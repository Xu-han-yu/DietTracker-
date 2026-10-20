//
//  NutritionProfileTests.swift
//  DietTrackerTests
//
//  RDI（每日推荐摄入量）计算测试：Mifflin-St Jeor + 活动系数 + 目标调整。
//  ⚠️ RDI 不含运动回加 —— compute 的签名里根本没有运动参数，这是设计保证。
//

import XCTest
@testable import DietTracker

final class NutritionProfileTests: XCTestCase {

    /// 男 / 30 岁 / 175cm / 70kg / 轻度活动 / 维持
    /// BMR = 10×70 + 6.25×175 − 5×30 + 5 = 1648.75
    /// TDEE = 1648.75 × 1.375 = 2267.03
    private let referenceMale = UserProfileSnapshot(sex: .male,
                                                    age: 30,
                                                    heightCm: 175,
                                                    weightKg: 70,
                                                    activityLevel: .light,
                                                    goal: .maintain)

    func testMifflinStJeorMaintain() {
        let rdi = NutritionProfile.compute(from: referenceMale)
        XCTAssertEqual(rdi.kcal, 2267.03, accuracy: 0.5)
        XCTAssertEqual(rdi.proteinG, 84, accuracy: 0.01)       // 70 × 1.2
        XCTAssertEqual(rdi.fatG, 2267.03 * 0.25 / 9, accuracy: 0.5)
        XCTAssertEqual(rdi.carbsG, (2267.03 - 84 * 4 - rdi.fatG * 9) / 4, accuracy: 0.5)
    }

    func testCutReduces20Percent() {
        let cut = NutritionProfile.compute(from: UserProfileSnapshot(
            sex: .male, age: 30, heightCm: 175, weightKg: 70,
            activityLevel: .light, goal: .cut))
        XCTAssertEqual(cut.kcal, 2267.03 * 0.80, accuracy: 0.5)
        XCTAssertEqual(cut.proteinG, 112, accuracy: 0.01)      // 70 × 1.6
    }

    func testBulkIncreases10Percent() {
        let bulk = NutritionProfile.compute(from: UserProfileSnapshot(
            sex: .male, age: 30, heightCm: 175, weightKg: 70,
            activityLevel: .light, goal: .bulk))
        XCTAssertEqual(bulk.kcal, 2267.03 * 1.10, accuracy: 0.5)
        XCTAssertEqual(bulk.proteinG, 126, accuracy: 0.01)     // 70 × 1.8
    }

    func testFemaleBMRConstant() {
        let female = NutritionProfile.compute(from: UserProfileSnapshot(
            sex: .female, age: 30, heightCm: 175, weightKg: 70,
            activityLevel: .light, goal: .maintain))
        // 女性常数 −161：1648.75 − 166 = 1482.75 → × 1.375 = 2038.78
        XCTAssertEqual(female.kcal, 2038.78, accuracy: 0.5)
    }

    func testFemaleSafetyFloor() {
        // 女 / 30 / 160 / 45kg / 久坐 / 减脂：算出来 1093 kcal，必须抬到 1200 下限
        let rdi = NutritionProfile.compute(from: UserProfileSnapshot(
            sex: .female, age: 30, heightCm: 160, weightKg: 45,
            activityLevel: .sedentary, goal: .cut))
        XCTAssertEqual(rdi.kcal, 1200, accuracy: 0.01)
    }

    func testMaleSafetyFloor() {
        let rdi = NutritionProfile.compute(from: UserProfileSnapshot(
            sex: .male, age: 60, heightCm: 150, weightKg: 30,
            activityLevel: .sedentary, goal: .cut))
        XCTAssertGreaterThanOrEqual(rdi.kcal, 1500)
    }

    func testMicronutrientTargets() {
        let male = NutritionProfile.compute(from: referenceMale)
        XCTAssertEqual(male.calciumMG, 800)
        XCTAssertEqual(male.ironMG, 12)
        XCTAssertEqual(male.vitaminCMG, 100)
        XCTAssertEqual(male.fiberG, 25)

        let female = NutritionProfile.compute(from: UserProfileSnapshot(
            sex: .female, age: 30, heightCm: 175, weightKg: 70,
            activityLevel: .light, goal: .maintain))
        XCTAssertEqual(female.ironMG, 18)
        XCTAssertEqual(female.calciumMG, 800)
    }

    func testExtremeInputsClamped() {
        // 体重 0 / 身高 0 / 年龄 200：不应产生 NaN 或负数
        let rdi = NutritionProfile.compute(from: UserProfileSnapshot(
            sex: .unspecified, age: 200, heightCm: 0, weightKg: 0,
            activityLevel: .sedentary, goal: .maintain))
        XCTAssertFalse(rdi.kcal.isNaN)
        XCTAssertFalse(rdi.kcal.isInfinite)
        XCTAssertGreaterThan(rdi.kcal, 0)
        XCTAssertGreaterThanOrEqual(rdi.proteinG, 20 * 1.2)   // 体重下限 20kg
    }

    func testEstimatorVersionRecorded() {
        let rdi = NutritionProfile.compute(from: referenceMale)
        XCTAssertEqual(rdi.estimatorVersion, EstimatorVersion.rdi)
    }
}
