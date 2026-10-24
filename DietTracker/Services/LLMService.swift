//
//  LLMService.swift
//  DietTracker
//
//  2.0 联网能力：**本地表没命中时**，调用用户自己配置的大模型做一次营养估算。
//
//  ⚠️ 安全与隐私硬约束（逐条对应，不要削弱）：
//   1. **Key 绝不硬编码** —— 只从钥匙串读（KeychainHelper），源码里不出现任何 Key。
//   2. **强制 HTTPS** —— scheme 必须是 https；URLSession 使用重定向代理，
//      任何跳向 http（或其他 scheme）的重定向都会被直接掐断。
//   3. **请求脱敏** —— Prompt 白名单只允许「食物名称 + 份量描述」两个字段，
//      禁止附带设备信息、机型、坐标系、广告标识、Apple ID、健康数据。
//   4. **默认关闭** —— 装好就是纯离线；用户显式打开开关并填 Key 才会联网。
//   5. **优雅降级** —— 未填 Key / 断网 / 超时 / 返回格式不对，一律回退本地字典，
//      并在 UI 提示「当前处于离线估算模式」。**绝不让网络错误打断记录流程**。
//
//  为什么要 LOCAL FIRST：本地表是离线、可复现、零延迟的主路径。
//  大模型只用来补本地表的盲区，不是替代品 —— 所以调用顺序永远是本地先命中。
//

import Foundation

// MARK: - 配置

/// 大模型配置。**API Key 不在这个结构体里持久化**，只在使用时从钥匙串现读。
struct LLMConfiguration: Sendable {
    /// 总开关。默认 false —— 装好就是纯离线。
    var isEnabled: Bool
    var baseURL: String
    var model: String

    static let `default` = LLMConfiguration(
        isEnabled: false,
        baseURL: "https://api.deepseek.com",
        model: "deepseek-chat"
    )
}

/// 配置存取。开关 / URL / 模型名放 UserDefaults（非敏感），**API Key 走钥匙串**。
enum LLMSettingsStore {

    private enum Defaults {
        static let enabled = "llm.enabled"
        static let baseURL = "llm.baseURL"
        static let model   = "llm.model"
    }

    static func load() -> LLMConfiguration {
        let ud = UserDefaults.standard
        return LLMConfiguration(
            isEnabled: ud.bool(forKey: Defaults.enabled),
            baseURL: ud.string(forKey: Defaults.baseURL) ?? LLMConfiguration.default.baseURL,
            model: ud.string(forKey: Defaults.model) ?? LLMConfiguration.default.model
        )
    }

    /// 保存配置。**注意入参不含 Key** —— Key 单独用 `saveAPIKey(_:)` 写钥匙串。
    static func save(_ config: LLMConfiguration) {
        let ud = UserDefaults.standard
        ud.set(config.isEnabled, forKey: Defaults.enabled)
        ud.set(config.baseURL, forKey: Defaults.baseURL)
        ud.set(config.model, forKey: Defaults.model)
    }

    static func loadAPIKey() -> String {
        KeychainHelper.string(forAccount: .llmAPIKey) ?? ""
    }

    @discardableResult
    static func saveAPIKey(_ key: String) -> Bool {
        KeychainHelper.setString(key, forAccount: .llmAPIKey)
    }

    static func deleteAPIKey() {
        KeychainHelper.delete(.llmAPIKey)
    }
}

// MARK: - 结果模型

/// 大模型给出的一份营养估算。**全部字段都经过限幅**，见 `clamped`。
struct LLMNutritionEstimate: Sendable, Equatable {
    /// 模型假设的食物重量（g）。用于 UI 展示「按多少克算的」。
    var assumedGrams: Double
    var kcal: Double
    var proteinG: Double
    var fatG: Double
    var carbsG: Double
    var calciumMG: Double
    var ironMG: Double
    var vitaminCMG: Double
    var fiberG: Double
}

// MARK: - 错误

enum LLMError: LocalizedError {
    /// 用户没开开关
    case disabled
    case missingKey
    case insecureURL(String)
    case transport(String)
    case badStatus(Int)
    case emptyContent
    case undecodable

    var errorDescription: String? {
        switch self {
        case .disabled:            return "未启用联网分析"
        case .missingKey:          return "未填写 API Key"
        case .insecureURL(let u):  return "只允许 HTTPS 地址，当前配置：\(u)"
        case .transport(let m):    return "网络请求失败：\(m)"
        case .badStatus(let c):    return "服务返回状态码 \(c)"
        case .emptyContent:        return "服务没有返回内容"
        case .undecodable:         return "服务返回的内容无法解析"
        }
    }
}

// MARK: - 协议

protocol NutritionLLMService: Sendable {
    /// 是否已可用（开开关 + 有 Key + 地址合法）。UI 用它决定要不要走联网分支。
    var isAvailable: Bool { get }
    /// 估算一份食物的营养。**失败一律 throw**，调用方负责回退本地。
    func estimate(name: String, quantityText: String?) async throws -> LLMNutritionEstimate
}

/// 兜底实现：永远不可用。测试或纯离线构建使用。
struct DisabledNutritionLLMService: NutritionLLMService {
    var isAvailable: Bool { false }
    func estimate(name: String, quantityText: String?) async throws -> LLMNutritionEstimate {
        throw LLMError.disabled
    }
}

// MARK: - OpenAI / DeepSeek 兼容实现

/// 兼容 OpenAI Chat Completions 协议的实现（DeepSeek / 通义 / Moonshot 等均兼容该协议）。
///
/// 配置在**每次调用时现读**（而不是构造时快照），
/// 这样用户在设置页改完开关或 Key，下一次识别立即生效，不用重启 App。
struct OpenAICompatibleNutritionLLMService: NutritionLLMService {

    var isAvailable: Bool {
        let config = LLMSettingsStore.load()
        guard config.isEnabled, !LLMSettingsStore.loadAPIKey().isEmpty else { return false }
        guard let scheme = URLComponents(string: config.baseURL)?.scheme?.lowercased() else { return false }
        return scheme == "https"
    }

    func estimate(name: String, quantityText: String?) async throws -> LLMNutritionEstimate {
        let config = LLMSettingsStore.load()
        guard config.isEnabled else { throw LLMError.disabled }

        let apiKey = LLMSettingsStore.loadAPIKey()
        guard !apiKey.isEmpty else { throw LLMError.missingKey }

        let url = try makeEndpointURL(baseURL: config.baseURL)
        let payload = try makeRequestPayload(model: config.model,
                                            name: name,
                                            quantityText: quantityText)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = payload
        request.timeoutInterval = 15
        // 不用任何本地缓存，也不收 Cookie —— 减少可追踪状态。
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.httpShouldHandleCookies = false

        // ephemeral：不落磁盘缓存；自定义 delegate：拦截非 HTTPS 重定向。
        let session = URLSession(configuration: .ephemeral,
                                 delegate: HTTPSOnlyRedirectDelegate(),
                                 delegateQueue: nil)
        // 会话是一次性的，用完必须释放，否则会泄漏连接。
        defer { session.invalidateAndCancel() }

        let data: Data
        let response: URLResponse
        do {
            // 不能写成 `(data, response) = try await ...` —— Swift 不允许对已声明的
            // let 做元组解构赋值。这里先接成元组再拆开。
            let pair = try await session.data(for: request)
            data = pair.0
            response = pair.1
        } catch {
            throw LLMError.transport(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw LLMError.badStatus(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
            throw LLMError.emptyContent
        }

        guard let jsonData = Self.extractJSONObject(from: content),
              let raw = try? JSONDecoder().decode(RawNutritionJSON.self, from: jsonData) else {
            throw LLMError.undecodable
        }

        return raw.clamped()
    }

    // MARK: 内部构造

    private func makeEndpointURL(baseURL: String) throws -> URL {
        var trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        while trimmed.hasSuffix("/") { trimmed.removeLast() }

        guard let components = URLComponents(string: trimmed + "/chat/completions"),
              let scheme = components.scheme?.lowercased(),
              scheme == "https",
              let host = components.host, !host.isEmpty,
              let url = components.url else {
            throw LLMError.insecureURL(baseURL)
        }
        return url
    }

    /// 构造请求体。**这里是脱敏的唯一出口** —— 只放 name 与 quantityText。
    private func makeRequestPayload(model: String,
                                    name: String,
                                    quantityText: String?) throws -> Data {
        let q = (quantityText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        // 白名单：只有一个字段组合进 prompt，任何其他信息都不允许加进来。
        let userContent = q.isEmpty
            ? "食物名称：\(name)"
            : "食物名称：\(name)\n份量描述：\(q)"

        let system = """
        你是营养估算助手。根据给定的食物与份量，估算其营养含量。
        只输出一个 JSON 对象，不要输出任何解释、Markdown 代码块以外的文字。
        字段必须是：assumed_grams, kcal, protein_g, fat_g, carbs_g, calcium_mg, iron_mg, vitamin_c_mg, fiber_g。
        单位依次是：克、千卡、克、克、克、毫克、毫克、毫克、克。
        数值必须是非负数字，不要带单位字符串。
        如果无法确定，给出最合理的常见估计值即可。
        """

        let body = ChatRequest(
            model: model,
            messages: [
                ChatRequest.Message(role: "system", content: system),
                ChatRequest.Message(role: "user", content: userContent)
            ],
            temperature: 0,
            responseFormat: ChatRequest.ResponseFormat(type: "json_object")
        )
        return try JSONEncoder().encode(body)
    }

    // MARK: JSON 提取

    /// 从回复文本里抠出第一个 JSON 对象。
    ///
    /// 大模型经常自觉or不自觉地包一层 ```json 代码块，甚至前后加两句寒暄。
    /// 只信 rng出來的第一对花括号，比正则更稳。
    static func extractJSONObject(from text: String) -> Data? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              start < end else { return nil }
        let slice = String(text[start...end])
        return slice.data(using: .utf8)
    }
}

// MARK: - 重定向守卫

/// 只放行 HTTPS 重定向。
///
/// 防止「服务端返回 302 把请求引到 http://」这种降维 + 顺便把 URL 里的
/// Authorization 头带到明文信道上的情况 —— 那等于把用户的 Key 明文投递出去。
private final class HTTPSOnlyRedirectDelegate: NSObject, URLSessionTaskDelegate {

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if request.url?.scheme?.lowercased() == "https" {
            completionHandler(request)
        } else {
            completionHandler(nil)
        }
    }
}

// MARK: - 线协议模型

private struct ChatRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    struct ResponseFormat: Encodable {
        let type: String
    }

    let model: String
    let messages: [Message]
    let temperature: Double
    let responseFormat: ResponseFormat

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case responseFormat = "response_format"
    }
}

private struct ChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

/// 大模型返回的原始字段。「六月coverage不全」是常态 —— 缺失字段一律按 0 处理。
private struct RawNutritionJSON: Decodable {
    let assumedGrams: Double?
    let kcal: Double?
    let proteinG: Double?
    let fatG: Double?
    let carbsG: Double?
    let calciumMG: Double?
    let ironMG: Double?
    let vitaminCMG: Double?
    let fiberG: Double?

    enum CodingKeys: String, CodingKey {
        case assumedGrams = "assumed_grams"
        case kcal
        case proteinG = "protein_g"
        case fatG = "fat_g"
        case carbsG = "carbs_g"
        case calciumMG = "calcium_mg"
        case ironMG = "iron_mg"
        case vitaminCMG = "vitamin_c_mg"
        case fiberG = "fiber_g"
    }

    /// 限幅：负数归零，超出合理上限的截断。
    ///
    /// 大模型偶尔会给出「一份米饭 99999 kcal」这种数字。不拦住的话，
    /// 一条错数据能把整天的分析和 7 天趋势全带偏。
    func clamped() -> LLMNutritionEstimate {
        func clamp(_ v: Double?, _ max: Double) -> Double {
            guard let v, v.isFinite else { return 0 }
            return Swift.min(Swift.max(v, 0), max)
        }
        return LLMNutritionEstimate(
            assumedGrams: clamp(assumedGrams, 5000),
            kcal:         clamp(kcal, 5000),
            proteinG:     clamp(proteinG, 500),
            fatG:         clamp(fatG, 500),
            carbsG:       clamp(carbsG, 500),
            calciumMG:    clamp(calciumMG, 20000),
            ironMG:       clamp(ironMG, 500),
            vitaminCMG:   clamp(vitaminCMG, 20000),
            fiberG:       clamp(fiberG, 200)
        )
    }

    /// 字段缺失时不让整个 decode 失败 —— 大模型返回半截 JSON 是常态。
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        assumedGrams = try c.decodeIfPresent(Double.self, forKey: .assumedGrams)
        kcal         = try c.decodeIfPresent(Double.self, forKey: .kcal)
        proteinG     = try c.decodeIfPresent(Double.self, forKey: .proteinG)
        fatG         = try c.decodeIfPresent(Double.self, forKey: .fatG)
        carbsG       = try c.decodeIfPresent(Double.self, forKey: .carbsG)
        calciumMG    = try c.decodeIfPresent(Double.self, forKey: .calciumMG)
        ironMG       = try c.decodeIfPresent(Double.self, forKey: .ironMG)
        vitaminCMG   = try c.decodeIfPresent(Double.self, forKey: .vitaminCMG)
        fiberG       = try c.decodeIfPresent(Double.self, forKey: .fiberG)
    }
}
