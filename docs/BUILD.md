# DietTracker 云端构建与侧载指南（第 2 步交付）

> 环境前提：Windows，无 Mac。所有构建在 GitHub Actions 的 macOS runner 上完成，本机只负责编辑与推送。
> 最终产物：**未签名 `DietTracker-unsigned.ipa`**，用 SideStore / LiveContainer 侧载到 iPhone 17（iOS 26）。

---

## 1. 最终目录结构

```
E:\DietTracker\
├── .github/
│   └── workflows/
│       └── build-unsigned-ipa.yml        # 云端构建：xcodegen → xcodebuild → zip → 未签名 IPA
├── DietTracker/                          # App 源码根（XcodeGen 按目录 glob，新增文件自动纳入）
│   ├── App/
│   │   ├── DietTrackerApp.swift          # @main 入口，注入主题与 ModelContainer
│   │   └── AppDependencies.swift         # 服务装配（解析 / 查询 / 分析）
│   ├── Theme/
│   │   ├── DesignTokens.swift            # 唯一允许出现样式字面量的文件
│   │   └── Theme.swift                   # Environment 注入 + View 修饰符 + 状态→颜色
│   ├── Models/
│   │   ├── MealSlotConfig.swift          # 可配置进食时段
│   │   ├── MealEntry.swift               # 一条饮食记录
│   │   ├── FoodItem.swift                # 解析后的食物 + 营养快照
│   │   ├── ExerciseIntensity.swift       # 低 / 中 / 高
│   │   ├── ExerciseEntry.swift           # 一条运动记录
│   │   ├── ExerciseItem.swift            # 解析后的运动 + MET 快照
│   │   ├── WaterEntry.swift
│   │   ├── SupplementEntry.swift
│   │   ├── BodyMetricEntry.swift
│   │   ├── UserProfile.swift
│   │   ├── NutritionProfile.swift        # 每日推荐摄入量 RDI
│   │   ├── DailyIntake.swift             # 某日饮食聚合（不持久化）
│   │   ├── DailyEnergyBalance.swift      # 摄入 / 消耗 / 净摄入（不持久化）
│   │   └── DailyAnalysis.swift           # 分析结论 + 中文建议
│   ├── Services/
│   │   ├── Protocols/
│   │   │   ├── FoodParsingService.swift
│   │   │   ├── NutritionLookupService.swift
│   │   │   ├── ExerciseParsingService.swift
│   │   │   └── ExerciseCalorieService.swift
│   │   ├── LocalFoodParsingService.swift
│   │   ├── LocalNutritionLookupService.swift
│   │   ├── LocalExerciseParsingService.swift
│   │   ├── METExerciseCalorieService.swift
│   │   ├── RemoteNutritionAPIClient.swift     # 可选增强，超时 3s 静默回退
│   │   └── AnalysisEngine.swift               # 双通道分析（微量 | 能量/宏量）
│   ├── Data/
│   │   ├── FoodDatabase.swift            # ≥50 种中式食物营养表
│   │   └── ExerciseDatabase.swift        # ≥20 种运动 × 3 强度 MET 表
│   ├── Persistence/
│   │   └── ModelContainerFactory.swift   # SwiftData 容器，禁用 CloudKit
│   ├── Views/
│   │   ├── TodayView.swift
│   │   ├── HistoryView.swift
│   │   ├── TrendView.swift
│   │   ├── SettingsView.swift
│   │   └── Components/
│   │       ├── ExerciseInputCard.swift
│   │       ├── EnergyBalanceCard.swift
│   │       ├── NutrientProgressRow.swift
│   │       ├── StatusChip.swift
│   │       └── DisclaimerView.swift
│   └── Resources/
│       ├── Info.plist                    # 含 API Key 占位符（留空 = 关闭外部 API）
│       └── Assets.xcassets/
│           ├── AppIcon.appiconset/icon-1024.png
│           └── AccentColor.colorset
├── DietTrackerTests/                     # 第 7 步填充测试
├── scripts/
│   └── check-hardcoded-style.sh          # 第 2.5 步主题层落地后启用
├── docs/
│   ├── PRD.md
│   ├── THEME.md
│   ├── DECISIONS.md
│   └── BUILD.md                          # 本文件
├── project.yml                           # XcodeGen 工程定义
└── .gitignore
```

---

## 2. 方案 A：自建 GitHub Actions（**推荐，已就位**）

这是主推方案，不依赖任何第三方工具，完全可控。配置已写好：`E:\DietTracker\.github\workflows\build-unsigned-ipa.yml`。

### 2.1 构建流水线做了什么

```
push / PR / 手动触发
   │
   ▼
macos-15 runner（Xcode 16.x，可切 macos-26）
   │
   ├─ 1. 打印工具链版本（xcodebuild -version）          → 排错时定位 Xcode 版本漂移
   ├─ 2. brew install xcodegen
   ├─ 3. xcodegen generate --spec project.yml           → 生成 DietTracker.xcodeproj
   ├─ 4. （第 2.5 步启用）硬编码样式扫描                  → 违反"零硬编码"直接失败
   ├─ 5. xcodebuild clean build                          → 未签名 .app
   │        CODE_SIGNING_ALLOWED=NO
   │        CODE_SIGNING_REQUIRED=NO
   │        CODE_SIGN_IDENTITY=""  PROVISIONING_PROFILE=""
   ├─ 6. 打包 Payload/DietTracker.app → DietTracker-unsigned.ipa
   └─ 7. 上传 Artifacts（90 天保留）
```

### 2.2 触发方式

| 方式 | 何时 |
|---|---|
| 推送到 `main` | 自动构建 |
| 开 PR 到 `main` | 自动构建（验证编译不破坏） |
| 发布 Release | 自动构建并把 IPA 挂到 Release 资产 |
| **手动** | Actions 页面 → 「Build Unsigned IPA」→ Run workflow |

### 2.3 产物在哪

Actions 运行完成后 → 该次 run 页面底部 **Artifacts** → 下载 `DietTracker-unsigned-ipa`（zip 内含 `DietTracker-unsigned.ipa`）。

### 2.4 改 Bundle ID

**一键改名（推荐）**：手动触发 workflow 时在 `bundle_id` 输入框填新值。

**永久改名**：改 `project.yml` 两处（`options.bundleIdPrefix` 和 `settings.base.PRODUCT_BUNDLE_IDENTIFIER`）。

> 注意：Bundle ID 一旦侧载到设备并被 SideStore 重新签名，**再改会变成"新 App"**，旧数据不会自动迁移。侧载前定好就不要轻易改。

---

## 3. 首次推送到 GitHub（Windows 本机操作）

在 `E:\DietTracker` 目录下，用 Git Bash 或 PowerShell：

```bash
git init -b main
git add .
git commit -m "chore: initial DietTracker scaffold (XcodeGen + unsigned CI)"
```

在 GitHub 建一个**空仓库**（不要勾 README / .gitignore / license，避免冲突），命名如 `DietTracker`。**建议 public**（macOS runner 分钟数更充裕；private 会消耗免费配额 2000 分钟/月）。

然后关联并推送：

```bash
git remote add origin https://github.com/<你的用户名>/DietTracker.git
git push -u origin main
```

推送后第一次构建自动触发。在仓库 **Actions** 标签页看日志。

> ⚠️ 如果 Actions 页面提示 "Workflows are disabled for forks" 或 "scheduled workflows disabled"，点一下 "Enable" 即可。

---

## 4. 方案 B：ios-builder 第三方工具（备选）

### 4.1 ⚠️ 先说明一个关键事实

你提到的 **`SideStore/ios-builder` 仓库目前已返回 404**，可能已迁移、更名或转为私有。**不要把构建流程寄托在这个地址上**。下面是两个**当前可用**的替代。

### 4.2 替代对比

| 工具 | 适用 | 是否支持原生 Swift | 特点 |
|---|---|---|---|
| **自建 workflow（方案 A）** | 全部 | ✅ | 完全可控，无第三方依赖，**推荐** |
| `MobAI-App/ios-builder`（Builder CLI） | 全部 | ✅ | 命令行工具，`builder init` 自动在你的仓库注入 workflow；支持未签名（`--unsigned`） |
| `adro0303/ipa-builder` | **仅 Expo / React Native** | ❌ | 面向 JS 项目，不适合原生 SwiftUI |

### 4.3 如果坚持用 MobAI Builder CLI

```bash
# 1. 安装（Windows）：从 Releases 下载 builder.exe 加入 PATH
#    https://github.com/MobAI-App/ios-builder/releases

# 2. 认证 GitHub
builder auth github

# 3. 在 E:\DietTracker 目录下初始化（会注入它自己的 workflow）
builder init

# 4. 构建未签名 IPA
builder ios build --unsigned
```

> 它的 `builder init` 会生成**另一套** `.github/workflows/ios-build.yml`。为避免与我们自建的 workflow 冲突，二选一：**用了 Builder CLI 就删掉 `build-unsigned-ipa.yml`，反之删掉 `ios-build.yml`**。两者同时存在会导致双倍构建。

### 4.4 建议

**坚持方案 A**。方案 A 的 workflow 就是 GitHub 官方 macOS runner + 标准 `xcodebuild`，没有任何黑箱，报错容易定位，也不受第三方仓库下线影响。

---

## 5. SideStore 侧载步骤

### 5.1 首次安装（需要 Windows 电脑 + iPhone，一次性）

1. **装 SideServer（或 Sideloadly）** 到 Windows 电脑：
   - SideServer：https://sidestore.io/#get-started （或 GitHub `SideStore/SideServer`）
2. **iPhone 与电脑连同一 Wi-Fi**（或用数据线）。
3. 用 SideServer/Sideloadly **把 SideStore IPA 安装到 iPhone**（登录你的 Apple ID，**免费账号即可**）。
4. **打开 SideStore**，按提示完成：
   - 启用 **StosVPN**（本地 VPN，用于无线刷新签名，不翻墙）。
   - 若要求配对文件（pairing file），用 SideServer 生成并导入。
5. 进入 iPhone **设置 → 通用 → VPN 与设备管理**，信任你的 Apple ID 开发者证书。

### 5.2 日常侧载 DietTracker

1. 从 GitHub Actions 下载 `DietTracker-unsigned-ipa`（zip），解压得到 `DietTracker-unsigned.ipa`。
2. 把 IPA 传到 iPhone（通过「文件」App / 微信文件 / iCloud Drive / 数据线）。
3. 打开 **SideStore → My Apps → 左上角 +** → 选 IPA。
4. SideStore 用你的免费 Apple ID **重新签名并安装**。
5. 回到桌面打开 DietTracker。

> **未签名 IPA 也能侧载**：SideStore 会在安装时用自己的证书重新签名，不需要你提供证书。

---

## 6. 7 天续签（免费 Apple ID 限制）

免费账号的签名证书 **7 天后过期**，过期后 App 点不开。三种处理：

| 方式 | 操作 | 说明 |
|---|---|---|
| **后台自动刷新（推荐）** | 保持 **StosVPN 常开** + 同一 Wi-Fi，SideStore 会在后台自动刷新 | 最省心，几乎无感 |
| 手动刷新 | 打开 SideStore → My Apps → **Refresh All** | 过期前后随时可做 |
| 过期重装 | App 已灰：用 SideStore **重新安装同一个 IPA** | **不要先删 App**——只要 Bundle ID 不变，重新安装会**保留** Documents 里的数据 |

> ⚠️ **先删再装 = 数据全丢**。只要 Bundle ID 不变，直接覆盖安装即可续期。

### 免费账号限额
- 同一 Apple ID 最多 **3 个**侧载 App。
- 每周最多创建 **10 个 App ID**。
- 证书 **7 天**有效期。

---

## 7. 常见构建报错排查表

| 报错 | 原因 | 解法 |
|---|---|---|
| `xcodegen: command not found` | runner 未装 XcodeGen | workflow 已有 `brew install xcodegen`；确认该步在 generate 之前 |
| `Source path "..." does not exist` | project.yml 里 `sources.path` 指向的目录不存在 | 确认 `DietTracker/` 和 `DietTrackerTests/` 都在仓库里（`.gitignore` 没误伤） |
| `Unable to find a destination matching the provided destination specifier` | runner 上没有对应 SDK/模拟器 | 设备构建用 `-destination 'generic/platform=iOS'`；别写死具体设备名 |
| `Code signing is required for product type 'Application'` | 某个配置仍要求签名 | 确认 `CODE_SIGNING_ALLOWED=NO` `CODE_SIGNING_REQUIRED=NO` `CODE_SIGN_IDENTITY=""` 三件套都在 xcodebuild 命令里 |
| `requires a development team` | 残留的签名设置 | 在命令里补 `DEVELOPMENT_TEAM=""` `PROVISIONING_PROFILE=""`（已在 workflow 中） |
| `None of the input catalogs contained a matching app icon set` | 设了 `ASSETCATALOG_COMPILER_APPICON_NAME` 但没有该图标集 | 已提供 `Assets.xcassets/AppIcon.appiconset`；若删掉了就同时删掉该 build setting |
| `error: Sandbox: ... deny` | 脚本沙箱 | workflow 里没有自定义 run script，一般不会出现 |
| `Command SwiftCompile failed` / 一堆 Swift 错误 | 代码本身编译错误 | 看日志里第一个 `error:`，多数是类型缺失/导入遗漏 |
| `AttributeGraph` / `GraphContact` 崩溃（运行时） | SwiftUI 状态循环 | 与构建无关，属运行时问题，第 7 步排查 |
| 产物里没有 `.app` | derivedData 路径对不上 | workflow 用 `-derivedDataPath build/DerivedData`，路径固定 |
| IPA 里残留 `_CodeSignature` | 构建时仍签了名 | 打包步骤已 `rm -rf _CodeSignature`；确认签名三件套生效 |
| iOS 26 上装不上 | 系统收紧侧载策略 | 走 **LiveContainer**（见下） |

---

## 8. 未签名 IPA 的限制（重要）

未签名 IPA **没有 entitlements**，以下能力一律**不可用**，MVP 已全部规避：

- ❌ CloudKit（SwiftData 已用 `cloudKitDatabase: .none`）
- ❌ App Groups、Keychain Sharing
- ❌ 推送通知（APNs）
- ❌ HealthKit / GPS 后台定位（MVP 本来就不用）

> 所以项目里**不要**添加任何 `.entitlements` 文件，也不要在代码里调用这些能力，否则侧载安装时会报 "ApplicationVerificationFailed"。

---

## 9. Plan B：LiveContainer（iOS 26 收紧侧载时）

如果 iOS 26 对 SideStore 直接安装收紧，改用 **LiveContainer**：

1. 用 SideStore 侧载 **LiveContainer**（它本身是一个签名 App，只需签名一次）。
2. 在 LiveContainer 里 `+` 添加 **未签名的 `DietTracker-unsigned.ipa`**。
3. LiveContainer 在容器内直接运行未签名 App，**不需要逐个重新签名**。

优点：只有 LiveContainer 本体受 7 天限制，里面的 App 不受限；也不占 3-App 名额。
注意：少数依赖特殊权限的 App 可能有兼容问题，DietTracker 是纯本地 App，兼容性好。

---

## 10. 本步交付物清单

| 文件 | 说明 |
|---|---|
| `project.yml` | XcodeGen 工程定义，含未签名构建设置 |
| `.github/workflows/build-unsigned-ipa.yml` | 完整云端构建 workflow |
| `DietTracker/Resources/Info.plist` | 含 API Key 占位符 |
| `DietTracker/Resources/Assets.xcassets/` | App Icon + 强调色 |
| `.gitignore` | 忽略生成物与产物 |
| `docs/BUILD.md` | 本指南 |
