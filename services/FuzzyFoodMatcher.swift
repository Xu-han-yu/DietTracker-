//
//  FuzzyFoodMatcher.swift
//  DietTracker
//
//  2.0 解析增强：**口语噪声清洗 + 模糊匹配 + 裸量词补全**。
//
//  为什么需要它：
//    主表命中用的是 `text.contains(alias)`，完全精确。用户真实输入往往夹杂口语噪声：
//      「我刚刚吃了份黄焖鸡」   —— 「我/刚刚/吃了」是噪声
//      「黄闷鸡」               —— 错别字，主表没有
//      「杨枝甘路」             —— 同音错字
//    三层都失败时，以前直接进 unmatchedSegments；现在走模糊匹配给一个「低置信度候选」，
//    仍然让用户确认后保存 —— 这符合项目一贯的原则：结果是可修正的猜测，不是最终答案。
//
//  ⚠️ 设计边界（不要越界）：
//    - 本文件**只做字符串层面的猜测**，不发网络请求，纯同步、可离线。
//    - 返回的置信度刻意压得低（≤0.72），UI 必须能看出这是「猜的」。
//    - 精确匹配永远优先：只有 `FoodDatabase.match(in:)` 完全没命中时才轮到这里。
//

import Foundation

// MARK: - 口语清洗

enum FoodTextNormalizer {

    /// 句首的时间 / 主语 / 动作词。按长度降序逐个剥前缀，避免「刚刚」被「刚」抢先切掉一半。
    private static let leadingTokens: [String] = {
        let raw = ["今天", "明天", "早上", "上午", "中午", "下午", "晚上", "半夜", "凌晨",
                   "刚才", "刚刚", "已经", "后来", "后来", "之前", "以前",
                   "我们", "咱们", "咱", "俺", "我",
                   "吃了", "吃过", "吃",
                   "喝了", "喝过", "喝",
                   "点了", "点了个", "点",
                   "买了", "买了个", "买",
                   "来了", "整了", "干了", "啃了", "尝了", "加餐", "加了个"]
        return raw.sorted { $0.count > $1.count }
    }()

    /// 全局虚词。这些字几乎不会出现在食物名里，去掉它们只会提高命中率。
    /// ⚠️ 不要往这里加实词（形容词、食物部件），否则会 corruption 掉真实菜名。
    private static let particles: [String] = ["的话", "吧", "呢", "啊", "嘛", "的", "了", "过", "着", "呀", "哈"]

    /// 只要「汉字 / 字母 / 数字」，其余标点空白全部丢弃。
    static func vocabulary(_ text: String) -> String {
        var out = ""
        for scalar in text.unicodeScalars {
            let isASCIIAlnum = (scalar.value >= 48 && scalar.value <= 57)     // 0-9
                            || (scalar.value >= 65 && scalar.value <= 90)     // A-Z
                            || (scalar.value >= 97 && scalar.value <= 122)    // a-z
            let isCJK = (scalar.value >= 0x4E00 && scalar.value <= 0x9FFF)    // 基本汉字
            if isASCIIAlnum || isCJK { out.unicodeScalars.append(scalar) }
        }
        return out
    }

    /// 完整清洗：剥前缀 → 去虚词 → 去标点空白。
    static func normalize(_ text: String) -> String {
        var s = vocabulary(text)

        // 剥前缀。每剥掉一层就重来一遍，支持「我今天刚吃了」这种叠加。
        var didStrip = true
        while didStrip && !s.isEmpty {
            didStrip = false
            for token in leadingTokens {
                if s.hasPrefix(token), s.count > token.count {
                    s.removeFirst(token.count)
                    didStrip = true
                    break
                }
            }
        }

        for particle in particles {
            s = s.replacingOccurrences(of: particle, with: "")
        }
        return s
    }
}

// MARK: - 裸量词补全

/// 处理「无量词数字」的口语写法。
///
/// `QuantityParser` 要求数字在前、单位在后，因此它识别不了「吃了**份**黄焖鸡」——
/// 这里补一条窄规则：动作字（了/过/吃/喝/点…）紧跟一个**容量单位**时，按「1 份」处理。
///
/// ⚠️ 必须窄：
///    - 只认动词后的单位，不认词内部的单位。否则「杯子蛋糕」会被误判成「1 杯 蛋糕」。
///    - 不收「两 / 斤 / 克 / 毫升」：它们是重量单位，无数字时的语义不成立。
enum BareUnitQuantity {

    private static let pattern =
        "(了|过|吃|喝|点|来|要|买|盛|加)"
        + "(碗|份|个|只|颗|枚|杯|片|块|根|条|盘|碟|勺|匙|瓶|袋|包|把)"

    private static let regex: NSRegularExpression? = try? NSRegularExpression(pattern: pattern)

    static func firstMatch(in text: String) -> QuantityMatch? {
        guard let regex else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let m = regex.firstMatch(in: text, options: [], range: range),
              let unitRange = Range(m.range(at: 2), in: text) else { return nil }

        let unitText = String(text[unitRange])
        guard let unit = PortionUnit.from(text: unitText) else { return nil }

        return QuantityMatch(text: unitText, value: 1, unit: unit, scale: 1)
    }
}

// MARK: - 模糊匹配

struct FuzzyFoodCandidate {
    let entry: FoodEntry
    /// 原始相似度 0...1
    let score: Double
    /// 落到 ParsedFood 上的置信度。刻意压低，UI 要当「猜的」处理。
    let confidence: Double
}

enum FuzzyFoodMatcher {

    /// 命中阈值。调太低会把「随便吃点东西」也匹配到某个菜上，宁缺毋滥。
    static let scoreThreshold: Double = 0.62

    /// 候选扁平表（别名 + 正式名，去重）。static 惰性求值，整个 App 生命周期只算一次。
    private static let candidates: [(key: String, entry: FoodEntry)] = {
        var seen = Set<String>()
        var pairs: [(String, FoodEntry)] = []
        for entry in FoodDatabase.all {
            let keys = entry.aliases + [entry.name]
            for key in keys {
                let k = key.lowercased()
                if seen.insert(k).inserted {
                    pairs.append((k, entry))
                }
            }
        }
        return pairs
    }()

    /// 在全部食物里找与 `query` 最接近的一个。
    ///
    /// - Note: 只在 `FoodDatabase.match(in:)` 失败后调用，不在热路径上。
    static func bestCandidate(for query: String) -> FuzzyFoodCandidate? {
        let q = query.lowercased()
        guard q.count >= 2 else { return nil }   // 单字不做模糊，噪声太大

        var best: (score: Double, entry: FoodEntry)? = nil

        for (key, entry) in candidates {
            guard key.count >= 2 else { continue }
            let score = similarity(q, key)
            if score < scoreThreshold { continue }
            if best == nil || score > best!.score {
                best = (score, entry)
            }
        }

        guard let best else { return nil }
        let confidence = Swift.min(0.72, Swift.max(0.40, best.score * 0.9))
        return FuzzyFoodCandidate(entry: best.entry, score: best.score, confidence: confidence)
    }

    /// 相似度 = 编辑距离分 45% + 最长公共子串分 55%。
    ///
    /// 只用一个指标都会失真：
    ///   编辑距离对「插入 / 缺失一两个字」敏感（黄焖鸡 vs 黄焖**鸡米饭**）
    ///   公共子串对「前后缀乱入」敏感（番茄炒蛋 vs **番茄**）
    /// 两者加权后才兼顾错别字与局部重合两种情况。
    static func similarity(_ a: String, _ b: String) -> Double {
        if a.isEmpty || b.isEmpty { return 0 }
        if a == b { return 1 }

        let ca = Array(a)
        let cb = Array(b)

        // 【规则一】等长（或差 1 个字）且较短一方 ≥3 字：
        //   编辑距离 ≤1 基本就是错别字（黄闷鸡 / 黄焖鸡、杨枝甘路 / 杨枝甘露）。
        //   ⚠️ 必须是 ≥3 字才敢这么宽容：两字词「烧烤」与「烤鸭」也只差一个字，
        //      但它们毫无关系。少了这个长度门槛会造成大量荒唐误配。
        let lenDiff = abs(ca.count - cb.count)
        if Swift.min(ca.count, cb.count) >= 3 && lenDiff <= 1 {
            let d = editDistance(ca, cb)
            if d <= 1 { return 0.85 }
            if d == 2 { return 0.70 }
            // d 更大说明差异偏大，落到下面的加权公式，别硬判
        }

        // 【规则二】包含关系：比纯相似更可信，但明显低于完全相等。
        // 这里作用于已清洗过的短词；「白菜 vs 小白菜」这类上下位误判由阈值兜住。
        if a.contains(b) { return 0.80 + 0.15 * Double(cb.count) / Double(Swift.max(ca.count, 1)) }
        if b.contains(a) { return 0.80 + 0.15 * Double(ca.count) / Double(Swift.max(cb.count, 1)) }

        let longest = Double(Swift.max(ca.count, cb.count))
        guard longest > 0 else { return 0 }

        let distance = editDistance(ca, cb)
        let distanceScore = 1 - Double(distance) / longest

        let common = longestCommonSubstring(ca, cb).count
        let substringScore = Double(common) / longest

        let raw = 0.45 * distanceScore + 0.55 * substringScore
        return Swift.min(1, Swift.max(0, raw))
    }

    // MARK: 基础算法

    /// Levenshtein 距离（动态规划）。输入都是短词，开销可以忽略。
    static func editDistance(_ a: [Character], _ b: [Character]) -> Int {
        let n = a.count
        let m = b.count
        if n == 0 { return m }
        if m == 0 { return n }

        // 滚动数组，避免 O(n·m) 的空间。
        var previous = Array(0...m)
        var current = Array(repeating: 0, count: m + 1)

        for i in 1...n {
            current[0] = i
            for j in 1...m {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                current[j] = Swift.min(previous[j] + 1,      // 删除
                                       current[j - 1] + 1,   // 插入
                                       previous[j - 1] + cost) // 替换
            }
            previous = current
        }
        return previous[m]
    }

    /// 最长公共**连续**子串。
    static func longestCommonSubstring(_ a: [Character], _ b: [Character]) -> [Character] {
        let n = a.count
        let m = b.count
        guard n > 0, m > 0 else { return [] }

        var previous = Array(repeating: 0, count: m + 1)
        var bestLength = 0
        var bestEnd = 0

        for i in 1...n {
            var current = Array(repeating: 0, count: m + 1)
            for j in 1...m {
                if a[i - 1] == b[j - 1] {
                    current[j] = previous[j - 1] + 1
                    if current[j] > bestLength {
                        bestLength = current[j]
                        bestEnd = i
                    }
                } else {
                    current[j] = 0
                }
            }
            previous = current
        }

        guard bestLength > 0 else { return [] }
        return Array(a[(bestEnd - bestLength)..<bestEnd])
    }
}
