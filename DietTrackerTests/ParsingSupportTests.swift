//
//  ParsingSupportTests.swift
//  DietTrackerTests
//
//  中文数字、份量、时长解析的单元测试。
//  这些是食物/运动解析的地基：地基错了，上面全是错的。
//

import XCTest
@testable import DietTracker

final class ParsingSupportTests: XCTestCase {

    // MARK: - 中文数字

    func testChineseNumberBasics() {
        XCTAssertEqual(ChineseNumberParser.parse("0"), 0)
        XCTAssertEqual(ChineseNumberParser.parse("3"), 3)
        XCTAssertEqual(ChineseNumberParser.parse("3.5"), 3.5)
        XCTAssertEqual(ChineseNumberParser.parse("一"), 1)
        XCTAssertEqual(ChineseNumberParser.parse("两"), 2)   // 「两」是数词
        XCTAssertEqual(ChineseNumberParser.parse("半"), 0.5)
    }

    func testChineseNumberTens() {
        XCTAssertEqual(ChineseNumberParser.parse("十"), 10)
        XCTAssertEqual(ChineseNumberParser.parse("十五"), 15)
        XCTAssertEqual(ChineseNumberParser.parse("二十"), 20)
        XCTAssertEqual(ChineseNumberParser.parse("二十五"), 25)
    }

    func testChineseNumberInvalid() {
        XCTAssertNil(ChineseNumberParser.parse(""))
        XCTAssertNil(ChineseNumberParser.parse("abc"))
        XCTAssertNil(ChineseNumberParser.parse("几百"))
    }

    // MARK: - 份量

    func testQuantityArabicNumber() {
        let m = QuantityParser.firstMatch(in: "200克鸡胸肉")
        XCTAssertNotNil(m)
        XCTAssertEqual(m?.value, 200)
        XCTAssertEqual(m?.unit, .gram)
        XCTAssertEqual(m?.scale, 1)
    }

    func testQuantityChineseNumber() {
        let m = QuantityParser.firstMatch(in: "两碗米饭")
        XCTAssertNotNil(m)
        XCTAssertEqual(m?.value, 2)          // 「两」作数词
        XCTAssertEqual(m?.unit, .bowl)
    }

    /// 「三两牛肉」：数词「三」+ 重量单位「两」。这是第 4 步修过的关键坑。
    func testQuantityLiangAsUnit() {
        let m = QuantityParser.firstMatch(in: "三两牛肉")
        XCTAssertNotNil(m)
        XCTAssertEqual(m?.value, 3)
        XCTAssertEqual(m?.unit, .liang)      // 「两」作单位
    }

    func testQuantitySizeModifier() {
        let big = QuantityParser.firstMatch(in: "一大碗米饭")
        XCTAssertNotNil(big)
        XCTAssertEqual(big?.value, 1)
        XCTAssertEqual(big?.scale, 1.25, accuracy: 0.001)   // 大

        let small = QuantityParser.firstMatch(in: "一小份沙拉")
        XCTAssertNotNil(small)
        XCTAssertEqual(small?.scale, 0.75, accuracy: 0.001) // 小
    }

    func testQuantityMilliliter() {
        let m = QuantityParser.firstMatch(in: "250ml牛奶")
        XCTAssertNotNil(m)
        XCTAssertEqual(m?.value, 250)
        XCTAssertEqual(m?.unit, .ml)
    }

    func testQuantityNotFound() {
        XCTAssertNil(QuantityParser.firstMatch(in: "吃了顿火锅"))
    }

    // MARK: - 时长

    func testDurationMinutes() {
        XCTAssertEqual(DurationParser.totalMinutes(in: "30分钟"), 30)
        XCTAssertEqual(DurationParser.totalMinutes(in: "跑了45分"), 45)
        XCTAssertEqual(DurationParser.totalMinutes(in: "45 mins"), 45)
    }

    func testDurationHours() {
        XCTAssertEqual(DurationParser.totalMinutes(in: "1小时"), 60)
        XCTAssertEqual(DurationParser.totalMinutes(in: "2h"), 120)
        XCTAssertEqual(DurationParser.totalMinutes(in: "快走一小时"), 60)
    }

    func testDurationComposed() {
        // 求和而不是取第一个：1小时30分钟 = 90
        XCTAssertEqual(DurationParser.totalMinutes(in: "1小时30分钟"), 90)
        // 「一个半小时」必须整体识别为 90，而不是内部的「半小时」= 30
        XCTAssertEqual(DurationParser.totalMinutes(in: "一个半小时"), 90)
    }

    func testDurationSpecialWords() {
        XCTAssertEqual(DurationParser.totalMinutes(in: "半小时"), 30)
        XCTAssertEqual(DurationParser.totalMinutes(in: "一刻钟"), 15)
    }

    func testDurationNotFound() {
        XCTAssertNil(DurationParser.totalMinutes(in: "随便动动"))
        XCTAssertNil(DurationParser.totalMinutes(in: ""))
    }

    // MARK: - 分句

    func testSegmenterChinesePunctuation() {
        let parts = TextSegmenter.split("米饭一碗、番茄炒蛋、一杯牛奶")
        XCTAssertEqual(parts.count, 3)
        XCTAssertEqual(parts[0], "米饭一碗")
        XCTAssertEqual(parts[1], "番茄炒蛋")
        XCTAssertEqual(parts[2], "一杯牛奶")
    }

    func testSegmenterConjunctions() {
        let parts = TextSegmenter.split("米饭和面条还有鸡蛋")
        XCTAssertEqual(parts.count, 3)
    }

    func testSegmenterSingleSegment() {
        XCTAssertEqual(TextSegmenter.split("一碗米饭"), ["一碗米饭"])
    }
}
