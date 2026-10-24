//
//  FoodDatabaseSupplement.swift
//  DietTracker
//
//  2.0 食物库扩充：**中式菜品 / 零食甜品 / 现制饮品**。
//
//  为什么单独一个文件：
//    `FoodDatabase.all` 本来就是「子数组相加」的形式，新增数据只要往这里加数组、
//    再改 `FoodDatabase.swift` 里 `all` 那一行即可，主文件一行业务代码都不用动。
//
//  ⚠️ 数值口径与原表一致：**每 100g 可食部**，参考中国食物成分表与常见门店份量的经验值，
//     全部属于**估算**。饮品按实际甜度（多为标准糖）估算，选无糖请让用户手动修正。
//
//  ⚠️ 别名冲突检查（重要）：
//     `aliasIndex` 按别名长度降序命中。本文件所有别名都已避开主表现有别名，
//     且刻意让「更长的别名」压过主表的短别名，例如：
//       「豆腐脑」(3) 胜过主表「豆腐」(2)      —— 豆花不会被算成北豆腐
//       「酸菜鱼」(3) 胜过主表「鲈鱼/鱼」      —— 不会退化成一条清蒸鱼
//     改动任何一个别名前，先确认它不会误伤主表。
//

import Foundation

extension FoodDatabase {

    // MARK: - 中式菜品（一）

    static let supplementDishesA: [FoodEntry] = [

        FoodEntry(id: "huangmen_chicken", name: "黄焖鸡", aliases: ["黄焖鸡", "黄焖鸡米饭", "黄焖鸡肉"],
                  category: .dish,
                  per100g: .per100g(145, 10.5, 7.5, 8.0, ca: 18, fe: 1.2, fb: 1.0),
                  portions: [.serving: 350, .bowl: 400], defaultGrams: 350),

        FoodEntry(id: "yuxiang_pork", name: "鱼香肉丝", aliases: ["鱼香肉丝", "鱼香肉丝盖饭"],
                  category: .dish,
                  per100g: .per100g(165, 8.5, 9.0, 11.0, ca: 20, fe: 1.5, vc: 8, fb: 1.2),
                  portions: [.serving: 250, .plate: 300], defaultGrams: 250),

        FoodEntry(id: "sweet_sour_pork", name: "糖醋里脊", aliases: ["糖醋里脊"],
                  category: .dish,
                  per100g: .per100g(250, 10.0, 14.0, 20.0, ca: 22, fe: 1.4),
                  portions: [.serving: 200, .plate: 250], defaultGrams: 200),

        FoodEntry(id: "sweet_sour_ribs", name: "糖醋排骨", aliases: ["糖醋排骨", "红烧排骨", "排骨"],
                  category: .dish,
                  per100g: .per100g(278, 14.0, 20.0, 10.0, ca: 45, fe: 1.8),
                  portions: [.serving: 200, .plate: 250], defaultGrams: 200),

        FoodEntry(id: "braised_lion_head", name: "狮子头", aliases: ["红烧狮子头", "狮子头", "四喜丸子"],
                  category: .dish,
                  per100g: .per100g(290, 12.0, 22.0, 10.0, ca: 30, fe: 1.6),
                  portions: [.piece: 80, .serving: 200], defaultGrams: 160),

        FoodEntry(id: "twice_cooked_pork", name: "回锅肉", aliases: ["回锅肉"],
                  category: .dish,
                  per100g: .per100g(330, 12.0, 26.0, 8.0, ca: 18, fe: 1.5, fb: 1.5),
                  portions: [.serving: 200, .plate: 250], defaultGrams: 200),

        FoodEntry(id: "meicai_pork", name: "梅菜扣肉", aliases: ["梅菜扣肉", "扣肉"],
                  category: .dish,
                  per100g: .per100g(400, 10.0, 36.0, 9.0, ca: 35, fe: 1.6, fb: 2.0),
                  portions: [.serving: 150, .plate: 200], defaultGrams: 150),

        FoodEntry(id: "boiled_beef", name: "水煮牛肉", aliases: ["水煮牛肉", "水煮肉片"],
                  category: .dish,
                  per100g: .per100g(200, 14.0, 13.0, 6.0, ca: 20, fe: 2.2, fb: 1.5),
                  portions: [.serving: 300, .bowl: 400], defaultGrams: 300),

        FoodEntry(id: "boiled_fish", name: "水煮鱼", aliases: ["水煮鱼", "沸腾鱼"],
                  category: .dish,
                  per100g: .per100g(180, 15.0, 11.0, 4.0, ca: 40, fe: 1.6),
                  portions: [.serving: 350, .bowl: 450], defaultGrams: 350),

        FoodEntry(id: "sour_cabbage_fish", name: "酸菜鱼", aliases: ["酸菜鱼", "酸汤鱼"],
                  category: .dish,
                  per100g: .per100g(140, 14.0, 7.0, 5.0, ca: 55, fe: 1.5, fb: 1.0),
                  portions: [.serving: 350, .bowl: 450], defaultGrams: 350),

        FoodEntry(id: "grilled_fish", name: "烤鱼", aliases: ["烤鱼", "万州烤鱼"],
                  category: .dish,
                  per100g: .per100g(180, 16.0, 11.0, 4.0, ca: 45, fe: 1.8),
                  portions: [.serving: 350, .plate: 450], defaultGrams: 350),

        FoodEntry(id: "spicy_chicken", name: "辣子鸡", aliases: ["辣子鸡", "干锅鸡", "辣子鸡丁"],
                  category: .dish,
                  per100g: .per100g(250, 18.0, 17.0, 6.0, ca: 22, fe: 1.6, fb: 1.2),
                  portions: [.serving: 250, .plate: 300], defaultGrams: 250),

        FoodEntry(id: "sanbei_chicken", name: "三杯鸡", aliases: ["三杯鸡"],
                  category: .dish,
                  per100g: .per100g(220, 16.0, 13.0, 8.0, ca: 20, fe: 1.4),
                  portions: [.serving: 250, .plate: 300], defaultGrams: 250),

        FoodEntry(id: "cola_chicken_wing", name: "可乐鸡翅", aliases: ["可乐鸡翅"],
                  category: .dish,
                  per100g: .per100g(230, 15.0, 13.0, 12.0, ca: 25, fe: 1.3),
                  portions: [.piece: 60, .serving: 200], defaultGrams: 180),

        FoodEntry(id: "beer_duck", name: "啤酒鸭", aliases: ["啤酒鸭"],
                  category: .dish,
                  per100g: .per100g(240, 16.0, 18.0, 4.0, ca: 26, fe: 2.4),
                  portions: [.serving: 250, .bowl: 400], defaultGrams: 250),

        FoodEntry(id: "dongpo_pork", name: "东坡肉", aliases: ["东坡肉"],
                  category: .dish,
                  per100g: .per100g(450, 10.0, 42.0, 8.0, ca: 15, fe: 1.4),
                  portions: [.piece: 60, .serving: 150], defaultGrams: 120),

        FoodEntry(id: "di_san_xian", name: "地三鲜", aliases: ["地三鲜"],
                  category: .dish,
                  per100g: .per100g(150, 3.0, 11.0, 9.0, ca: 20, fe: 1.0, vc: 15, fb: 2.2),
                  portions: [.serving: 250, .plate: 300], defaultGrams: 250),

        FoodEntry(id: "dry_green_beans", name: "干煸豆角", aliases: ["干煸豆角"],
                  category: .dish,
                  per100g: .per100g(160, 4.0, 12.0, 8.0, ca: 45, fe: 1.6, vc: 10, fb: 3.0),
                  portions: [.serving: 200, .plate: 250], defaultGrams: 200),

        FoodEntry(id: "stir_fry_greens", name: "清炒时蔬", aliases: ["清炒时蔬", "炒青菜", "蒜蓉青菜"],
                  category: .dish,
                  per100g: .per100g(90, 2.0, 6.5, 6.0, ca: 60, fe: 1.2, vc: 30, fb: 2.5),
                  portions: [.serving: 200, .plate: 250], defaultGrams: 200),

        FoodEntry(id: "oyster_lettuce", name: "蚝油生菜", aliases: ["蚝油生菜"],
                  category: .dish,
                  per100g: .per100g(70, 1.5, 5.0, 4.0, ca: 40, fe: 1.0, vc: 15, fb: 1.5),
                  portions: [.serving: 200, .plate: 250], defaultGrams: 200),

        FoodEntry(id: "hand_torn_cabbage", name: "手撕包菜", aliases: ["手撕包菜", "干锅包菜"],
                  category: .dish,
                  per100g: .per100g(90, 2.0, 6.5, 7.0, ca: 50, fe: 0.9, vc: 35, fb: 2.0),
                  portions: [.serving: 200, .plate: 250], defaultGrams: 200),

        FoodEntry(id: "sour_spicy_potato", name: "酸辣土豆丝", aliases: ["酸辣土豆丝", "土豆丝"],
                  category: .dish,
                  per100g: .per100g(110, 2.0, 5.5, 15.0, ca: 15, fe: 0.9, vc: 12, fb: 1.8),
                  portions: [.serving: 200, .plate: 250], defaultGrams: 200),

        FoodEntry(id: "smashed_cucumber", name: "凉拌黄瓜", aliases: ["凉拌黄瓜", "拍黄瓜"],
                  category: .dish,
                  per100g: .per100g(60, 1.2, 4.5, 4.0, ca: 20, fe: 0.5, vc: 10, fb: 0.8),
                  portions: [.serving: 150, .plate: 200], defaultGrams: 150),

        FoodEntry(id: "century_egg_tofu", name: "皮蛋豆腐", aliases: ["皮蛋豆腐", "凉拌皮蛋"],
                  category: .dish,
                  per100g: .per100g(120, 8.5, 8.5, 3.0, ca: 130, fe: 2.6),
                  portions: [.serving: 150, .plate: 200], defaultGrams: 150),

        FoodEntry(id: "tomato_brisket", name: "西红柿牛腩", aliases: ["西红柿牛腩", "番茄牛腩"],
                  category: .dish,
                  per100g: .per100g(150, 12.0, 8.0, 6.0, ca: 22, fe: 2.6, vc: 10, fb: 1.2),
                  portions: [.serving: 250, .bowl: 350], defaultGrams: 250),

        FoodEntry(id: "potato_beef_stew", name: "土豆炖牛肉", aliases: ["土豆炖牛肉", "牛肉炖土豆", "咖喱牛肉"],
                  category: .dish,
                  per100g: .per100g(150, 12.0, 7.0, 10.0, ca: 20, fe: 2.4, fb: 1.4),
                  portions: [.serving: 250, .bowl: 350], defaultGrams: 250)
    ]

    // MARK: - 中式菜品（二）

    static let supplementDishesB: [FoodEntry] = [

        FoodEntry(id: "black_pepper_beef", name: "铁板牛肉", aliases: ["铁板牛肉", "黑椒牛柳"],
                  category: .dish,
                  per100g: .per100g(220, 18.0, 13.0, 6.0, ca: 18, fe: 2.8),
                  portions: [.serving: 250, .plate: 300], defaultGrams: 250),

        FoodEntry(id: "cumin_lamb", name: "孜然羊肉", aliases: ["孜然羊肉", "葱爆羊肉"],
                  category: .dish,
                  per100g: .per100g(220, 18.0, 15.0, 4.0, ca: 20, fe: 2.6, fb: 1.0),
                  portions: [.serving: 250, .plate: 300], defaultGrams: 250),

        FoodEntry(id: "lamb_skewer", name: "羊肉串", aliases: ["羊肉串", "烤串", "撸串"],
                  category: .dish,
                  per100g: .per100g(250, 20.0, 16.0, 4.0, ca: 15, fe: 2.5),
                  portions: [.piece: 40, .serving: 200], defaultGrams: 200),

        FoodEntry(id: "jingjiang_pork", name: "京酱肉丝", aliases: ["京酱肉丝"],
                  category: .dish,
                  per100g: .per100g(200, 12.0, 10.0, 12.0, ca: 24, fe: 1.6, fb: 1.2),
                  portions: [.serving: 200, .plate: 250], defaultGrams: 200),

        FoodEntry(id: "malatang_xiangguo", name: "麻辣香锅", aliases: ["麻辣香锅", "香锅"],
                  category: .dish,
                  per100g: .per100g(200, 10.0, 14.0, 10.0, ca: 45, fe: 2.0, vc: 12, fb: 2.5),
                  portions: [.serving: 350, .bowl: 450], defaultGrams: 350),

        FoodEntry(id: "maocai", name: "冒菜", aliases: ["冒菜"],
                  category: .dish,
                  per100g: .per100g(150, 7.0, 10.0, 10.0, ca: 40, fe: 1.8, vc: 15, fb: 2.5),
                  portions: [.bowl: 500, .serving: 450], defaultGrams: 500),

        FoodEntry(id: "braised_hairtail", name: "红烧带鱼", aliases: ["红烧带鱼", "带鱼"],
                  category: .dish,
                  per100g: .per100g(210, 18.0, 13.0, 5.0, ca: 90, fe: 1.6),
                  portions: [.serving: 200, .plate: 250], defaultGrams: 200),

        FoodEntry(id: "fish_head_chili", name: "剁椒鱼头", aliases: ["剁椒鱼头", "鱼头"],
                  category: .dish,
                  per100g: .per100g(150, 14.0, 9.0, 4.0, ca: 60, fe: 1.5, fb: 1.0),
                  portions: [.serving: 350, .plate: 450], defaultGrams: 350),

        FoodEntry(id: "garlic_shrimp", name: "蒜蓉粉丝虾", aliases: ["蒜蓉粉丝虾", "蒜蓉虾"],
                  category: .dish,
                  per100g: .per100g(150, 14.0, 6.0, 12.0, ca: 65, fe: 1.8),
                  portions: [.serving: 250, .plate: 300], defaultGrams: 250),

        FoodEntry(id: "crayfish", name: "小龙虾", aliases: ["小龙虾", "麻辣小龙虾"],
                  category: .dish,
                  per100g: .per100g(140, 16.0, 6.0, 5.0, ca: 85, fe: 2.0),
                  portions: [.serving: 300, .plate: 500], defaultGrams: 300),

        FoodEntry(id: "bobochicken", name: "钵钵鸡", aliases: ["钵钵鸡"],
                  category: .dish,
                  per100g: .per100g(180, 14.0, 11.0, 5.0, ca: 25, fe: 1.4, fb: 1.2),
                  portions: [.serving: 250, .bowl: 350], defaultGrams: 250),

        FoodEntry(id: "white_cut_chicken", name: "白切鸡", aliases: ["白切鸡", "文昌鸡"],
                  category: .dish,
                  per100g: .per100g(190, 20.0, 11.0, 2.0, ca: 18, fe: 1.4),
                  portions: [.serving: 200, .plate: 300], defaultGrams: 200),

        FoodEntry(id: "lanzhou_noodles", name: "兰州拉面", aliases: ["兰州拉面", "牛肉拉面", "拉面"],
                  category: .dish,
                  per100g: .per100g(150, 7.0, 3.0, 24.0, ca: 20, fe: 1.2, fb: 1.2),
                  portions: [.bowl: 500, .serving: 450], defaultGrams: 500),

        FoodEntry(id: "zhajiang_noodles", name: "炸酱面", aliases: ["炸酱面"],
                  category: .dish,
                  per100g: .per100g(230, 8.0, 8.0, 30.0, ca: 25, fe: 1.6, fb: 1.8),
                  portions: [.bowl: 300, .serving: 300], defaultGrams: 300),

        FoodEntry(id: "dandan_noodles", name: "担担面", aliases: ["担担面"],
                  category: .dish,
                  per100g: .per100g(210, 8.0, 10.0, 22.0, ca: 22, fe: 1.5, fb: 1.5),
                  portions: [.bowl: 300, .serving: 300], defaultGrams: 300),

        FoodEntry(id: "hot_dry_noodles", name: "热干面", aliases: ["热干面"],
                  category: .dish,
                  per100g: .per100g(280, 9.0, 12.0, 33.0, ca: 30, fe: 1.8, fb: 1.6),
                  portions: [.bowl: 280, .serving: 280], defaultGrams: 280),

        FoodEntry(id: "luosifen", name: "螺蛳粉", aliases: ["螺蛳粉"],
                  category: .dish,
                  per100g: .per100g(160, 4.0, 6.5, 22.0, ca: 30, fe: 1.2, fb: 1.8),
                  portions: [.bowl: 400, .serving: 400], defaultGrams: 400),

        FoodEntry(id: "sour_spicy_noodles", name: "酸辣粉", aliases: ["酸辣粉"],
                  category: .dish,
                  per100g: .per100g(140, 3.0, 5.5, 22.0, ca: 20, fe: 1.0, fb: 1.5),
                  portions: [.bowl: 350, .serving: 350], defaultGrams: 350),

        FoodEntry(id: "rice_noodles", name: "米线", aliases: ["米线", "过桥米线"],
                  category: .dish,
                  per100g: .per100g(130, 5.0, 4.0, 20.0, ca: 25, fe: 1.1, fb: 1.0),
                  portions: [.bowl: 450, .serving: 450], defaultGrams: 450),

        FoodEntry(id: "rice_roll", name: "肠粉", aliases: ["肠粉", "鸡蛋肠粉"],
                  category: .dish,
                  per100g: .per100g(140, 5.0, 4.5, 20.0, ca: 30, fe: 1.2, fb: 0.8),
                  portions: [.plate: 250, .serving: 250], defaultGrams: 250),

        FoodEntry(id: "roujiamo", name: "肉夹馍", aliases: ["肉夹馍", "腊汁肉夹馍"],
                  category: .dish,
                  per100g: .per100g(280, 12.0, 14.0, 26.0, ca: 30, fe: 1.8, fb: 1.5),
                  portions: [.piece: 150], defaultGrams: 150),

        FoodEntry(id: "jianbing", name: "煎饼果子", aliases: ["煎饼果子", "煎饼"],
                  category: .dish,
                  per100g: .per100g(220, 7.0, 9.0, 28.0, ca: 40, fe: 1.5, fb: 1.8),
                  portions: [.piece: 200], defaultGrams: 200),

        FoodEntry(id: "xiaolongbao", name: "小笼包", aliases: ["小笼包", "灌汤包"],
                  category: .dish,
                  per100g: .per100g(230, 8.0, 8.0, 30.0, ca: 22, fe: 1.4, fb: 1.0),
                  portions: [.piece: 25, .serving: 150], defaultGrams: 150),

        FoodEntry(id: "shengjianbao", name: "生煎包", aliases: ["生煎包", "生煎"],
                  category: .dish,
                  per100g: .per100g(280, 10.0, 15.0, 26.0, ca: 25, fe: 1.6, fb: 1.2),
                  portions: [.piece: 40, .serving: 160], defaultGrams: 160),

        FoodEntry(id: "shaomai", name: "烧麦", aliases: ["烧麦", "烧卖"],
                  category: .dish,
                  per100g: .per100g(240, 9.0, 9.0, 30.0, ca: 20, fe: 1.5, fb: 1.0),
                  portions: [.piece: 30, .serving: 150], defaultGrams: 150),

        FoodEntry(id: "sandwich", name: "三明治", aliases: ["三明治", "火腿三明治"],
                  category: .dish,
                  per100g: .per100g(250, 12.0, 10.0, 28.0, ca: 120, fe: 1.6, fb: 1.8),
                  portions: [.piece: 150], defaultGrams: 150),

        FoodEntry(id: "onigiri", name: "饭团", aliases: ["饭团", "饭团寿司"],
                  category: .dish,
                  per100g: .per100g(180, 6.0, 4.0, 30.0, ca: 18, fe: 0.8, fb: 1.0),
                  portions: [.piece: 150], defaultGrams: 150),

        FoodEntry(id: "sushi", name: "寿司", aliases: ["寿司", "寿司卷"],
                  category: .dish,
                  per100g: .per100g(150, 5.0, 2.0, 28.0, ca: 25, fe: 0.9, fb: 1.0),
                  portions: [.piece: 20, .serving: 200], defaultGrams: 200),

        FoodEntry(id: "curry_rice", name: "咖喱饭", aliases: ["咖喱饭", "日式咖喱"],
                  category: .dish,
                  per100g: .per100g(150, 5.0, 6.0, 22.0, ca: 35, fe: 1.2, fb: 1.6),
                  portions: [.plate: 400, .serving: 400], defaultGrams: 400),

        FoodEntry(id: "claypot_rice", name: "煲仔饭", aliases: ["煲仔饭", "砂锅饭"],
                  category: .dish,
                  per100g: .per100g(180, 8.0, 7.0, 24.0, ca: 25, fe: 1.5, fb: 1.0),
                  portions: [.bowl: 450], defaultGrams: 450),

        FoodEntry(id: "omurice", name: "蛋包饭", aliases: ["蛋包饭"],
                  category: .dish,
                  per100g: .per100g(180, 7.0, 7.5, 24.0, ca: 35, fe: 1.4, fb: 1.0),
                  portions: [.plate: 400, .serving: 400], defaultGrams: 400)
    ]

    // MARK: - 零食 / 甜品

    static let supplementSnacks: [FoodEntry] = [

        FoodEntry(id: "latiao", name: "辣条", aliases: ["辣条", "卫龙辣条"],
                  category: .snack,
                  per100g: .per100g(450, 8.0, 22.0, 55.0, ca: 60, fe: 2.0, fb: 3.0),
                  portions: [.bag: 80, .serving: 50], defaultGrams: 50),

        FoodEntry(id: "potato_chips", name: "薯片", aliases: ["薯片", "虾条", "乐事"],
                  category: .snack,
                  per100g: .per100g(550, 6.0, 35.0, 52.0, ca: 30, fe: 1.5, fb: 4.5),
                  portions: [.bag: 70, .serving: 40], defaultGrams: 40),

        FoodEntry(id: "moyu_shuang", name: "魔芋爽", aliases: ["魔芋爽"],
                  category: .snack,
                  per100g: .per100g(90, 2.0, 4.0, 10.0, ca: 40, fe: 0.8, fb: 6.0),
                  portions: [.bag: 20, .piece: 20], defaultGrams: 20),

        FoodEntry(id: "sunflower_seeds", name: "瓜子", aliases: ["瓜子", "葵花籽"],
                  category: .snack,
                  per100g: .per100g(600, 23.0, 52.0, 17.0, ca: 70, fe: 4.5, fb: 9.0),
                  portions: [.handful: 30, .bag: 100], defaultGrams: 30),

        FoodEntry(id: "crackers", name: "饼干", aliases: ["饼干", "苏打饼干"],
                  category: .snack,
                  per100g: .per100g(435, 8.0, 13.0, 70.0, ca: 60, fe: 1.5, fb: 2.5),
                  portions: [.piece: 8, .bag: 100], defaultGrams: 30),

        FoodEntry(id: "cookies", name: "曲奇", aliases: ["曲奇", "曲奇饼干"],
                  category: .snack,
                  per100g: .per100g(500, 6.0, 25.0, 63.0, ca: 45, fe: 1.5, fb: 2.0),
                  portions: [.piece: 12, .bag: 100], defaultGrams: 30),

        FoodEntry(id: "egg_roll_snack", name: "蛋卷", aliases: ["蛋卷", "鸡蛋卷"],
                  category: .snack,
                  per100g: .per100g(500, 7.0, 25.0, 62.0, ca: 50, fe: 1.8, fb: 1.5),
                  portions: [.piece: 10, .bag: 120], defaultGrams: 30),

        FoodEntry(id: "saqima", name: "沙琪玛", aliases: ["沙琪玛", "萨其马"],
                  category: .snack,
                  per100g: .per100g(420, 6.0, 18.0, 60.0, ca: 40, fe: 1.2, fb: 1.0),
                  portions: [.piece: 30, .serving: 40], defaultGrams: 40),

        FoodEntry(id: "walnut_cookie", name: "桃酥", aliases: ["桃酥"],
                  category: .snack,
                  per100g: .per100g(480, 7.0, 24.0, 60.0, ca: 45, fe: 1.8, fb: 2.0),
                  portions: [.piece: 30], defaultGrams: 30),

        FoodEntry(id: "mungbean_cake", name: "绿豆糕", aliases: ["绿豆糕"],
                  category: .snack,
                  per100g: .per100g(350, 6.0, 10.0, 58.0, ca: 35, fe: 1.4, fb: 2.5),
                  portions: [.piece: 30], defaultGrams: 30),

        FoodEntry(id: "egg_yolk_pastry", name: "蛋黄酥", aliases: ["蛋黄酥"],
                  category: .snack,
                  per100g: .per100g(390, 8.0, 20.0, 45.0, ca: 60, fe: 1.8, fb: 1.5),
                  portions: [.piece: 60], defaultGrams: 60),

        FoodEntry(id: "wife_cake", name: "老婆饼", aliases: ["老婆饼"],
                  category: .snack,
                  per100g: .per100g(400, 6.0, 18.0, 55.0, ca: 30, fe: 1.2, fb: 1.5),
                  portions: [.piece: 50], defaultGrams: 50),

        FoodEntry(id: "pineapple_cake", name: "凤梨酥", aliases: ["凤梨酥"],
                  category: .snack,
                  per100g: .per100g(450, 5.0, 22.0, 58.0, ca: 35, fe: 1.3, fb: 2.0),
                  portions: [.piece: 40], defaultGrams: 40),

        FoodEntry(id: "mooncake", name: "月饼", aliases: ["月饼", "双黄莲蓉月饼"],
                  category: .snack,
                  per100g: .per100g(400, 7.0, 18.0, 55.0, ca: 60, fe: 2.0, fb: 2.5),
                  portions: [.piece: 80], defaultGrams: 80),

        FoodEntry(id: "zongzi", name: "粽子", aliases: ["粽子", "肉粽", "豆沙粽"],
                  category: .snack,
                  per100g: .per100g(200, 5.0, 4.5, 35.0, ca: 25, fe: 1.2, fb: 1.5),
                  portions: [.piece: 120], defaultGrams: 120),

        FoodEntry(id: "tangyuan", name: "汤圆", aliases: ["汤圆", "元宵"],
                  category: .snack,
                  per100g: .per100g(300, 4.0, 6.0, 58.0, ca: 30, fe: 1.0, fb: 1.5),
                  portions: [.piece: 20, .bowl: 120], defaultGrams: 100),

        FoodEntry(id: "egg_tart", name: "蛋挞", aliases: ["蛋挞", "葡式蛋挞"],
                  category: .snack,
                  per100g: .per100g(260, 5.0, 16.0, 24.0, ca: 55, fe: 1.0),
                  portions: [.piece: 60], defaultGrams: 60),

        FoodEntry(id: "puff", name: "泡芙", aliases: ["泡芙"],
                  category: .snack,
                  per100g: .per100g(300, 5.0, 20.0, 25.0, ca: 50, fe: 0.9, fb: 1.0),
                  portions: [.piece: 30, .serving: 60], defaultGrams: 60),

        FoodEntry(id: "cake_slice", name: "蛋糕", aliases: ["蛋糕", "奶油蛋糕", "戚风蛋糕"],
                  category: .snack,
                  per100g: .per100g(320, 5.0, 15.0, 42.0, ca: 90, fe: 1.2, fb: 1.0),
                  portions: [.slice: 80, .piece: 100], defaultGrams: 100),

        FoodEntry(id: "tiramisu", name: "提拉米苏", aliases: ["提拉米苏"],
                  category: .snack,
                  per100g: .per100g(350, 6.0, 22.0, 32.0, ca: 80, fe: 1.3),
                  portions: [.piece: 100, .slice: 100], defaultGrams: 100),

        FoodEntry(id: "cheese_cake", name: "芝士蛋糕", aliases: ["芝士蛋糕", "重芝士"],
                  category: .snack,
                  per100g: .per100g(320, 7.0, 22.0, 25.0, ca: 180, fe: 1.0),
                  portions: [.slice: 100, .piece: 100], defaultGrams: 100),

        FoodEntry(id: "pudding", name: "布丁", aliases: ["布丁", "果冻"],
                  category: .snack,
                  per100g: .per100g(120, 3.0, 2.0, 22.0, ca: 60, fe: 0.3),
                  portions: [.piece: 100, .cup: 150], defaultGrams: 100),

        FoodEntry(id: "ice_cream", name: "冰淇淋", aliases: ["冰淇淋", "雪糕", "冰棍"],
                  category: .snack,
                  per100g: .per100g(200, 3.0, 11.0, 22.0, ca: 100, fe: 0.3),
                  portions: [.piece: 80, .cup: 100], defaultGrams: 80),

        FoodEntry(id: "chocolate", name: "巧克力", aliases: ["巧克力", "黑巧克力", "德芙"],
                  category: .snack,
                  per100g: .per100g(546, 6.0, 32.0, 58.0, ca: 110, fe: 2.5, fb: 6.0),
                  portions: [.piece: 10, .block: 50, .bag: 100], defaultGrams: 30),

        FoodEntry(id: "gummy", name: "软糖", aliases: ["软糖", "橡皮糖"],
                  category: .snack,
                  per100g: .per100g(350, 3.0, 0.2, 80.0),
                  portions: [.piece: 5, .bag: 60], defaultGrams: 30),

        FoodEntry(id: "milk_candy", name: "牛奶糖", aliases: ["牛奶糖", "大白兔"],
                  category: .snack,
                  per100g: .per100g(400, 3.0, 10.0, 72.0, ca: 90, fe: 0.4),
                  portions: [.piece: 5, .bag: 60], defaultGrams: 25),

        FoodEntry(id: "pork_jerky", name: "猪肉脯", aliases: ["猪肉脯", "肉脯", "肉干"],
                  category: .snack,
                  per100g: .per100g(350, 30.0, 10.0, 30.0, ca: 20, fe: 2.5),
                  portions: [.piece: 15, .bag: 100], defaultGrams: 40),

        FoodEntry(id: "beef_jerky", name: "牛肉干", aliases: ["牛肉干", "牛肉粒"],
                  category: .snack,
                  per100g: .per100g(400, 35.0, 12.0, 25.0, ca: 25, fe: 3.5),
                  portions: [.piece: 10, .bag: 50], defaultGrams: 40),

        FoodEntry(id: "squid_shreds", name: "鱿鱼丝", aliases: ["鱿鱼丝"],
                  category: .snack,
                  per100g: .per100g(320, 45.0, 4.0, 25.0, ca: 40, fe: 2.0),
                  portions: [.bag: 30, .serving: 30], defaultGrams: 30),

        FoodEntry(id: "duck_neck", name: "鸭脖", aliases: ["鸭脖", "绝味鸭脖"],
                  category: .snack,
                  per100g: .per100g(200, 20.0, 10.0, 6.0, ca: 40, fe: 2.4),
                  portions: [.root: 50, .bag: 150], defaultGrams: 100),

        FoodEntry(id: "quail_egg_snack", name: "鹌鹑蛋", aliases: ["鹌鹑蛋"],
                  category: .snack,
                  per100g: .per100g(160, 13.0, 11.0, 2.0, ca: 60, fe: 2.2),
                  portions: [.piece: 10, .bag: 100], defaultGrams: 50),

        FoodEntry(id: "ice_jelly", name: "冰粉", aliases: ["冰粉"],
                  category: .snack,
                  per100g: .per100g(80, 0.2, 0, 20.0, ca: 15, fe: 0.2),
                  portions: [.bowl: 250, .cup: 300], defaultGrams: 250),

        FoodEntry(id: "double_skin_milk", name: "双皮奶", aliases: ["双皮奶"],
                  category: .snack,
                  per100g: .per100g(150, 5.0, 6.0, 20.0, ca: 110, fe: 0.4),
                  portions: [.bowl: 150, .cup: 200], defaultGrams: 150),

        FoodEntry(id: "guilinggao", name: "龟苓膏", aliases: ["龟苓膏"],
                  category: .snack,
                  per100g: .per100g(90, 1.0, 0.2, 21.0, ca: 25, fe: 0.5),
                  portions: [.bowl: 200, .cup: 250], defaultGrams: 200),

        FoodEntry(id: "sesame_paste_soup", name: "芝麻糊", aliases: ["芝麻糊", "黑芝麻糊"],
                  category: .snack,
                  per100g: .per100g(180, 5.0, 6.0, 28.0, ca: 300, fe: 4.0, fb: 3.0),
                  portions: [.bowl: 250, .bag: 30], defaultGrams: 250),

        FoodEntry(id: "tofu_pudding", name: "豆花", aliases: ["豆花", "豆腐脑"],
                  category: .snack,
                  per100g: .per100g(60, 5.0, 3.0, 4.0, ca: 120, fe: 1.5, fb: 0.5),
                  portions: [.bowl: 300], defaultGrams: 300),

        FoodEntry(id: "liangfen", name: "凉粉", aliases: ["凉粉"],
                  category: .snack,
                  per100g: .per100g(70, 1.0, 0.3, 16.0, ca: 12, fe: 0.4),
                  portions: [.bowl: 250, .plate: 250], defaultGrams: 250),

        FoodEntry(id: "mochi", name: "麻薯", aliases: ["麻薯", "糯米糍"],
                  category: .snack,
                  per100g: .per100g(270, 3.0, 3.5, 58.0, ca: 25, fe: 0.6, fb: 1.0),
                  portions: [.piece: 25], defaultGrams: 50),

        FoodEntry(id: "popcorn", name: "爆米花", aliases: ["爆米花"],
                  category: .snack,
                  per100g: .per100g(400, 8.0, 20.0, 50.0, ca: 20, fe: 1.5, fb: 9.0),
                  portions: [.bag: 60, .cup: 30], defaultGrams: 60)
    ]

    // MARK: - 现制饮品 / 酒水

    static let supplementDrinks: [FoodEntry] = [

        FoodEntry(id: "chagee_boya", name: "伯牙绝弦", aliases: ["霸王茶姬", "伯牙绝弦"],
                  category: .drink,
                  per100g: .per100g(60, 1.0, 2.0, 12.0, ca: 40),
                  portions: [.cup: 500, .bottle: 500], defaultGrams: 500),

        FoodEntry(id: "chagee_shengsheng", name: "声声乌龙", aliases: ["声声乌龙"],
                  category: .drink,
                  per100g: .per100g(45, 0.8, 1.5, 8.0, ca: 45),
                  portions: [.cup: 500, .bottle: 500], defaultGrams: 500),

        FoodEntry(id: "chagee_huatian", name: "花田乌龙", aliases: ["花田乌龙"],
                  category: .drink,
                  per100g: .per100g(50, 0.8, 1.8, 9.0, ca: 40),
                  portions: [.cup: 500, .bottle: 500], defaultGrams: 500),

        FoodEntry(id: "mxbc_lemonade", name: "冰鲜柠檬水", aliases: ["蜜雪冰城", "柠檬水", "冰鲜柠檬水"],
                  category: .drink,
                  per100g: .per100g(40, 0.1, 0, 10.0, ca: 5, vc: 8),
                  portions: [.cup: 500, .bottle: 500], defaultGrams: 500),

        FoodEntry(id: "heytea_grape", name: "多肉葡萄", aliases: ["喜茶", "多肉葡萄"],
                  category: .drink,
                  per100g: .per100g(75, 0.3, 0.2, 18.0, ca: 10, vc: 5),
                  portions: [.cup: 500, .bottle: 500], defaultGrams: 500),

        FoodEntry(id: "naixue_strawberry", name: "霸气草莓", aliases: ["奈雪", "霸气草莓"],
                  category: .drink,
                  per100g: .per100g(80, 0.8, 1.0, 19.0, ca: 25, vc: 20),
                  portions: [.cup: 500, .bottle: 500], defaultGrams: 500),

        FoodEntry(id: "yidiandian_naiqing", name: "四季奶青", aliases: ["一点点", "四季奶青"],
                  category: .drink,
                  per100g: .per100g(90, 1.0, 3.0, 15.0, ca: 45),
                  portions: [.cup: 500, .bottle: 500], defaultGrams: 500),

        FoodEntry(id: "taro_bobo", name: "芋泥波波", aliases: ["芋泥波波", "芋泥"],
                  category: .drink,
                  per100g: .per100g(110, 1.5, 3.5, 20.0, ca: 50, fb: 1.5),
                  portions: [.cup: 500, .bottle: 500], defaultGrams: 500),

        FoodEntry(id: "mango_pomelo_sago", name: "杨枝甘露", aliases: ["杨枝甘露"],
                  category: .drink,
                  per100g: .per100g(130, 1.5, 3.5, 25.0, ca: 55, vc: 15, fb: 1.2),
                  portions: [.cup: 500, .bowl: 400], defaultGrams: 500),

        FoodEntry(id: "grass_jelly_drink", name: "烧仙草", aliases: ["烧仙草"],
                  category: .drink,
                  per100g: .per100g(120, 1.0, 2.5, 27.0, ca: 40, fb: 1.5),
                  portions: [.cup: 500, .bowl: 400], defaultGrams: 500),

        FoodEntry(id: "fruit_tea", name: "水果茶", aliases: ["水果茶", "果茶"],
                  category: .drink,
                  per100g: .per100g(60, 0.2, 0, 15.0, ca: 8, vc: 18),
                  portions: [.cup: 500, .bottle: 500], defaultGrams: 500),

        FoodEntry(id: "lemon_tea", name: "柠檬茶", aliases: ["柠檬茶", "港式柠檬茶"],
                  category: .drink,
                  per100g: .per100g(50, 0.2, 0, 12.0, ca: 6, vc: 15),
                  portions: [.cup: 500, .bottle: 500], defaultGrams: 500),

        FoodEntry(id: "matcha_latte", name: "抹茶拿铁", aliases: ["抹茶拿铁", "抹茶"],
                  category: .drink,
                  per100g: .per100g(70, 2.5, 3.0, 9.0, ca: 95),
                  portions: [.cup: 350, .bottle: 350], defaultGrams: 350),

        FoodEntry(id: "mocha", name: "摩卡", aliases: ["摩卡", "摩卡咖啡"],
                  category: .drink,
                  per100g: .per100g(70, 3.0, 3.0, 8.0, ca: 95),
                  portions: [.cup: 350], defaultGrams: 350),

        FoodEntry(id: "cappuccino", name: "卡布奇诺", aliases: ["卡布奇诺", "卡布"],
                  category: .drink,
                  per100g: .per100g(60, 3.0, 3.0, 6.0, ca: 100),
                  portions: [.cup: 300], defaultGrams: 300),

        FoodEntry(id: "flat_white", name: "澳白", aliases: ["澳白"],
                  category: .drink,
                  per100g: .per100g(70, 4.0, 4.0, 6.0, ca: 120),
                  portions: [.cup: 250], defaultGrams: 250),

        FoodEntry(id: "cold_brew", name: "冷萃", aliases: ["冷萃", "冷萃咖啡"],
                  category: .drink,
                  per100g: .per100g(5, 0.1, 0, 1.0, ca: 2),
                  portions: [.cup: 350, .bottle: 350], defaultGrams: 350),

        FoodEntry(id: "instant_coffee", name: "速溶咖啡", aliases: ["速溶咖啡", "三合一咖啡", "雀巢"],
                  category: .drink,
                  per100g: .per100g(420, 6.0, 12.0, 70.0, ca: 120),
                  portions: [.bag: 15, .spoon: 12, .cup: 200], defaultGrams: 200),

        FoodEntry(id: "diet_cola", name: "无糖可乐", aliases: ["零度可乐", "无糖可乐", "健怡可乐"],
                  category: .drink,
                  per100g: .per100g(0.5, 0, 0, 0.1),
                  portions: [.cup: 330, .bottle: 330], defaultGrams: 330),

        FoodEntry(id: "sprite", name: "雪碧", aliases: ["雪碧", "柠檬味汽水"],
                  category: .drink,
                  per100g: .per100g(40, 0, 0, 10.0),
                  portions: [.cup: 330, .bottle: 500], defaultGrams: 330),

        FoodEntry(id: "fanta", name: "芬达", aliases: ["芬达"],
                  category: .drink,
                  per100g: .per100g(45, 0, 0, 11.0),
                  portions: [.cup: 330, .bottle: 500], defaultGrams: 330),

        FoodEntry(id: "energy_drink", name: "红牛", aliases: ["红牛", "功能饮料", "能量饮料"],
                  category: .drink,
                  per100g: .per100g(45, 0.2, 0, 11.0, ca: 6),
                  portions: [.bottle: 250, .cup: 250], defaultGrams: 250),

        FoodEntry(id: "vitamin_water", name: "脉动", aliases: ["脉动", "维生素饮料"],
                  category: .drink,
                  per100g: .per100g(22, 0, 0, 5.5, vc: 10),
                  portions: [.bottle: 600, .cup: 300], defaultGrams: 600),

        FoodEntry(id: "electrolyte_drink", name: "宝矿力", aliases: ["宝矿力", "电解质水"],
                  category: .drink,
                  per100g: .per100g(25, 0, 0, 6.0, ca: 8),
                  portions: [.bottle: 500, .cup: 300], defaultGrams: 500),

        FoodEntry(id: "coconut_water", name: "椰子水", aliases: ["椰子水", "椰青"],
                  category: .drink,
                  per100g: .per100g(19, 0.5, 0.1, 4.0, ca: 15),
                  portions: [.bottle: 330, .cup: 300], defaultGrams: 330),

        FoodEntry(id: "sparkling_water", name: "气泡水", aliases: ["气泡水", "苏打水"],
                  category: .drink,
                  per100g: .per100g(0, 0, 0, 0),
                  portions: [.bottle: 500, .cup: 300], defaultGrams: 500),

        FoodEntry(id: "suanmeitang", name: "酸梅汤", aliases: ["酸梅汤"],
                  category: .drink,
                  per100g: .per100g(45, 0.1, 0, 11.0, ca: 8),
                  portions: [.cup: 300, .bottle: 500], defaultGrams: 300),

        FoodEntry(id: "soy_drink", name: "豆奶", aliases: ["豆奶"],
                  category: .drink,
                  per100g: .per100g(60, 3.0, 2.0, 7.0, ca: 25),
                  portions: [.bottle: 250, .cup: 250], defaultGrams: 250),

        FoodEntry(id: "yakult", name: "养乐多", aliases: ["养乐多", "乳酸菌饮料"],
                  category: .drink,
                  per100g: .per100g(70, 1.2, 0.2, 16.0, ca: 30),
                  portions: [.bottle: 100, .cup: 100], defaultGrams: 100),

        FoodEntry(id: "hot_cocoa", name: "热可可", aliases: ["热可可", "可可", "阿华田"],
                  category: .drink,
                  per100g: .per100g(80, 2.0, 2.0, 13.0, ca: 90),
                  portions: [.cup: 300, .spoon: 20], defaultGrams: 300),

        FoodEntry(id: "honey_citron_tea", name: "蜂蜜柚子茶", aliases: ["蜂蜜柚子茶", "柚子茶"],
                  category: .drink,
                  per100g: .per100g(55, 0.2, 0, 14.0, ca: 10, vc: 12),
                  portions: [.cup: 350, .spoon: 20], defaultGrams: 350),

        FoodEntry(id: "chinese_liquor", name: "白酒", aliases: ["白酒", "二锅头"],
                  category: .drink,
                  per100g: .per100g(300, 0, 0, 0),
                  portions: [.cup: 50, .piece: 50], defaultGrams: 50),

        FoodEntry(id: "red_wine", name: "红酒", aliases: ["红酒", "葡萄酒"],
                  category: .drink,
                  per100g: .per100g(85, 0.1, 0, 2.6, ca: 8),
                  portions: [.cup: 150, .bottle: 750], defaultGrams: 150),

        FoodEntry(id: "yellow_wine", name: "黄酒", aliases: ["黄酒", "花雕"],
                  category: .drink,
                  per100g: .per100g(66, 0.5, 0, 3.0, ca: 10),
                  portions: [.cup: 100, .bowl: 150], defaultGrams: 100),

        FoodEntry(id: "sake", name: "清酒", aliases: ["清酒", "日本酒"],
                  category: .drink,
                  per100g: .per100g(100, 0.3, 0, 5.0),
                  portions: [.cup: 100], defaultGrams: 100),

        FoodEntry(id: "whisky", name: "威士忌", aliases: ["威士忌", "洋酒"],
                  category: .drink,
                  per100g: .per100g(250, 0, 0, 0),
                  portions: [.cup: 45], defaultGrams: 45)
    ]
}
