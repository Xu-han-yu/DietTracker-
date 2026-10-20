# DietTracker 测试清单与安装排错（第 7 步）

> 本机是 Windows、无 Xcode：**所有编译与单测都在 GitHub Actions 的 macOS runner 上执行**。
> 本文档分四部分：自动化单测、云端构建排查、真机侧载检查、免费签名 7 天过期处理。

---

## 一、自动化单元测试（已在 CI 中运行）

### 测试文件（`DietTrackerTests/`，共 6 个）

| 文件 | 覆盖内容 | 守护的验收项 |
|---|---|---|
| `ParsingSupportTests.swift` | 中文数字（两/半/十五/二十五）、份量（克/两/大碗/小份/ml）、时长（半小时/一个半小时/一刻钟/1小时30分钟）、分句 | 解析地基 |
| `FoodParsingTests.swift` | **24 组**食物解析用例：精确克数（米饭一碗=150g、三两牛肉=150g、两碗=300g…）、别名命中（地瓜/荷包蛋/泡面/珍珠奶茶…）、混合句、无份量默认兜底、未识别进 unmatched、置信度边界 | 解析 ≥20 条通过率 ≥85%（此处按 100% 断言） |
| `ExerciseParsingAndMETTests.swift` | 运动解析（跑步/快走/力量训练/HIIT/打篮球…）、**「先剔除运动名再判强度」**（快走≠高强度、慢跑≠低强度）、MET 公式 `kcal = MET × kg × h`、**可复现性**（同输入两次结果相等、体重快照冗余）、兜底 MET=5.0 且 `isFallback=true`、时长 999→360 限幅、体重 0→60 兜底 | 运动记录离线可用；消耗估算可复现 |
| `AnalysisEngineTests.swift` | **双通道隔离**（运动 900 kcal/天也不能改写「钙偏低」；通道 A 判定逐项相等；RDI 不随运动回加）、**7 天趋势优先**（单日达标但一周偏低 → 仍偏低；`actual` 展示当日、`assessedValue` 按均值）、不足 3 天回落单日口径、纯函数确定性输出、建议 2–3 条且全过黑名单、免责声明存在、空数据日只给记录类建议 | 分析建议体现运动影响但不抵消微量判定 |
| `NutritionProfileTests.swift` | Mifflin-St Jeor（男/女/未知常数）、减脂 −20% / 增肌 +10%、女性 1200 / 男性 1500 安全下限、铁 12/18、极端输入不产生 NaN、estimatorVersion 记录 | RDI 公式正确 |
| `DatabaseIntegrityTests.swift` | 食物表 ≥50 项（实际 ~90）、运动表 ≥20 种（实际 32）、ID 唯一、MET 三档单调（low ≤ moderate ≤ high）、营养值非负、别名包含规范名、营养查询缩放（米饭 150g → 174 kcal）、未命中静默兜底、API Key 为空即关闭 | 本地表规模与数据质量；离线可用 |

### CI 上怎么跑

`push` / `PR` / 手动触发时，workflow 自动执行两个 job：

1. **Unit tests (iOS Simulator)** — `xcodegen generate` → 硬编码扫描 → `xcodebuild test`（iPhone 16 模拟器，Debug 配置，不签名）。
2. **Build unsigned .ipa** — 与测试并行；如想让「测试不过就不出 IPA」，在 build job 上加一行 `needs: [test]`。

本地（如有 Mac）等价命令：

```bash
xcodegen generate --spec project.yml --project DietTracker.xcodeproj
xcodebuild test \
  -project DietTracker.xcodeproj -scheme DietTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO
```

### 模拟器可测项（由 CI 代替本机执行）

- ✅ 全部单测（上表）
- ✅ 应用能启动不崩溃（单测宿主即 App 本体，启动失败测试会挂）
- ⚠️ 纯 UI 交互（输入→预览→落库→分析按钮）暂无 UI 自动化，靠真机检查单覆盖

### 已知的数据表修复（本轮顺手修掉）

- `hiit` 别名补了规范名 `HIIT`（原只有小写 `hiit`）
- `滑冰轮滑` 别名补了规范名本身
- 这两处由 `DatabaseIntegrityTests` 的「别名必须包含规范名」断言守护

---

## 二、云端构建报错排查表

| 报错关键词 | 原因 | 处理 |
|---|---|---|
| `xcodegen: command not found` | brew 安装失败/超时 | 重跑；或固定 `brew install xcodegen@2.44` |
| `Unable to find a destination matching the provided destination specifier` | runner 镜像没有对应模拟器（如 iPhone 16） | job 里把 `-destination` 的机型改成 `iPhone 17` / `iPhone 15`；先跑 `xcrun simctl list devices available` 打印可用机型 |
| `Testing failed: ... test host application` | App 启动即崩（SwiftData schema / 播种问题） | 看失败日志里的崩溃栈；常见为 `@Model` 无默认值属性 → 对照第 3 步迁移守则 |
| `Signing for "DietTrackerTests" requires a development team` | 测试 target 签名设置被覆盖 | 确认 project.yml 里 DietTrackerTests 的 `CODE_SIGNING_ALLOWED=NO` 仍在 |
| `error: unable to spawn process` / 编译卡住 >20 分钟 | 类型检查器在超大数组字面量上爆炸 | 已按分类拆分子数组规避；新增食物请追加到对应分类数组 |
| `Command CodeSign failed` | 某处又开启了签名 | 检查 workflow 的 5 个签名参数 + project.yml 三件套都没被改 |
| `No profiles, defaults or...` provisioning | 误删 `CODE_SIGNING_ALLOWED=NO` | 恢复 workflow 中 build 步骤的签名参数组 |
| Hardcoded style lint 失败 | 视图里出现了 `Color(...)` / `Font.system(size:)` / `.shadow(` 等字面量 | 改用 `Tokens.*` 与 `dtXxx` 修饰符；例外白名单在 `scripts/check-hardcoded-style.sh` 顶部 |
| `Cannot use staged migration with an unknown model version` | 真机/模拟器有旧 schema 数据 | 开发期直接删 App 重装（无存量用户，无需迁移代码） |

### 云端构建（完整流程）

```
GitHub 仓库（建议 public，macOS runner 分钟数免费额度更高）
→ Actions 手动触发 "Build Unsigned IPA"
→ 等 ~10-15 分钟，两个 job 全绿
→ Artifacts 下载 DietTracker-unsigned-ipa（90 天保留）
```

---

## 三、真机侧载检查单（SideStore）

装好后按顺序过一遍，全部 ✅ 才算通过验收：

### 启动与基础

- [ ] App 图标正常显示（石墨底 + 冷蓝环），启动不白屏不闪退
- [ ] 首次启动自动创建 7 个默认时段与默认档案（设置页可见）
- [ ] **飞行模式下**完成：记一餐 → 分析 → 看趋势（离线可用验收项）

### 饮食记录链路

- [ ] 输入「米饭一碗、番茄炒蛋和一杯牛奶」→ 解析预览出 3 项，克数可手动改
- [ ] 输入「三两牛肉」→ 150g；「两碗米饭」→ 300g
- [ ] 输入词典外食物（如「烧烤」）→ 进未识别区，提示手动处理，不崩溃
- [ ] 每条记录带「估算」标注；分析卡带免责声明

### 运动链路

- [ ] 输入「快走1小时」→ 强度默认中等（不是高强度）
- [ ] 输入「跑步30分钟」→ 消耗 = MET 11.0 × 体重 × 0.5h，公式在卡片上可见
- [ ] 改体重后，**历史记录的消耗数字不变**（可复现性验收项）
- [ ] 未匹配运动（如「舞蹈操30分钟」）→ 显示「按中等强度一般运动估算」

### 分析与趋势（核心验收）

- [ ] 今日摘要显示**摄入 / 消耗 / 净摄入**三个数
- [ ] 分析卡分两段：能量与宏量 + 微量营养素，中间有隔离说明文案
- [ ] 趋势页有**摄入 / 消耗 / 净摄入三条曲线**（7 天与 30 天可切）
- [ ] 大量运动日，「钙偏低」等微量状态**不变绿**（双通道隔离）
- [ ] 记录不足 3 天时，建议是「继续记录」类，不下营养结论
- [ ] 建议文案里**搜不到**「可以多吃 / 补回来 / 奖励自己 / 抵消」等词

### 主题

- [ ] 深色模式下背景非纯黑、文字清晰（#101114 / #EDEEF2）
- [ ] 系统字体调到最大档，首页 hero 数字不截断、布局不崩
- [ ] 数字变化时宽度不跳动（等宽数字生效）

### 数据

- [ ] 设置页改 RDI 参数（年龄/体重/目标）→ 推荐量实时刷新
- [ ] 设置页导出 JSON → 分享面板能弹出（iPhone 上正常；iPad 需 sourceView，已处理）
- [ ] 删除 App 重装 → 数据清空、默认时段重建（预期行为）

---

## 四、免费签名 7 天过期处理

| 场景 | 处理 |
|---|---|
| 日常防过期 | iPhone 上**保持 SideStore 的 StosVPN 开启**（设置 → VPN），SideStore 会在到期前自动刷新 |
| 已经过期（点图标闪退） | 打开 SideStore → Apps → DietTracker → **Refresh**；失败就开 StosVPN 再 Refresh |
| Refresh 反复失败 | 用当初的 IPA 重装（SideStore 的 `+` → 选 ipa → 安装）。**Bundle ID 不变就是覆盖安装，数据不丢** |
| 千万别做 | **先删除再安装** —— 卸载会连 SwiftData 本地库一起清掉，饮食历史全没 |
| 免费账号限额 | 最多 3 个侧载 App / 每周 10 个新 App ID / 证书 7 天；DietTracker 常驻占 1 个名额 |
| 每周动作 | 建议固定每周日 Refresh 一次（7 天周期内刷新即可） |
| Plan B（iOS 26 收紧侧载时） | 改用 **LiveContainer**：只签一次容器 App，把未签名 IPA 塞进去跑，免 7 天续签；见 `docs/BUILD.md` |

### 数据安全提醒

侧载续签 / 重装**理论上**不碰数据，但免费证书链路偶发异常。建议：

- 重要记录前先在设置页**导出 JSON** 备份
- 升级 IPA 前也导出一次
- 导出文件在「文件」App 的 `On My iPhone/DietTracker` 下可找到

---

## 五、验收标准对照（23 条）

| # | 验收项 | 状态 |
|---|---|---|
| 1 | 云端 xcodebuild 编译通过 | ⏳ 首次 push 后验证 |
| 2 | 无缺失类型 / 未定义符号 | ⏳ 同上（单测编译也是一道闸） |
| 3 | 飞行模式可记录 + 分析 | ✅ 代码层全本地；真机检查单覆盖 |
| 4 | 本地食物表 ≥50 项 | ✅ ~90 项 + 单测守护 |
| 5 | 运动表 ≥20 种 × 3 强度 | ✅ 32 种 + 单测守护 |
| 6 | 解析测试 ≥20 条 ≥85% | ✅ 24 条按 100% 断言 |
| 7 | 消耗估算可复现 | ✅ `testReproducible` + 体重快照断言 |
| 8 | 建议含中文 + 免责声明 | ✅ 单测断言 |
| 9 | SideStore 可侧载启动 | ⏳ 真机检查单 |
| 10 | 极端单日数据不引起结论剧烈波动 | ✅ 趋势均值判定 + 单测 |
| 11 | 空 API Key 纯本地无报错 | ✅ `testExternalAPIDisabledByDefault` |
| 12 | 全新 clone 即可构建 | ✅ XcodeGen 全自动，无本地依赖 |
| 13 | 运动不抵消微量判定 | ✅ `testHugeExerciseDoesNotWashOutMicronutrientDeficiency` |
| 14 | 今日摘要含摄入/消耗/净摄入 | ✅ 代码 + 真机检查单 |
| 15 | 7 日趋势含三条能量曲线 | ✅ TrendView + 真机检查单 |
| 16 | 无补偿性进食文案 | ✅ 黑名单 guard + 单测双向断言（命中必拦、正常不误伤） |
| 17–22 | 主题类（令牌、深色、动态字体、无硬编码、图表规范、对比度） | ✅ CI 扫描 + 代码审查；目视项在真机检查单 |
| 23 | 主题层不改分析逻辑 | ✅ AnalysisEngine 与 Theme 零 import 关系 |

---

## 六、剩余风险（透明披露）

1. **首次云端编译未验证** —— Windows 本机无 Xcode，所有规避（`@unknown default`、元组解构、区间 switch、数组拆分）都是静态审查结论，最终以 CI 为准。首跑失败按第二节排查表处理。
2. **模拟器机型名随 runner 镜像漂移** —— `iPhone 16` 在 macos-15 上可用；若换 macos-26 需同步改 destination。
3. **UI 层无自动化** —— 输入→预览→落库的交互链靠真机检查单，后续可用 XCUITest 补。
