//
//  AnalysisEngineTests.swift
//  DietTrackerTests
//
//  分析引擎测试 —— 本文件是「双通道隔离」「趋势优先」「反补偿性进食」
//  三条硬约束的守护测试。任何一条失败都意味着核心设计被破坏。
//

import XCTest
@testable import DietTracker

final class AnalysisEngineTests: XCTestCase {

    private let engine = DefaultAnalysisEngine()

    // MARK: - 测试数据

    private let profile = UserProfileSnapshot(sex: .male,
                                              age: 30,
                                              heightCm: 175,
                                              weightKg: 70,
                                              activityLevel: .light,
                                              goal: .cut)

    /// 一天的摄入：钙 300（远低于 800×70%=560），铁 8，蛋白 100
    private var lowCalciumIntake: Nutrition {
        Nutrition(kcal: 1800, proteinG: 100, fatG: 50, carbsG: 220,
                  calciumMG: 300, ironMG: 8, vitaminCMG: 40, fiberG: 10)
    }

    private func history(days: Int,
                         intake: Nutrition,
                         burn: Double,
                         startDay: Int = 10) -> [DailySummary] {
        (0..<days).map { i in
            DailySummary(dayIdentifier: String(format: "2026-10-%02d", startDay + i),
                         intake: intake,
                         burnKcal: burn)
        }
    }

    // MARK: - 通道隔离（最重要的测试）

    /// 运动量再大，「钙偏低」也不能被改写成正常。
    /// 这是 PRD v1.1 的硬约束：运动消耗不能抵消微量营养素缺乏。
    func testHugeExerciseDoesNotWashOutMicronutrientDeficiency() {
        let intake = lowCalciumIntake

        let contextA = AnalysisContext(dayIdentifier: "2026-10-13",
                                       intake: intake,
                                       burnKcal: 0,
                                       profile: profile,
                                       thresholds: .default,
                                       history: history(days: 4, intake: intake, burn: 0))
        let contextB = AnalysisContext(dayIdentifier: "2026-10-13",
                                       intake: intake,
                                       burnKcal: 900,     // 当天大量运动
                                       profile: profile,
                                       thresholds: .default,
                                       history: history(days: 4, intake: intake, burn: 900))

        let analysisA = engine.analyze(contextA)
        let analysisB = engine.analyze(contextB)

        // 1) 钙在两种情形下都必须是「偏低」
        XCTAssertEqual(analysisA.evaluation(for: .calcium)?.status, .low)
        XCTAssertEqual(analysisB.evaluation(for: .calcium)?.status, .low,
                       "运动量再大也不能把「钙偏低」判为正常 —— 通道隔离被破坏！")

        // 2) 通道 A 的全部判定结果在两次分析中完全一致
        XCTAssertEqual(analysisA.microEvaluations, analysisB.microEvaluations)

        // 3) RDI 不随运动回加：推荐量必须一模一样
        XCTAssertEqual(analysisA.target, analysisB.target)

        // 4) 运动只体现在能量平衡（描述性指标）
        XCTAssertEqual(analysisB.burnKcal, 900)
        XCTAssertEqual(analysisB.netKcal, 1800 - 900)
        XCTAssertNotEqual(analysisA.energyBalance.status, analysisB.energyBalance.status)
    }

    // MARK: - 7 天趋势优先

    /// 记录天数足够时，状态由窗口均值判定，而不是当日值。
    /// 「今天钙吃够了但一周都缺」→ 依然偏低。
    func testTrendAverageOverrulesSingleDay() {
        // 前 6 天钙 300，今天钙 800（单日达标）
        var days = history(days: 6, intake: lowCalciumIntake, burn: 0, startDay: 10)
        let todayIntake = Nutrition(kcal: 1800, proteinG: 100, fatG: 50, carbsG: 220,
                                    calciumMG: 800, ironMG: 8, vitaminCMG: 40, fiberG: 10)
        days.append(DailySummary(dayIdentifier: "2026-10-16",
                                 intake: todayIntake,
                                 burnKcal: 0))

        let analysis = engine.analyze(AnalysisContext(dayIdentifier: "2026-10-16",
                                                      intake: todayIntake,
                                                      burnKcal: 0,
                                                      profile: profile,
                                                      thresholds: .default,
                                                      history: days))

        XCTAssertTrue(analysis.hasEnoughData)
        let calcium = analysis.evaluation(for: .calcium)
        XCTAssertEqual(calcium?.actual, 800)                        // 展示当日值
        XCTAssertEqual(calcium?.assessedValue ?? 0, (6 * 300 + 800) / 7.0, accuracy: 0.5)
        XCTAssertEqual(calcium?.status, .low)                       // 但按均值判：偏低
        XCTAssertEqual(calcium?.basis.isMultiDay, true)
        XCTAssertEqual(calcium?.basis.windowDays, 7)
    }

    /// 不足 3 天不做强结论：判定口径回落到当日。
    func testSingleDayBasisWhenDataInsufficient() {
        let intake = lowCalciumIntake
        let analysis = engine.analyze(AnalysisContext(dayIdentifier: "2026-10-10",
                                                      intake: intake,
                                                      burnKcal: 0,
                                                      profile: profile,
                                                      thresholds: .default,
                                                      history: history(days: 1, intake: intake, burn: 0)))

        XCTAssertFalse(analysis.hasEnoughData)
        XCTAssertEqual(analysis.recordedDays, 1)
        let calcium = analysis.evaluation(for: .calcium)
        XCTAssertEqual(calcium?.basis.isMultiDay, false)
        XCTAssertEqual(calcium?.status, .low)   // 单日参考值仍然标注状态，但口径是「当日」
    }

    // MARK: - 纯函数可复现性

    func testDeterministicOutput() {
        let intake = lowCalciumIntake
        let context = AnalysisContext(dayIdentifier: "2026-10-13",
                                      intake: intake,
                                      burnKcal: 320,
                                      profile: profile,
                                      thresholds: .default,
                                      history: history(days: 5, intake: intake, burn: 200))

        let a = engine.analyze(context)
        let b = engine.analyze(context)

        XCTAssertEqual(a.evaluations, b.evaluations)
        XCTAssertEqual(a.advice.map(\.title), b.advice.map(\.title))
        XCTAssertEqual(a.advice.map(\.detail), b.advice.map(\.detail))
        XCTAssertEqual(a.netKcal, b.netKcal)
        XCTAssertEqual(a.energyBalance, b.energyBalance)
    }

    // MARK: - 建议输出规范

    /// PRD：输出 2–3 条建议，全部过文案黑名单，且必须带免责声明。
    func testAdviceWellFormedAndClean() {
        let intake = lowCalciumIntake
        for burn in [0.0, 400.0] {
            let analysis = engine.analyze(AnalysisContext(dayIdentifier: "2026-10-13",
                                                          intake: intake,
                                                          burnKcal: burn,
                                                          profile: profile,
                                                          thresholds: .default,
                                                          history: history(days: 5, intake: intake, burn: burn)))

            XCTAssertTrue((2...3).contains(analysis.advice.count),
                          "建议应为 2–3 条，实际 \(analysis.advice.count) 条（burn=\(burn)）")

            for advice in analysis.advice {
                XCTAssertTrue(CompensationWordingGuard.isClean(advice.title),
                              "建议标题命中黑名单：\(advice.title)")
                XCTAssertTrue(CompensationWordingGuard.isClean(advice.detail),
                              "建议正文命中黑名单：\(advice.detail)")
                if let hint = advice.actionHint {
                    XCTAssertTrue(CompensationWordingGuard.isClean(hint),
                                  "行动提示命中黑名单：\(hint)")
                }
                XCTAssertFalse(advice.title.isEmpty)
                XCTAssertFalse(advice.detail.isEmpty)
            }

            XCTAssertTrue(analysis.disclaimer.contains("不能替代"),
                          "必须包含免责声明")
        }
    }

    /// 完全没有记录时：只鼓励记录，不做营养结论。
    func testEmptyDayGivesLoggingAdviceOnly() {
        let analysis = engine.analyze(AnalysisContext(dayIdentifier: "2026-10-10",
                                                      intake: .zero,
                                                      burnKcal: 0,
                                                      profile: profile,
                                                      thresholds: .default,
                                                      history: []))
        XCTAssertFalse(analysis.advice.isEmpty)
        XCTAssertTrue(analysis.advice.allSatisfy { $0.category == .logging },
                      "空数据日只应出现记录类建议")
    }

    // MARK: - 能量平衡（描述性指标）

    func testEnergyBalanceDescriptive() {
        let intake = Nutrition(kcal: 1800, proteinG: 100, fatG: 50, carbsG: 220)
        let analysis = engine.analyze(AnalysisContext(dayIdentifier: "2026-10-10",
                                                      intake: intake,
                                                      burnKcal: 300,
                                                      profile: profile,
                                                      thresholds: .default,
                                                      history: history(days: 1, intake: intake, burn: 300)))

        XCTAssertEqual(analysis.energyBalance.intakeKcal, 1800)
        XCTAssertEqual(analysis.energyBalance.burnKcal, 300)
        XCTAssertEqual(analysis.netKcal, 1500)
        XCTAssertFalse(analysis.energyBalance.status == .unknown)
    }
}

// MARK: - 文案黑名单

final class CompensationWordingGuardTests: XCTestCase {

    func testBannedPhrasesDetected() {
        for phrase in ["今天运动了可以多吃一碗",
                       "跑步消耗大，补回来",
                       "奖励自己吃顿好的",
                       "消耗了所以不怕多吃",
                       "今天可以放松一下",
                       "运动了所以随便吃"] {
            XCTAssertNotNil(CompensationWordingGuard.violation(in: phrase),
                            "黑名单应命中：\(phrase)")
            XCTAssertFalse(CompensationWordingGuard.isClean(phrase))
        }
    }

    func testCleanTextPasses() {
        for phrase in ["运动后注意补水",
                       "蛋白质摄入要跟上训练节奏",
                       "最近 7 天能量缺口偏大，留意恢复",
                       "钙摄入持续偏低，可以在早餐加一杯牛奶"] {
            XCTAssertTrue(CompensationWordingGuard.isClean(phrase), "不应误伤：\(phrase)")
        }
    }
}
