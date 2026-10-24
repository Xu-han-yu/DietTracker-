//
//  ExerciseDatabaseSupplement.swift
//  DietTracker
//
//  2.0 MET 库扩充：**更细粒度的日常活动**（家务拆解 / 通勤 / 搬运 / 带娃 …）。
//
//  为什么单独一个文件：
//    `ExerciseDatabase.all` 原本是一个巨大的数组字面量。新增活动不往里面继续堆，
//    而是把数据放到这里，再在主文件里把 `all` 改成 `core + dailySupplement`。
//
//  ⚠️ 主表已经有的，这里**不重复**（`爬楼梯` / `家务` / `遛狗` 早已在 ExerciseDatabase.swift 里）。
//     本文件补的是它们没覆盖到的细分动作，例如：
//       「家务」太笼统 → 拆出扫地 / 擦窗户 / 洗衣 / 整理收纳 / 做饭 / 洗碗
//       「骑车」只有健身场景 → 补通勤骑行、共享单车
//
//  ⚠️ 别名均与主表做过冲突检查，且刻意让长别名压过主表短别名：
//       「通勤骑行」(4) 胜过主表「骑行」(2)
//       「通勤走路」(4) 胜过主表「走路」(2)
//     但「快」「慢」字样不要写进别名 —— LocalExerciseParsingService 会把它当强度关键词剔除。
//
//  MET 参考 Ainsworth 体力活动概要的常见取值，**全部为估算值**。
//

import Foundation

extension ExerciseDatabase {

    static let dailySupplement: [ExerciseEntryData] = [

        ExerciseEntryData(id: "sweeping", name: "扫地",
                          aliases: ["扫地", "扫地板"],
                          category: .daily,
                          metLow: 2.3, metModerate: 3.3, metHigh: 4.0,
                          defaultMinutes: 20),

        ExerciseEntryData(id: "window_cleaning", name: "擦窗户",
                          aliases: ["擦窗户", "擦玻璃", "擦玻璃窗"],
                          category: .daily,
                          metLow: 2.5, metModerate: 3.5, metHigh: 4.5,
                          defaultMinutes: 20),

        ExerciseEntryData(id: "hand_laundry", name: "手洗衣物",
                          aliases: ["洗衣服", "手洗衣服", "手洗"],
                          category: .daily,
                          metLow: 2.0, metModerate: 3.0, metHigh: 4.0,
                          defaultMinutes: 20),

        ExerciseEntryData(id: "tidying", name: "整理收纳",
                          aliases: ["叠衣服", "熨衣服", "整理收纳", "收拾屋子", "收纳"],
                          category: .daily,
                          metLow: 1.8, metModerate: 2.5, metHigh: 3.3,
                          defaultMinutes: 20),

        ExerciseEntryData(id: "cooking", name: "做饭",
                          aliases: ["做饭", "炒菜", "下厨", "备餐"],
                          category: .daily,
                          metLow: 2.0, metModerate: 2.8, metHigh: 3.5,
                          defaultMinutes: 30),

        ExerciseEntryData(id: "dish_washing", name: "洗碗",
                          aliases: ["洗碗", "刷碗", "洗盘子"],
                          category: .daily,
                          metLow: 1.8, metModerate: 2.5, metHigh: 3.2,
                          defaultMinutes: 15),

        ExerciseEntryData(id: "grocery", name: "买菜拎菜",
                          aliases: ["买菜", "逛超市", "拎菜", "购物"],
                          category: .daily,
                          metLow: 2.0, metModerate: 3.0, metHigh: 4.0,
                          defaultMinutes: 30),

        ExerciseEntryData(id: "commute_walking", name: "通勤步行",
                          aliases: ["通勤走路", "步行通勤", "上下班走路"],
                          category: .daily,
                          metLow: 2.5, metModerate: 3.5, metHigh: 4.3,
                          defaultMinutes: 30),

        ExerciseEntryData(id: "commute_cycling", name: "通勤骑行",
                          aliases: ["通勤骑行", "通勤骑车", "骑车上班", "共享单车", "骑单车"],
                          category: .daily,
                          metLow: 3.5, metModerate: 5.8, metHigh: 8.0,
                          defaultMinutes: 30),

        ExerciseEntryData(id: "carrying_load", name: "搬重物",
                          aliases: ["搬东西", "搬重物", "搬家", "搬货"],
                          category: .daily,
                          metLow: 3.5, metModerate: 5.0, metHigh: 7.0,
                          defaultMinutes: 20),

        ExerciseEntryData(id: "childcare", name: "带娃",
                          aliases: ["带娃", "带小孩", "抱娃", "陪孩子玩"],
                          category: .daily,
                          metLow: 2.0, metModerate: 3.0, metHigh: 4.0,
                          defaultMinutes: 40),

        ExerciseEntryData(id: "car_washing", name: "洗车",
                          aliases: ["洗车"],
                          category: .daily,
                          metLow: 2.5, metModerate: 3.5, metHigh: 4.5,
                          defaultMinutes: 20),

        ExerciseEntryData(id: "gardening", name: "园艺",
                          aliases: ["园艺", "种花", "除草", "浇花", "打理阳台"],
                          category: .daily,
                          metLow: 2.5, metModerate: 3.8, metHigh: 5.0,
                          defaultMinutes: 30),

        ExerciseEntryData(id: "standing_work", name: "站立工作",
                          aliases: ["站着上班", "站立工作", "站班"],
                          category: .daily,
                          metLow: 1.5, metModerate: 2.0, metHigh: 2.5,
                          defaultMinutes: 60),

        ExerciseEntryData(id: "playing_instrument", name: "弹琴",
                          aliases: ["弹钢琴", "弹吉他", "练琴", "弹琴"],
                          category: .daily,
                          metLow: 1.5, metModerate: 2.0, metHigh: 2.5,
                          defaultMinutes: 30)
    ]
}
