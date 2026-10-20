//
//  DatabaseIntegrityTests.swift
//  DietTrackerTests
//
//  本地数据表完整性与营养查询测试：
//    · 食物表 ≥50 项、运动表 ≥20 种（MVP 验收下限）
//    · ID 唯一、数值合法（MET 三档单调、营养值非负）
//    · 查询链路：本地表命中 → 兜底值，永不抛错
//

import XCTest
@testable import DietTracker

// MARK: - 数据表完整性

final class DatabaseIntegrityTests: XCTestCase {

    func testFoodTableHasAtLeast50Entries() {
        XCTAssertGreaterThanOrEqual(FoodDatabase.all.count, 50,
                                     "MVP 要求本地食物表 ≥50 项，实际 \(FoodDatabase.all.count) 项")
    }

    func testExerciseTableHasAtLeast20Entries() {
        XCTAssertGreaterThanOrEqual(ExerciseDatabase.all.count, 20,
                                     "MVP 要求本地运动表 ≥20 种，实际 \(ExerciseDatabase.all.count) 种")
    }

    func testFoodIDsUnique() {
        let ids = FoodDatabase.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "食物 ID 有重复")
    }

    func testExerciseIDsUnique() {
        let ids = ExerciseDatabase.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "运动 ID 有重复")
    }

    func testFoodEntriesWellFormed() {
        for entry in FoodDatabase.all {
            XCTAssertFalse(entry.name.isEmpty, "\(entry.id) 名称为空")
            XCTAssertFalse(entry.aliases.isEmpty, "\(entry.id) 没有别名")
            XCTAssertTrue(entry.aliases.contains(entry.name),
                          "\(entry.id) 别名应包含规范名（保证精确输入可命中）")
            XCTAssertGreaterThan(entry.per100g.kcal, 0, "\(entry.id) 每100g热量应为正")
            XCTAssertGreaterThan(entry.defaultGrams, 0, "\(entry.id) 默认克数应为正")
            for nutrient in Nutrient.displayOrder {
                XCTAssertGreaterThanOrEqual(entry.per100g.value(for: nutrient), 0,
                                            "\(entry.id) 的 \(nutrient.rawValue) 出现负值")
            }
            for (unit, grams) in entry.portions {
                XCTAssertGreaterThan(grams, 0, "\(entry.id) 的 \(unit.rawValue) 份量为非正值")
            }
        }
    }

    func testExerciseMETOrdering() {
        for entry in ExerciseDatabase.all {
            XCTAssertLessThanOrEqual(entry.metLow, entry.metModerate,
                                     "\(entry.id) 低强度 MET 大于中等强度")
            XCTAssertLessThanOrEqual(entry.metModerate, entry.metHigh,
                                     "\(entry.id) 中等强度 MET 大于高强度")
            XCTAssertGreaterThan(entry.metLow, 0)
            XCTAssertGreaterThan(entry.defaultMinutes, 0)
            XCTAssertFalse(entry.name.isEmpty)
        }
    }

    func testEntryLookupByID() {
        XCTAssertNotNil(FoodDatabase.entry(id: "rice"))
        XCTAssertNil(FoodDatabase.entry(id: "no_such_food"))
        XCTAssertNotNil(ExerciseDatabase.entry(id: "running"))
        XCTAssertNil(ExerciseDatabase.entry(id: "no_such_exercise"))
    }

    /// 别名匹配：别名里必须真的能被 match(in:) 命中。
    func testMatchFindsAlias() {
        let hit = FoodDatabase.match(in: "今天吃了番茄炒鸡蛋")
        XCTAssertEqual(hit?.entry.id, "tomato_egg")

        let exHit = ExerciseDatabase.match(in: "晚上去撸铁")
        XCTAssertEqual(exHit?.entry.id, "strength")
    }
}

// MARK: - 营养查询与兜底

final class NutritionLookupTests: XCTestCase {

    private let service = LocalNutritionLookupService()

    /// 本地表命中：米饭一碗（150g）→ 116 kcal/100g × 1.5 = 174 kcal。
    func testLocalTableLookupScalesByGrams() async {
        let parsed = ParsedFood(name: "米饭",
                                matchedFoodID: "rice",
                                quantityText: "一碗",
                                grams: 150,
                                confidence: 0.95)
        let result = await service.lookup(parsed: parsed)
        XCTAssertEqual(result.source, .localTable)
        XCTAssertEqual(result.matchedFoodID, "rice")
        XCTAssertEqual(result.grams, 150)
        XCTAssertEqual(result.nutrition.kcal, 174, accuracy: 0.1)   // 116 × 1.5
        XCTAssertEqual(result.nutrition.proteinG, 2.6 * 1.5, accuracy: 0.1)
        XCTAssertEqual(result.estimatorVersion, EstimatorVersion.food)
    }

    /// 未命中且未配置 API（默认 Key 为空）→ 通用兜底值，绝不抛错。
    func testUnknownFoodFallsBackSilently() async {
        let parsed = ParsedFood(name: "拿铁冻冻",
                                matchedFoodID: nil,
                                quantityText: nil,
                                grams: nil,
                                confidence: 0.4)
        let result = await service.lookup(parsed: parsed)
        XCTAssertEqual(result.source, .fallback)
        XCTAssertNil(result.matchedFoodID)
        XCTAssertGreaterThan(result.nutrition.kcal, 0)   // 兜底值非零
        XCTAssertLessThanOrEqual(result.confidence, 0.5)
        XCTAssertGreaterThan(result.grams, 0)
    }

    /// 同步兜底路径永远有结果。
    func testSynchronousFallback() {
        let parsed = ParsedFood(name: "神秘食物",
                                matchedFoodID: nil,
                                quantityText: nil,
                                grams: 200,
                                confidence: 0.3)
        let result = service.fallback(parsed: parsed)
        XCTAssertEqual(result.source, .fallback)
        XCTAssertEqual(result.grams, 200)
        XCTAssertEqual(result.nutrition.kcal,
                       FoodDatabase.unknownPer100g.kcal * 2, accuracy: 0.1)
    }

    /// 未配置 Key 时外部 API 必须是关闭状态（离线可用验收项）。
    func testExternalAPIDisabledByDefault() {
        // 测试环境没有注入 NUTRITION_API_KEY，应视为关闭
        if NutritionAPIConfig.apiKey.isEmpty {
            XCTAssertFalse(NutritionAPIConfig.isEnabled)
            XCTAssertFalse(service.isExternalAPIEnabled)
        } else {
            XCTAssertFalse(service.isExternalAPIEnabled,
                           "测试不应携带 API Key")
        }
    }

    /// 查询结果可复现：同一输入两次查询结果一致。
    func testLookupReproducible() async {
        let parsed = ParsedFood(name: "鸡蛋",
                                matchedFoodID: "egg_boiled",
                                quantityText: "两个",
                                grams: 100,
                                confidence: 0.95)
        let a = await service.lookup(parsed: parsed)
        let b = await service.lookup(parsed: parsed)
        XCTAssertEqual(a, b)
    }
}
