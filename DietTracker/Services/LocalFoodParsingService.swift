//
//  LocalFoodParsingService.swift
//  DietTracker
//
//  本地食物解析：词典 + 正则 + 份量估算 + 模糊兜底（2.0）。
//
//  流程：
//    输入文本 → 分句 → 每段抽份量 → 剔除份量文本 → 三级命中 → 查份量表算克数
//
//    三级命中（顺序不能变，越靠前越可信）：
//      ① `FoodDatabase.match(in:)`           —— 原样文本的精确别名命中
//      ② `FoodDatabase.match(in: cleaned)`   —— 口语清洗后的精确别名命中
//      ③ `FuzzyFoodMatcher.bestCandidate`    —— 编辑距离 + 公共子串的模糊候选
//
//  ⚠️ 解析结果永远是「可修正的猜测」。只要 confidence < 0.8 或进了 unmatchedSegments，
//     UI 必须让用户能手动改（输入卡片的解析预览卡片负责这件事）。
//
//  ⚠️ 三级都走的是同一个 `entry`，后面的克数算法完全一致 ——
//     新增层级只影响「认不认得出名字」，不影响「算不算得对克数」。
//

import Foundation

struct LocalFoodParsingService: FoodParsingService {

    func parse(_ text: String) -> FoodParseResult {
        let raw = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return FoodParseResult.empty }

        let segments = TextSegmenter.split(raw)
        var items: [ParsedFood] = []
        var unmatched: [String] = []

        for segment in segments {
            // QuantityParser 要求「数字在前、单位在后」；口语里常见的「吃了份黄焖鸡」
            // 没有数字，交给 BareUnitQuantity 按「1 份」补全。两者互斥，优先前者。
            let quantity = QuantityParser.firstMatch(in: segment)
                        ?? BareUnitQuantity.firstMatch(in: segment)

            // 剔除份量文本后再匹配食物，避免「两碗」里的数词干扰别名命中
            var searchText = segment
            if let quantity {
                searchText = searchText.replacingOccurrences(of: quantity.text, with: "")
            }
            let cleaned = FoodTextNormalizer.normalize(searchText)

            guard let hit = resolveFood(searchText: searchText, cleaned: cleaned) else {
                unmatched.append(segment)
                continue
            }

            let entry = hit.entry
            var confidence: Double = hit.confidence

            let grams: Double
            if let quantity {
                let perUnit = entry.grams(unit: quantity.unit)
                grams = perUnit * quantity.value * quantity.scale
                // 食物自身没有这个份量单位（且不是绝对重量单位）→ 用的是默认克数，置信度下调
                if let unit = quantity.unit,
                   !unit.isAbsoluteUnit,
                   entry.grams(for: unit) == nil {
                    confidence -= 0.05
                }
                // 「大碗」「小份」这类模糊修饰本身也是估算
                if quantity.scaleText != nil { confidence -= 0.03 }
            } else {
                grams = entry.defaultGrams
                confidence -= 0.08   // 没说份量，用的是默认份量
            }

            items.append(ParsedFood(
                name: entry.name,
                matchedFoodID: entry.id,
                quantityText: quantity?.text,
                grams: Swift.max(0, grams),
                confidence: Swift.max(0.3, Swift.min(1, confidence))
            ))
        }

        return FoodParseResult(rawText: raw, items: items, unmatchedSegments: unmatched)
    }

    // MARK: 三级命中

    /// 精确优先、清洗次之、模糊兜底。返回 nil 表示这段确实不是食物。
    private func resolveFood(searchText: String,
                             cleaned: String) -> (entry: FoodEntry, confidence: Double)? {
        // ① 原样文本
        if let hit = FoodDatabase.match(in: searchText) {
            return (hit.entry, hit.alias == hit.entry.name ? 0.95 : 0.88)
        }
        // ② 清洗后文本（剥掉了「我/今天/吃了/的」这类噪声）
        if !cleaned.isEmpty, cleaned != searchText,
           let hit = FoodDatabase.match(in: cleaned) {
            return (hit.entry, 0.84)
        }
        // ③ 模糊候选。置信度由 FuzzyFoodMatcher 压在 0.40~0.72 之间。
        if let fuzzy = FuzzyFoodMatcher.bestCandidate(for: cleaned) {
            return (fuzzy.entry, fuzzy.confidence)
        }
        return nil
    }
}
