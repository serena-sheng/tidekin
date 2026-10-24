import Foundation

/// 单文件 JSON 持久化。放 App Group 容器，方便将来给 Complication / Widget 共用。
enum Persistence {
    static let appGroup = "group.com.serena.tidekin"
    static let fileName = "world.json"

    static var url: URL {
        if let container = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
            return container.appendingPathComponent(fileName)
        }
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent(fileName)
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted]
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    static func load() -> World? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(World.self, from: data)
    }

    static func save(_ world: World) {
        guard let data = try? encoder.encode(world) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func wipe() {
        try? FileManager.default.removeItem(at: url)
    }
}
