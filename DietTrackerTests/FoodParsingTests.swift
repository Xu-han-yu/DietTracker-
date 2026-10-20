//
//  FoodParsingTests.swift
//  DietTrackerTests
//
//  食物自然语言解析测试（本地词典 + 规则 + 份量估算）。
//  覆盖 MVP 验收标准「解析测试 ≥20 条通过率 ≥85%」——这里直接按 100% 断言，
//  任何一条回归都视为破坏性变更。
//

import XCTest
@testable import DietTracker

final class FoodParsingTests: XCTestCase {

    private let service = LocalFoodParsingService()

    // MARK: - 帮助方法

    private func parseOne(_ text: String,
                          file: StaticString = #filePath,
                          line: UInt = #line) -> ParsedFood {
        let result = service.parse(text)
        XCTAssertEqual(result.items.count, 1,
                       "「\(text)」应解析出 1 项，实际 \(result.items.count)；未匹配段：\(result.unmatchedSegments)",
                       file: file, line: line)
        return result.items[0]
    }

    // MARK: - 份量 × 食物（克数可精确断言的用例）

    func testRiceOneBowl() {
        let item = parseOne("米饭一碗")
        XCTAssertEqual(item.matchedFoodID, "rice")
        XCTAssertEqual(item.grams, 150)
    }

    func testRiceTwoBowlsChineseNumber() {
        let item = parseOne("两碗米饭")
        XCTAssertEqual(item.matchedFoodID, "rice")
        XCTAssertEqual(item.grams, 300)
    }

    func testBaoziThreePieces() {
        let item = parseOne("三个包子")
        XCTAssertEqual(item.matchedFoodID, "baozi_meat")
        XCTAssertEqual(item.grams, 240)   // 3 × 80
    }

    func testJiaoziTwentyPieces() {
        let item = parseOne("20个饺子")
        XCTAssertEqual(item.matchedFoodID, "jiaozi")
        XCTAssertEqual(item.grams, 400)   // 20 × 20
    }

    func testBoiledEggTwoPieces() {
        let item = parseOne("两个鸡蛋")
        XCTAssertEqual(item.matchedFoodID, "egg_boiled")
        XCTAssertEqual(item.grams, 100)   // 2 × 50
    }

    func testMilkOneCup() {
        let item = parseOne("一杯牛奶")
        XCTAssertEqual(item.matchedFoodID, "milk")
        XCTAssertEqual(item.grams, 250)
    }

    func testMilkMilliliters() {
        let item = parseOne("250ml牛奶")
        XCTAssertEqual(item.matchedFoodID, "milk")
        XCTAssertEqual(item.grams, 250)
    }

    func testBeefThreeLiang() {
        let item = parseOne("三两牛肉")
        XCTAssertEqual(item.matchedFoodID, "beef")
        XCTAssertEqual(item.grams, 150)   // 3 × 50
    }

    func testChickenBreastGrams() {
        let item = parseOne("100克鸡胸肉")
        XCTAssertEqual(item.matchedFoodID, "chicken_breast")
        XCTAssertEqual(item.grams, 100)
    }

    func testMantouOnePiece() {
        let item = parseOne("一个馒头")
        XCTAssertEqual(item.matchedFoodID, "mantou")
        XCTAssertEqual(item.grams, 100)
    }

    func testToastTwoSlices() {
        let item = parseOne("吐司两片")
        XCTAssertEqual(item.matchedFoodID, "whole_wheat_bread")
        XCTAssertEqual(item.grams, 70)    // 2 × 35
    }

    func testNoodlesNoQuantityUsesDefault() {
        // 没说份量 → 默认克数兜底（面条默认 200g），置信度下调
        let item = parseOne("吃面条")
        XCTAssertEqual(item.matchedFoodID, "noodles")
        XCTAssertEqual(item.grams, 200)
        XCTAssertLessThan(item.confidence, 0.9)
    }

    // MARK: - 命中识别（克数依赖表内默认值，只断言命中与正数）

    func testAliasesHit() {
        for (text, expectedID) in [
            ("西红柿", "tomato"),
            ("地瓜", "sweet_potato"),
            ("荷包蛋", "egg_fried"),
            ("泡面", "instant_noodles"),
            ("麻婆豆腐", "mapo_tofu"),
            ("珍珠奶茶", "milk_tea"),
            ("薯条", "french_fries"),
            ("鸡排", "fried_chicken"),
            ("可乐", "cola"),
            ("酸奶", "yogurt"),
            ("西兰花", "broccoli"),
            ("猕猴桃", "kiwi"),
        ] {
            let item = parseOne(text)
            XCTAssertEqual(item.matchedFoodID, expectedID, "「\(text)」命中错误")
            XCTAssertGreaterThan(item.grams ?? 0, 0, "「\(text)」克数应大于 0")
        }
    }

    // MARK: - 多食物混合输入

    func testMixedSentenceThreeItems() {
        let result = service.parse("米饭一碗、番茄炒蛋和一杯牛奶")
        XCTAssertEqual(result.items.count, 3)
        XCTAssertEqual(result.unmatchedSegments.count, 0)
        let ids = Set(result.items.compactMap { $0.matchedFoodID })
        XCTAssertTrue(ids.contains("rice"))
        XCTAssertTrue(ids.contains("tomato_egg"))
        XCTAssertTrue(ids.contains("milk"))
    }

    func testMixedSentenceWithNoise() {
        let result = service.parse("中午吃了一碗面条，还有两个鸡蛋和半个苹果")
        XCTAssertGreaterThanOrEqual(result.items.count, 2)
        XCTAssertTrue(result.unmatchedSegments.isEmpty)
    }

    func testSizeModifierScalesGrams() {
        let item = parseOne("一大碗米饭")
        XCTAssertEqual(item.matchedFoodID, "rice")
        XCTAssertEqual(item.grams ?? 0, 150 * 1.25, accuracy: 0.5)
    }

    // MARK: - 边界与未识别

    func testEmptyInput() {
        let result = service.parse("")
        XCTAssertTrue(result.isEmpty)
        XCTAssertTrue(result.items.isEmpty)
    }

    func testWhitespaceOnlyInput() {
        let result = service.parse("   ")
        XCTAssertTrue(result.isEmpty)
    }

    func testUnmatchedGoesToUnmatchedSegments() {
        let result = service.parse("吃了一顿烧烤")
        XCTAssertTrue(result.items.isEmpty, "词典里没有「烧烤」，不应伪造命中")
        XCTAssertFalse(result.unmatchedSegments.isEmpty)
    }

    func testConfidenceBounded() {
        for text in ["米饭一碗", "两碗米饭", "吃面条", "三个包子", "一杯牛奶"] {
            let item = parseOne(text)
            XCTAssertGreaterThan(item.confidence, 0)
            XCTAssertLessThanOrEqual(item.confidence, 1)
        }
    }
}
