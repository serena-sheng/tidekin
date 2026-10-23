import Foundation

/// Token 用量账本。
///
/// DeepSeek 官方**没有** token 用量查询接口（只有 `/user/balance` 查余额），
/// 所以这里的做法是：由一个可信来源上报「累计已用 token」，本地只记增量。
/// 上报端可以是 Mac 上的脚本（统计 omp / Claudian 的 usage），也可以是自己搭的端点。
///
/// 端点约定（二选一，都接受）：
///   { "tokens": 123456 }        // 累计总量
///   { "total": 123456 }
/// 或者直接返回纯数字 123456。
enum TokenLedger {

    private static let lastTotalKey = "token.lastTotal"

    static var lastTotal: Int {
        get { UserDefaults.standard.integer(forKey: lastTotalKey) }
        set { UserDefaults.standard.set(newValue, forKey: lastTotalKey) }
    }

    enum Failure: Error, LocalizedError {
        case badURL
        case http(Int)
        case malformed

        var errorDescription: String? {
            switch self {
            case .badURL: return "端点地址不合法"
            case .http(let c): return "端点返回 HTTP \(c)"
            case .malformed: return "端点返回的数据看不懂"
            }
        }
    }

    /// 拉一次累计值，返回「自上次以来新增的 token」。
    /// 累计值变小视为账本被重置（换了账号/环境），本次不计增量。
    static func pullDelta(endpoint: String, secret: String?) async throws -> Int {
        guard let url = URL(string: endpoint.trimmingCharacters(in: .whitespaces)),
              url.scheme != nil else { throw Failure.badURL }

        var req = URLRequest(url: url)
        req.timeoutInterval = 20
        req.cachePolicy = .reloadIgnoringLocalCacheData
        if let secret, !secret.isEmpty {
            req.setValue("Bearer \(secret)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw Failure.http(http.statusCode)
        }

        guard let total = parseTotal(data) else { throw Failure.malformed }
        let previous = lastTotal
        lastTotal = total
        return total > previous ? total - previous : 0
    }

    static func parseTotal(_ data: Data) -> Int? {
        if let n = Int(String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)) {
            return n
        }
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        for key in ["tokens", "total", "total_tokens", "used"] {
            if let v = obj[key] as? Int { return v }
            if let v = obj[key] as? Double { return Int(v) }
            if let s = obj[key] as? String, let v = Int(s) { return v }
        }
        return nil
    }

    /// 手动记账：你在别处看到用量时直接填进来，同样只算增量。
    static func recordManual(total: Int) -> Int {
        let previous = lastTotal
        lastTotal = max(previous, total)
        return total > previous ? total - previous : 0
    }

    static func reset() { lastTotal = 0 }
}
