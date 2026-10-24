import Foundation

/// DeepSeek 客户端。只管发请求和解析，不掺业务。
///
/// 官方只提供 `/user/balance`，**没有 token 用量查询接口**，
/// 所以用量必须自己记账（见 TokenLedger）。
struct DeepSeekClient {
    var apiKey: String
    var model: String = "deepseek-flash"
    var baseURL = URL(string: "https://api.deepseek.com/chat/completions")!
    var session: URLSession = .shared

    struct Message: Encodable {
        let role: String
        let content: String
    }

    struct Request: Encodable {
        let model: String
        let messages: [Message]
        let stream: Bool
        let max_tokens: Int
    }

    struct Response: Decodable {
        struct Choice: Decodable {
            struct Msg: Decodable { let content: String? }
            let message: Msg
        }
        struct Usage: Decodable {
            let prompt_tokens: Int?
            let completion_tokens: Int?
            let total_tokens: Int?
        }
        let choices: [Choice]
        let usage: Usage?
    }

    struct Reply {
        let text: String
        /// 这次调用实际消耗的 token。用于喂给 token 驱动线，形成闭环。
        let tokens: Int
    }

    enum Failure: Error, LocalizedError {
        case noKey
        case http(Int, String)
        case empty

        var errorDescription: String? {
            switch self {
            case .noKey: return "没有 API Key"
            case .http(let code, let body): return "HTTP \(code)：\(body.prefix(160))"
            case .empty: return "模型没有返回内容"
            }
        }
    }

    func chat(_ messages: [Message], maxTokens: Int = 320) async throws -> Reply {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else { throw Failure.noKey }

        var req = URLRequest(url: baseURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 30
        req.httpBody = try JSONEncoder().encode(
            Request(model: model, messages: messages, stream: false, max_tokens: maxTokens)
        )

        let (data, response) = try await session.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw Failure.http(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard let text = decoded.choices.first?.message.content, !text.isEmpty else {
            throw Failure.empty
        }
        let used = decoded.usage?.total_tokens
            ?? ((decoded.usage?.prompt_tokens ?? 0) + (decoded.usage?.completion_tokens ?? 0))
        return Reply(text: text.trimmingCharacters(in: .whitespacesAndNewlines), tokens: used)
    }

    // MARK: - 宠物人格

    /// 让数码兽用第一人称说话。喂进去的是世界状态，
    /// 所以它的回答会跟着饥饿、心情、阶段变。
    static func persona(for w: World) -> Message {
        let stageLine: String
        switch w.stage {
        case .egg: stageLine = "你还在蛋里，只能断断续续地回应。"
        case .baby1: stageLine = "你是幼年期 I，说话很短，词汇很少。"
        case .baby2: stageLine = "你是幼年期 II，能说短句，爱撒娇。"
        case .child: stageLine = "你是成长期，有点自信，会炫耀。"
        case .adult: stageLine = "你是成熟期，沉稳但不失好胜。"
        case .perfect: stageLine = "你是完全体，语气从容，偶尔俯视对方。"
        }

        var state: [String] = []
        state.append("饥饿心 \(w.hunger)/\(w.maxHearts)")
        state.append("力量心 \(w.strength)/\(w.maxHearts)")
        state.append("心情 \(w.mood)")
        if w.poop > 0 { state.append("屏幕上有 \(w.poop) 坨便便") }
        if w.isAsleep { state.append("你正在睡觉") }
        if w.injured > 0 { state.append("你受了 \(w.injured) 次伤") }
        state.append("体重 \(w.weight)g")

        return Message(role: "system", content: """
        你是 \(w.displayName)，一只住在手表里的鲸。你在跟你的搭档（玩家）说话。

        \(stageLine)
        现在的状态：\(state.joined(separator: "，"))。

        规则：
        - 用中文，两三句话说清，不要长篇大论。
        - 保持角色，不要解释自己是 AI 或模型。
        - 状态差就抱怨（饿、累、脏），状态好就得意。
        - 允许向玩家提一个具体要求（喂食、散步、多聊几句——聊天会喂大你）。
        - 不要用表情符号。
        """)
    }
}
