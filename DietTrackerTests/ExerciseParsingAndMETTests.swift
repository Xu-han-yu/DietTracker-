//
//  ExerciseParsingAndMETTests.swift
//  DietTrackerTests
//
//  运动解析（词典 + 时长 + 强度）与 MET 消耗估算测试。
//  重点验收项：
//    · 「先剔除运动名再判强度」——「快走」「慢跑」不能被误判强度
//    · kcal = MET × 体重kg × 小时数，可复现
//    · 未命中回退「中等强度一般运动」并标注 isFallback
//

import XCTest
@testable import DietTracker

final class ExerciseParsingTests: XCTestCase {

    private let service = LocalExerciseParsingService()

    // MARK: - 基础解析

    func testRunningMinutes() {
        let item = service.parse("跑步30分钟").items.first
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.matchedExerciseID, "running")
        XCTAssertEqual(item?.minutes, 30)
    }

    func testBriskWalkingOneHour() {
        let item = service.parse("快走1小时").items.first
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.matchedExerciseID, "brisk_walking")
        XCTAssertEqual(item?.minutes, 60)
        // 「快走」的「快」不能被判成高强度
        XCTAssertNil(item?.intensity)
    }

    func testStrengthTraining() {
        let item = service.parse("力量训练40分钟").items.first
        XCTAssertEqual(item?.matchedExerciseID, "strength")
        XCTAssertEqual(item?.minutes, 40)
    }

    func testSwimming() {
        let item = service.parse("游泳45分钟").items.first
        XCTAssertEqual(item?.matchedExerciseID, "swimming")
        XCTAssertEqual(item?.minutes, 45)
    }

    /// 慢跑是「跑步」的别名，剔除后剩「30分钟」，强度应为默认（nil），不是低强度。
    func testJoggingAliasNotMisreadAsLowIntensity() {
        let item = service.parse("慢跑30分钟").items.first
        XCTAssertEqual(item?.matchedExerciseID, "running")
        XCTAssertEqual(item?.minutes, 30)
        XCTAssertNil(item?.intensity)
    }

    // MARK: - 强度

    func testExplicitHighIntensity() {
        let item = service.parse("高强度跑步半小时").items.first
        XCTAssertEqual(item?.matchedExerciseID, "running")
        XCTAssertEqual(item?.minutes, 30)
        XCTAssertEqual(item?.intensity, .high)
    }

    func testExplicitLowIntensity() {
        let item = service.parse("慢速骑行一小时").items.first
        XCTAssertEqual(item?.matchedExerciseID, "cycling")
        XCTAssertEqual(item?.minutes, 60)
        XCTAssertEqual(item?.intensity, .low)
    }

    // MARK: - 时长组合

    func testNinetyMinutes() {
        let item = service.parse("跑步一个半小时").items.first
        XCTAssertEqual(item?.minutes, 90)
    }

    func testQuarterHour() {
        let item = service.parse("跳绳一刻钟").items.first
        XCTAssertEqual(item?.matchedExerciseID, "jump_rope")
        XCTAssertEqual(item?.minutes, 15)
    }

    func testEnglishDuration() {
        let item = service.parse("HIIT 20分钟").items.first
        XCTAssertEqual(item?.matchedExerciseID, "hiit")
        XCTAssertEqual(item?.minutes, 20)
    }

    // MARK: - 多运动与边界

    func testMultipleExercises() {
        let result = service.parse("跑步30分钟，力量训练40分钟")
        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(result.items[0].matchedExerciseID, "running")
        XCTAssertEqual(result.items[1].matchedExerciseID, "strength")
    }

    func testAliasBasketball() {
        let item = service.parse("打篮球40分钟").items.first
        XCTAssertEqual(item?.matchedExerciseID, "basketball")
        XCTAssertEqual(item?.minutes, 40)
    }

    func testNoDurationUsesNil() {
        let item = service.parse("去跑步了").items.first
        XCTAssertEqual(item?.matchedExerciseID, "running")
        XCTAssertNil(item?.minutes)   // 时长由估算层用默认值兜底
        XCTAssertFalse(item!.hasDuration)
    }

    func testEmptyInput() {
        XCTAssertTrue(service.parse("").isEmpty)
    }

    func testUnmatched() {
        let result = service.parse("看了一下午电视")
        XCTAssertTrue(result.items.isEmpty)
        XCTAssertFalse(result.unmatchedSegments.isEmpty)
    }
}

// MARK: - MET 估算

final class METCalorieServiceTests: XCTestCase {

    private let service = METExerciseCalorieService()

    private func runningParsed(minutes: Double?, intensity: ExerciseIntensity?) -> ParsedExercise {
        ParsedExercise(name: "跑步",
                       matchedExerciseID: "running",
                       minutes: minutes,
                       intensity: intensity,
                       confidence: 0.95)
    }

    // MARK: - 公式

    func testFormulaRunningModerate() {
        // 11.0 MET × 70 kg × 0.5 h = 385.0 kcal
        let e = service.estimate(parsed: runningParsed(minutes: 30, intensity: nil),
                                  weightKg: 70,
                                  defaultIntensity: .moderate)
        XCTAssertFalse(e.isFallback)
        XCTAssertEqual(e.metValue, 11.0)
        XCTAssertEqual(e.kcal, 385.0, accuracy: 0.05)
        XCTAssertEqual(e.weightKgAtEstimate, 70)
        XCTAssertEqual(e.estimatorVersion, EstimatorVersion.exerciseMET)
    }

    func testFormulaIntensityScalesMET() {
        let low = service.estimate(parsed: runningParsed(minutes: 30, intensity: .low),
                                   weightKg: 70, defaultIntensity: .moderate)
        let high = service.estimate(parsed: runningParsed(minutes: 30, intensity: .high),
                                    weightKg: 70, defaultIntensity: .moderate)
        XCTAssertLessThan(low.metValue, high.metValue)
        XCTAssertLessThan(low.kcal, high.kcal)
    }

    // MARK: - 可复现性（验收项：同一输入两次估算结果一致）

    func testReproducible() {
        let parsed = runningParsed(minutes: 30, intensity: .moderate)
        let a = service.estimate(parsed: parsed, weightKg: 70, defaultIntensity: .moderate)
        let b = service.estimate(parsed: parsed, weightKg: 70, defaultIntensity: .moderate)
        XCTAssertEqual(a, b)
    }

    /// 体重快照必须冗余存储：改体重不能篡改历史数字的来源。
    func testWeightSnapshotStored() {
        let e = service.estimate(parsed: runningParsed(minutes: 30, intensity: nil),
                                  weightKg: 82.5,
                                  defaultIntensity: .moderate)
        XCTAssertEqual(e.weightKgAtEstimate, 82.5)
        XCTAssertEqual(e.kcal, 11.0 * 82.5 * 0.5, accuracy: 0.05)
    }

    // MARK: - 兜底

    func testFallbackForUnknownExercise() {
        let parsed = ParsedExercise(name: "舞蹈操",
                                    matchedExerciseID: nil,
                                    minutes: 30,
                                    intensity: nil,
                                    confidence: 0.4)
        let e = service.estimate(parsed: parsed, weightKg: 70, defaultIntensity: .moderate)
        XCTAssertTrue(e.isFallback)
        XCTAssertEqual(e.metValue, ExerciseFallback.met)       // 5.0
        XCTAssertEqual(e.kcal, 5.0 * 70 * 0.5, accuracy: 0.05)
        XCTAssertNotNil(e.cautionText)                          // UI 必须展示估算标注
        XCTAssertNil(e.matchedExerciseID)
    }

    func testZeroWeightFallsBackToDefault() {
        let e = service.estimate(parsed: runningParsed(minutes: 30, intensity: nil),
                                  weightKg: 0,
                                  defaultIntensity: .moderate)
        XCTAssertEqual(e.weightKgAtEstimate, ExerciseFallback.defaultWeightKg)  // 60
        XCTAssertEqual(e.kcal, 11.0 * 60 * 0.5, accuracy: 0.05)
    }

    func testMissingDurationUsesDefault() {
        let e = service.estimate(parsed: runningParsed(minutes: nil, intensity: nil),
                                  weightKg: 70,
                                  defaultIntensity: .moderate)
        XCTAssertEqual(e.minutes, ExerciseFallback.defaultMinutes)  // 30
    }

    /// 时长上限限幅：999 分钟夹到 360。
    func testDurationClamped() {
        let e = service.estimate(parsed: runningParsed(minutes: 999, intensity: nil),
                                  weightKg: 70,
                                  defaultIntensity: .moderate)
        XCTAssertEqual(e.minutes, 360)
        XCTAssertEqual(e.kcal, 11.0 * 70 * 6.0, accuracy: 0.05)
    }

    // MARK: - MET 公式本身

    func testMETFormulaEdgeCases() {
        XCTAssertEqual(METFormula.kcal(met: 0, weightKg: 70, minutes: 30), 0)
        XCTAssertEqual(METFormula.kcal(met: 5, weightKg: 0, minutes: 30), 0)
        XCTAssertEqual(METFormula.kcal(met: 5, weightKg: 70, minutes: 0), 0)
        XCTAssertEqual(METFormula.kcal(met: 5, weightKg: 70, minutes: 60), 350, accuracy: 0.05)
    }
}
