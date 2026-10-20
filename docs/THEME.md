# DietTracker 主题规范 ·「冷灰数据极简」（Cool Gray Data Minimal）

> 版本 v1.2 · 增量修改
> 定位：首页像一张**干净的数据仪表盘**——数字是主角，颜色只用来表达"够不够"，不让界面替用户紧张。

---

## 0. 三条不可协商的规则

1. **唯一值源**：全项目只有 `DesignTokens.swift` 允许出现颜色 / 尺寸 / 字号的**字面量**。其他任何文件出现 `Color(...)` 的字面量参数、`Font.system(size:)`、裸 `CGFloat` 间距、裸圆角，视为违规。
2. **唯一强调色**：冷蓝（`#2F6FED` / 深色 `#6C9BFF`）是全局**唯一**强调色。状态色必须"去饱和到不抢戏"的程度；禁止引入红黄绿三色灯式的健康配色。
3. **零阴影**：不使用任何投影。层级关系只靠**背景色阶 + 0.5px 细边框**表达。

---

## 1. 文件与职责

| 文件 | 路径 | 职责 | 允许字面量 |
|---|---|---|---|
| `DesignTokens.swift` | `DietTracker/Theme/DesignTokens.swift` | **令牌唯一定义处**：调色板、排版、间距、圆角、边框、图表色板 | ✅ 仅此一处 |
| `Theme.swift` | `DietTracker/Theme/Theme.swift` | `Theme` 结构、`EnvironmentKey` 注入、`View` 扩展修饰符、状态→颜色映射 | ❌ |

### 目录插入点（原第 2 步目录结构新增）

```
DietTracker/
├── Theme/
│   ├── DesignTokens.swift
│   └── Theme.swift
├── Models/
├── Services/
├── Data/
├── Views/
└── Persistence/
```

> `project.yml` **无需改动** —— XcodeGen 按源码目录 glob，新增目录自动纳入编译。

---

## 2. 颜色令牌

### 2.1 背景与表面（自动适配浅 / 深）

| 令牌 | 浅色 | 深色 | 用途 |
|---|---|---|---|
| `bgPrimary` | `#FAFAFC` | `#101114` | 页面底色。**近白非纯白**，深色非纯黑（避免 OLED 拖影） |
| `bgSecondary` | `#F2F3F7` | `#17191D` | 分组底、指标卡底 |
| `surface` | `#FFFFFF` | `#1C1F24` | 卡片 |
| `surfaceMuted` | `#F7F8FB` | `#22262C` | 卡片内嵌块、输入框底 |

### 2.2 文字（石墨黑体系）

| 令牌 | 浅色 | 深色 | 用途 |
|---|---|---|---|
| `textPrimary` | `#1C1E21` | `#EDEEF2` | 标题、数字 |
| `textSecondary` | `#5A6070` | `#A0A6B4` | 正文、指标名 |
| `textTertiary` | `#8A90A0` | `#6E7482` | 单位、说明、免责声明 |

### 2.3 边框（细线）

| 令牌 | 浅色 | 深色 | 宽度 |
|---|---|---|---|
| `separator` | `#E3E5EC` | `#2A2E36` | 0.5px |
| `separatorStrong` | `#D8DBE3` | `#3A3F49` | 1px（仅焦点/选中态） |

### 2.4 强调色（唯一）

| 令牌 | 浅色 | 深色 | 用途 |
|---|---|---|---|
| `accent` | `#2F6FED` | `#6C9BFF` | 进度条、图表主线、主按钮 |
| `accentText` | `#2557C4` | `#93B4FF` | 强调色上的**文字**（保证 ≥4.5:1 对比度） |
| `accentSubtle` | `#E8EFFD` | `#1E2A44` | 强调底、状态胶囊 |

> `accent` 用于**色块/线条**，`accentText` 用于**文字**。两者分开是为了满足 WCAG AA：强调色作背景时对比度足够，但作为小字正文时不够，必须加深一档。

### 2.5 状态色（去饱和，不抢强调色）

| 状态 | 浅色 | 深色 | 语义 |
|---|---|---|---|
| `sufficient` 充足 | `#2F6FED` | `#6C9BFF` | 直接用强调色 —— 达标是"正向" |
| `low` 偏低 | `#6E7B94` | `#8C97AC` | 石板灰蓝 |
| `high` 偏高 | `#A85A4E` | `#C08376` | 去饱和砖红（不用鲜红） |
| `none` 无数据 | `#C9CCD6` | `#4A505C` | 中性灰 |

---

## 3. 排版令牌

### 3.1 字体
- 统一使用 **SF Pro**（`.systemDesign(.default)`），中文自动回落 PingFang SC，无需额外处理。
- **所有数字必须 `.monospacedDigit()`** —— 防止数字变化时宽度跳动，这是仪表盘观感的关键。

### 3.2 字号（全部支持 Dynamic Type）

| 令牌 | 尺寸 | 字重 | 用途 |
|---|---|---|---|
| `numberHero` | 40 | `.semibold` | **净摄入大数字**（首页视觉锚点） |
| `numberLarge` | 28 | `.semibold` | 摄入 / 消耗 / 各营养素主数值 |
| `numberMedium` | 20 | `.semibold` | 卡片内次要数值 |
| `numberSmall` | 16 | `.medium` | 列表数值 |
| `title` | 20 | `.semibold` | 页面标题 |
| `headline` | 17 | `.semibold` | 卡片标题 |
| `body` | 15 | `.regular` | 正文 |
| `subhead` | 14 | `.regular` | 次级说明 |
| `caption` | 13 | `.regular` | 单位、脚注 |
| `overline` | 12 | `.medium` + `0.5` 字距 | 数据标签（如"蛋白质""运动消耗"） |

### 3.3 动态字体实现要点
- 自定义字号需用 `UIFontMetrics(forTextStyle:).scaledFont(for:)` 包装，否则 `Font.system(size:)` **不会**随系统字号缩放。
- `numberHero` 等大数字需设**缩放上限**（`.dynamicTypeSize(...xxxLarge)`），避免超大字号下布局崩坏。
- 固定尺寸元素（进度环直径等）用 `@ScaledMetric` 声明。

---

## 4. 空间与形状令牌

### 4.1 间距（中等信息密度）

| 令牌 | 值 | 用途 |
|---|---|---|
| `xxs` | 4 | 图标与文字间隙 |
| `xs` | 8 | 元素内部小间隙 |
| `sm` | 12 | 卡片内元素间距 |
| `md` | 16 | **卡片内边距（默认）** |
| `lg` | 20 | 卡片之间间距 |
| `xl` | 24 | 分区之间间距 |
| `xxl` | 32 | 页面顶部/底部留白 |

### 4.2 圆角（中等）

| 令牌 | 值 | 用途 |
|---|---|---|
| `sm` | 8 | 按钮、输入框、标签 |
| `md` | 12 | 小卡片、列表项 |
| `lg` | 16 | 标准卡片 |
| `pill` | 999 | 状态胶囊、分段控件 |

### 4.3 边框与阴影

| 令牌 | 值 |
|---|---|
| `hairline` | 0.5 |
| `thin` | 1 |
| `Shadow` | **仅提供 `.none`**。禁止使用其他阴影。 |

---

## 5. 图表令牌（细线 · 低饱和）

| 令牌 | 浅色 | 深色 | 用途 |
|---|---|---|---|
| `chartIntake` | `#2F6FED` | `#6C9BFF` | 饮食摄入曲线 |
| `chartBurn` | `#8FA3C4` | `#7F93B4` | 运动消耗曲线 |
| `chartNet` | `#5B6B85` | `#8D9BB0` | 净摄入曲线 |
| `chartGrid` | `#E3E5EC` | `#2A2E36` | 网格线 |
| `chartProtein` | `#4A79C0` | `#7BA0DE` | 蛋白质 |
| `chartFat` | `#93A2B8` | `#9AA7BC` | 脂肪 |
| `chartCarb` | `#B9C2CF` | `#C3CBD6` | 碳水 |

| 样式令牌 | 值 |
|---|---|
| `lineWidth` | 2 |
| `symbolSize` | 24（点击热区） |
| `pointRadius` | 3（数据点） |
| `gridLineWidth` | 0.5 |
| `gradient` | **禁用**。面积图只允许 8% 透明度的纯色填充 |

---

## 6. 组件级修饰符 API（定义在 `Theme.swift`）

```swift
// 卡片
func dtCard(padding: CGFloat = Tokens.Space.md) -> some View
func dtSurfaceMuted() -> some View

// 页面与分区
func dtScreenBackground() -> some View
func dtSectionHeader(_ title: String, subtitle: String? = nil) -> some View
func dtHairlineDivider() -> some View

// 数字（核心 —— 全部自动 monospacedDigit + 语义色）
func dtNumber(_ style: Tokens.Typography.NumberStyle,
              color: Color = Tokens.Palette.textPrimary) -> some View
func dtMetric(label: String, value: Double, unit: String,
              status: NutrientStatus = .none) -> some View

// 状态
func dtStatusColor(_ status: NutrientStatus) -> Color
func dtStatusChip(_ text: String, status: NutrientStatus) -> some View

// 交互
func dtPrimaryButton() -> some View
func dtSecondaryButton() -> some View

// 无障碍
func dtMaxDynamicType(_ limit: DynamicTypeSize) -> some View
```

---

## 7. 影响清单

### 7.1 当前进度与返工成本

| 项 | 状态 |
|---|---|
| 第 1 步 PRD | ✅ 已完成（v1.1，含运动模块） |
| 第 2–7 步代码 | ⏸ **尚未生成** |
| 返工成本 | **0** —— 主题层作为前置插入，不产生任何已有代码修改 |

### 7.2 交付顺序调整（建议）

| 步骤 | 内容 | 主题相关增量 |
|---|---|---|
| 第 2 步 | 工程与云端构建方案 | 目录结构新增 `Theme/`；`project.yml` 不变 |
| **第 2.5 步（新增）** | **主题层落地** | **`DesignTokens.swift` + `Theme.swift` 完整代码** |
| 第 3 步 | 数据模型与协议 | **不受影响** |
| 第 4 步 | 解析与 MET 表 | **不受影响** |
| 第 5 步 | AnalysisEngine | **不受影响**（明确不改分析逻辑） |
| 第 6 步 | SwiftUI 界面 | 所有视图**只引用令牌**，零硬编码 |
| 第 7 步 | 测试与排错 | + 主题检查项（对比度 / 深色模式 / 动态字体 / 硬编码扫描） |

### 7.3 文件级影响

| 文件 | 状态 | 主题层影响 |
|---|---|---|
| `Theme/DesignTokens.swift` | 新增 | 全部令牌定义 |
| `Theme/Theme.swift` | 新增 | 环境注入 + 修饰符 + 状态映射 |
| `DietTrackerApp.swift` | 修改 | 注入 `.dtTheme(.default)` |
| `Views/TodayView.swift` | 修改 | 引用 `dtCard` / `dtNumber(.hero)` / 图表令牌 |
| `Views/HistoryView.swift` | 修改 | 引用卡片与文字令牌 |
| `Views/TrendView.swift` | 修改 | 三条能量曲线使用 `chartIntake/Burn/Net`，细线低饱和 |
| `Views/SettingsView.swift` | 修改 | 表单基础样式令牌 |
| `Views/ExerciseInputCard.swift` | 修改 | 强度切换控件使用 `accentSubtle` / `pill` |
| `Views/Components/EnergyBalanceCard.swift` | 修改 | 净摄入大数字使用 `numberHero` |
| `scripts/check-hardcoded-style.sh` | 新增 | CI 硬编码扫描 |
| `Models/**`、`Services/**`、`Data/**` | **无改动** | 分析逻辑零触碰 |

---

## 8. 深浅色与动态字体实现方案

### 8.1 动态颜色（不依赖 Asset Catalog）
```swift
extension Color {
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}
```
- 好处：纯代码、Windows 上可直接生成、无需在 Xcode 里手动建色集（符合"不依赖本机 Xcode 手动配置"硬约束）。
- `Color(uiColor:)` 为 iOS 15+，满足 iOS 17 部署目标。

### 8.2 动态字体
```swift
enum Typography {
    static func font(size: CGFloat, weight: Font.Weight, relativeTo style: UIFont.TextStyle) -> Font {
        let f = UIFont.systemFont(ofSize: size, weight: weight.uiKitWeight)
        return Font(UIFontMetrics(forTextStyle: style).scaledFont(for: f))
    }
}
```
- 必须做 `Font.Weight → UIFont.Weight` 映射。
- 大数字模块统一 `.dtMaxDynamicType(.xxxLarge)` 限幅。

---

## 9. 硬编码禁令的落地机制

光靠"约定"守不住禁令，因此加三道闸：

1. **收敛 API**：`Theme.swift` 提供上述修饰符，覆盖 95% 场景，让人"没必要"写硬编码。
2. **CI 静态扫描**：`scripts/check-hardcoded-style.sh` 在 `Views/`、`Services/` 下 grep 以下模式，命中即让构建失败：
   - `Color(red:green:blue:)` / `Color(hex:` / `Color("` 
   - `Font.system(size:` / `.font(.system(size:`
   - `.cornerRadius(<数字>)` / `.padding(<裸数字>)`（白名单：允许 `Tokens.Space.*` / `Tokens.Radius.*`）
   - `.shadow(` （除 `.shadow(.none)`）
   - `.foregroundStyle(Color.` / `.foregroundColor(Color.`
3. **第 7 步新增人工检查项**：对比度、深色模式、动态字体大字号三项目视验证。

---

## 9.5 已落地实现（v1.2 代码）

主题层已在第 2.5 步落地，文件：

| 文件 | 内容 |
|---|---|
| `DietTracker/Theme/DesignTokens.swift` | 全部令牌（唯一含字面量的文件） |
| `DietTracker/Theme/Theme.swift` | `Theme` + Environment + 修饰符 + `DTDivider` / `DTSectionHeader` / `DTStatusChip` / `DTMetric` / `DTDisclaimer` |
| `DietTracker/Models/NutrientStatus.swift` | 判定状态枚举（第 3 步直接复用，不要重复定义） |
| `scripts/check-hardcoded-style.sh` | CI 硬编码扫描，已在 workflow 启用 |

相对本规范的三处实现调整：

1. `dtStatusChip` / `dtMetric` 改为**独立 View 组件**（`DTStatusChip` / `DTMetric`），而非 View 扩展方法 —— 因为它们需要组合多个子视图，写成修饰符会很难用。
2. 状态胶囊的底色与文字**固定**用 `accentSubtle` / `accentText`（保证任何状态下对比度达标），状态本身由左侧 6pt 圆点的颜色表达。
3. 所有字体令牌必须是 **`static var` 计算属性**，不能写 `static let`：缓存成 let 后 `UIFontMetrics` 不会随系统字号变化重算，动态字体就失效了。

## 10. 更新后的验收标准（新增项）

| # | 标准 | 验证方式 |
|---|---|---|
| 17 | 全项目无硬编码颜色 / 字号 / 圆角（Theme 目录除外） | CI 脚本 `check-hardcoded-style.sh` 通过 |
| 18 | 浅色 / 深色模式均可正常显示，无文字不可见 | 模拟器切换外观目视 |
| 19 | 正文文字对比度 ≥ 4.5:1，大字 ≥ 3:1 | 对比度计算脚本 |
| 20 | 开启系统最大字号后首页不截断、不重叠 | 模拟器 Dynamic Type XXL 目视 |
| 21 | 数字全部使用等宽数字，刷新时不跳动 | 目视 + `.monospacedDigit()` 覆盖检查 |
| 22 | 图表为细线（2px）+ 低饱和色，无渐变填充 | 目视 |
| 23 | 主题层不修改任何分析逻辑，`AnalysisEngine` 输出与 v1.1 一致 | 分析单测全部保持通过 |
