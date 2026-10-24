//
//  KeychainHelper.swift
//  DietTracker
//
//  iOS 钥匙串封装：用于存放用户自己输入的 API Key。
//
//  ⚠️ 硬约束（对应安全验收项）：
//   1. **绝不硬编码 Key** —— 本文件不生产 Key，只负责存用户输入的 Key。
//   2. **不写进 UserDefaults / 源码 / Info.plist** —— Key 只进钥匙串。
//   3. **`:ThisDeviceOnly`** —— `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`
//      保证条目不进 iCloud 备份、不随设备迁移，重装 App 后即失效。
//
//  ⚠️ 为什么不用 keychain-access-groups：那需要 entitlements 文件，
//     而未签名 IPA 没有 entitlements，配了会直接编译失败。
//     默认 access group（App 自己的 Bundle Identifier）不需要任何 entitlements，
//     与本项目「未签名侧载」的构建方式相容。
//
//  ⚠️ 侧载场景提示：SideStore 重新签名时若 Bundle ID 变了，钥匙串条目会读不到。
//     这是 iOS 的行为，不是 bug；UI 上应说明「Key 只存在本机，重装需重新填写」。
//

import Foundation
import Security

enum KeychainHelper {

    /// 钥匙串条目的 account 标识。新增敏感字段时在这里加 case。
    enum Key: String {
        /// 大模型 API Key
        case llmAPIKey = "llm.apiKey"
    }

    /// service 名。与 PRODUCT_BUNDLE_IDENTIFIER 保持一致即可。
    static let serviceName = "com.yourname.diettracker"

    // MARK: 写入

    /// 写入字符串。已存在则先删后写。
    /// - Returns: 是否成功。**失败原因不回传给调用方文案**，避免泄露钥匙串状态细节。
    @discardableResult
    static func setString(_ value: String, forAccount account: Key) -> Bool {
        // 空值按「删除」处理 —— 用户清空输入框时应该真的抹掉 Key，而不是存一个空字符串。
        guard !value.isEmpty else {
            delete(account)
            return true
        }

        guard let data = value.data(using: .utf8) else { return false }
        delete(account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    // MARK: 读取

    static func string(forAccount account: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        // errSecItemNotFound 是正常情况（用户还没填 Key），不是错误。
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8),
              !value.isEmpty else { return nil }

        return value
    }

    // MARK: 删除

    @discardableResult
    static func delete(_ account: Key) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account.rawValue
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
