//
//  LLMSettingsSection.swift
//  DietTracker
//
//  设置页的「联网智能分析」区块：开关 / 服务地址 / 模型名 / API Key / 连接测试。
//
//  ⚠️ 隐私承诺必须写在 UI 上、且不能说含糊：
//    - API Key 只存在本机钥匙串，不进 iCloud 备份、不随备份导出。
//    - 每次请求只发送「食物名称 + 份量描述」，不发送体重、年龄、身份或设备信息。
//    - 开关默认关闭。关掉或删掉 Key，App 立即回到纯离线。
//
//  UI 文案在这里是「安全约束的一部分」：用户必须能一眼看懂数据在往外发什么。
//

import SwiftUI

struct LLMSettingsSection: View {

    @State private var config: LLMConfiguration = LLMSettingsStore.load()
    @State private var keyInput: String = ""
    @State private var hasStoredKey: Bool = false
    @State private var testState: TestState = .idle
    @State private var isTesting: Bool = false

    private enum TestState {
        case idle
        case success(String)
        case failure(String)

        var message: String? {
            switch self {
            case .idle:                 return nil
            case .success(let m):       return m
            case .failure(let m):       return m
            }
        }

        var isOK: Bool {
            if case .success = self { return true }
            return false
        }
    }

    var body: some View {
        Section {
            Toggle(isOn: $config.isEnabled) {
                Text("联网智能分析")
                    .font(Tokens.Typography.body)
            }
            .tint(Tokens.Palette.accent)
            .listRowBackground(Tokens.Palette.surface)
            .onChange(of: config.isEnabled) { _, _ in save() }

            if config.isEnabled {
                urlRow
                modelRow
                keyRow
                testRow
            }

            statusRow
        } header: {
            Text("大模型（可选）")
                .font(Tokens.Typography.caption)
                .foregroundStyle(Tokens.Palette.textSecondary)
        } footer: {
            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                Text("本地食物表没命中时，才会用大模型估算一次。本地表永远优先。")
                Text("每次请求只发送「食物名称 + 份量描述」，不发送体重、年龄、性别、设备或任何身份信息。")
                Text("API Key 存放在本机钥匙串（不进 iCloud 备份）。重装 App 或改 Bundle ID 会丢失，需要重新填写。")
                Text("强制 HTTPS；未填 Key、开关关闭或网络不通时，自动回退到本地估算。")
            }
            .font(Tokens.Typography.caption)
            .foregroundStyle(Tokens.Palette.textTertiary)
        }
        .onAppear(perform: loadKeyState)
    }

    // MARK: 子行

    private var urlRow: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
            Text("服务地址（必须 https://）")
                .font(Tokens.Typography.caption)
                .foregroundStyle(Tokens.Palette.textSecondary)
            TextField("https://api.deepseek.com", text: $config.baseURL)
                .font(Tokens.Typography.body)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit { save() }
                .onChange(of: config.baseURL) { _, _ in save() }
        }
        .listRowBackground(Tokens.Palette.surface)
    }

    private var modelRow: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
            Text("模型名称")
                .font(Tokens.Typography.caption)
                .foregroundStyle(Tokens.Palette.textSecondary)
            TextField("deepseek-chat", text: $config.model)
                .font(Tokens.Typography.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit { save() }
                .onChange(of: config.model) { _, _ in save() }
        }
        .listRowBackground(Tokens.Palette.surface)
    }

    private var keyRow: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
            HStack(spacing: Tokens.Space.xs) {
                Text("API Key")
                    .font(Tokens.Typography.caption)
                    .foregroundStyle(Tokens.Palette.textSecondary)
                Spacer(minLength: Tokens.Space.xxs)
                Text(hasStoredKey ? "已保存" : "未设置")
                    .font(Tokens.Typography.overline)
                    .foregroundStyle(hasStoredKey ? Tokens.Palette.accentText : Tokens.Palette.textTertiary)
            }

            SecureField("粘贴你的 API Key", text: $keyInput)
                .font(Tokens.Typography.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit { saveKey() }
                .onChange(of: keyInput) { _, _ in saveKey() }

            if hasStoredKey {
                Button(role: .destructive) {
                    clearKey()
                } label: {
                    Text("删除已保存的 Key")
                        .font(Tokens.Typography.caption)
                }
            }
        }
        .listRowBackground(Tokens.Palette.surface)
    }

    private var testRow: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            Button {
                runTest()
            } label: {
                Text(isTesting ? "测试中…" : "测试连接")
                    .font(Tokens.Typography.body)
                    .foregroundStyle(Tokens.Palette.accentText)
            }
            .disabled(isTesting || LLMSettingsStore.loadAPIKey().isEmpty)

            if let message = testState.message {
                Text(message)
                    .font(Tokens.Typography.caption)
                    .foregroundStyle(testState.isOK ? Tokens.Palette.accentText : Tokens.Palette.textSecondary)
            }
        }
        .listRowBackground(Tokens.Palette.surface)
    }

    private var statusRow: some View {
        HStack(spacing: Tokens.Space.xs) {
            Text("当前模式")
                .font(Tokens.Typography.body)
            Spacer(minLength: Tokens.Space.xs)
            Text(currentModeText)
                .font(Tokens.Typography.caption)
                .foregroundStyle(Tokens.Palette.textTertiary)
        }
        .listRowBackground(Tokens.Palette.surface)
    }

    // MARK: 逻辑

    private var currentModeText: String {
        let service = OpenAICompatibleNutritionLLMService()
        return service.isAvailable ? "本地表 + 大模型兜底" : "离线估算模式"
    }

    private func loadKeyState() {
        hasStoredKey = !LLMSettingsStore.loadAPIKey().isEmpty
    }

    private func save() {
        LLMSettingsStore.save(config)
        testState = .idle
    }

    /// Key 单独写钥匙串，**不写 UserDefaults**。
    private func saveKey() {
        let trimmed = keyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = LLMSettingsStore.saveAPIKey(trimmed)
        hasStoredKey = true
        testState = .idle
    }

    private func clearKey() {
        LLMSettingsStore.deleteAPIKey()
        keyInput = ""
        hasStoredKey = false
        testState = .idle
    }

    private func runTest() {
        isTesting = true
        Task {
            defer { isTesting = false }
            let service = OpenAICompatibleNutritionLLMService()
            do {
                let result = try await service.estimate(name: "白米饭", quantityText: "一碗")
                testState = .success("连接成功 · 测试样本返回 \(AnalysisFormat.kcal(result.kcal)) kcal")
            } catch {
                testState = .failure("连接失败：\(error.localizedDescription)。本地估算不受影响。")
            }
        }
    }
}

#Preview("联网设置区块") {
    Form { LLMSettingsSection() }
        .scrollContentBackground(.hidden)
        .dtScreenBackground()
        .dtTheme(.default)
}
