//
//  ExerciseItem.swift
//  DietTracker
//
//  一条具体的运动及其消耗估算。
//
//  ⚠️ 可复现性约定（对应验收标准「消耗估算可复现」）：
//     本模型冗余存储 `metValue` / `weightKgAtEstimate` / `estimatedKcal` / `estimatorVersion`。
//     用户后来改了设置里的体重，历史记录里这条运动的消耗数字**不会变**。
//
//  ⚠️ 消耗只用于能量平衡描述与能量/宏量建议（通道 B），
//     永远不能用来抵消微量营养素（通道 A）的「偏低」判定。
//

import Foundation
import SwiftData

@Model
final class ExerciseItem {

    var id: UUID = UUID()

    var name: String = ""
    /// 命中的本地 MET 表条目 ID；nil 表示走了兜底
    var matchedExerciseID: String? = nil

    /// 时长（分钟）
    var minutes: Double = 0
    var intensityRaw: String = ExerciseIntensity.moderate.rawValue

    // MARK: 估算快照

    var metValue: Double = 0
    var estimatedKcal: Double = 0
    /// 用户手动修正的消耗值（kcal）。nil 表示沿用估算值。
    ///
    /// ⚠️ 刻意**不覆盖** `estimatedKcal` —— 估算结果永久留着作为对照证据。
    ///    用户随时可以「恢复估算值」，历史也能追溯到当时 MET 算了多少。
    var manualKcal: Double? = nil
    /// 估算当时的体重（kg）。改设置里的体重不会篡改历史。
    var weightKgAtEstimate: Double = 0
    var estimatorVersion: String = EstimatorVersion.exerciseMET

    /// true 表示没匹配到具体运动，用了「中等强度一般运动」默认 MET
    var isFallback: Bool = false
    /// 解析置信度 0...1
    var confidence: Double = 1

    var sortOrder: Int = 0
    var createdAt: Date = Date()

    // MARK: 计算属性（不持久化）

    /// 实际参与计算的消耗值：手动修正优先，否则用估算值。
    ///
    /// ⚠️ 全工程**只能通过它**取 kcal（列表、趋势、分析引擎都一样）。
    ///    任何地方直接读 estimatedKcal，都会出现「列表显示 400、趋势算 280」
    ///    这种自相矛盾的数字 —— 那比算错更伤信任。
    var effectiveKcal: Double { manualKcal ?? estimatedKcal }

    /// 数值是否被用户手动改过（UI 要标注，让别人知道这不是公式结果）
    var isManuallyAdjusted: Bool { manualKcal != nil }

    var intensity: ExerciseIntensity {
        get { ExerciseIntensity(rawValue: intensityRaw) ?? .moderate }
        set { intensityRaw = newValue.rawValue }
    }

    /// 是否需要用户人工复核（走了兜底或置信度过低）
    var needsReview: Bool { isFallback || confidence < 0.6 }

    /// 展示用时长文本
    var minutesText: String {
        let m = Int(minutes.rounded())
        if m < 60 { return "\(m) 分钟" }
        let h = m / 60
        let rest = m % 60
        return rest == 0 ? "\(h) 小时" : "\(h) 小时 \(rest) 分"
    }

    init() {}

    convenience init(name: String,
                    matchedExerciseID: String?,
                    minutes: Double,
                    intensity: ExerciseIntensity,
                    metValue: Double,
                    estimatedKcal: Double,
                    weightKgAtEstimate: Double,
                    manualKcal: Double? = nil,
                    isFallback: Bool = false,
                    confidence: Double = 1,
                    sortOrder: Int = 0) {
        self.init()
        self.name = name
        self.matchedExerciseID = matchedExerciseID
        self.minutes = minutes
        self.intensityRaw = intensity.rawValue
        self.metValue = metValue
        self.estimatedKcal = estimatedKcal
        self.manualKcal = manualKcal
        self.weightKgAtEstimate = weightKgAtEstimate
        self.isFallback = isFallback
        self.confidence = confidence
        self.sortOrder = sortOrder
        self.estimatorVersion = EstimatorVersion.exerciseMET
        self.createdAt = Date()
    }
}
