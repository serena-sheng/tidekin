import Foundation

enum CallKind: String, Codable {
    case none, hunger, strength, both

    var isActive: Bool { self != .none }
}

struct LogEntry: Codable, Identifiable, Equatable {
    var id = UUID()
    var at: Date
    var text: String
}

/// 世界状态。纯值类型，不知道"现在几点"——时间永远由外部传入。
struct World: Codable {
    var tuning: Tuning

    var stage: Stage
    var species: String

    var hunger: Int
    var strength: Int
    var effort: Double
    var weight: Int
    var poop: Int
    var injured: Int

    // 隐藏计数器（原版玩家看不到）
    var careMistakes: Int
    var sleepDisturb: Int
    var overfeed: Int
    var trainCount: Int

    var battles: Int
    var wins: Int

    // 时间戳
    var bornAt: Date
    var stageStartedAt: Date
    var lastResolvedAt: Date

    // 内部累加器（分钟）
    var awakeMinutes: Int
    var hungerAccum: Int
    var strengthAccum: Int
    var poopAccum: Int

    // Call 状态
    var callKind: CallKind
    var callStartedAt: Date?
    var callPenalized: Bool

    var isAsleep: Bool
    var isDead: Bool
    var poopingInjuredThisCycle: Bool

    var log: [LogEntry]

    // MARK: - 新建

    static func newGame(at now: Date, tuning: Tuning = Tuning()) -> World {
        World(
            tuning: tuning,
            stage: .egg,
            species: "DIGITAMA",
            hunger: 0, strength: 0, effort: 0, weight: 5, poop: 0, injured: 0,
            careMistakes: 0, sleepDisturb: 0, overfeed: 0, trainCount: 0,
            battles: 0, wins: 0,
            bornAt: now, stageStartedAt: now, lastResolvedAt: now,
            awakeMinutes: 0, hungerAccum: 0, strengthAccum: 0, poopAccum: 0,
            callKind: .none, callStartedAt: nil, callPenalized: false,
            isAsleep: false, isDead: false, poopingInjuredThisCycle: false,
            log: []
        )
    }

    // MARK: - 派生量

    var maxHearts: Int { stage.maxHearts }

    var ageHours: Double {
        (lastResolvedAt.timeIntervalSince(bornAt) / 3600)
    }

    var winRate: Double {
        battles == 0 ? 0 : Double(wins) / Double(battles)
    }

    /// 距离下一次进化还有多少分钟（睡眠不计）。不做世界推进，仅用于展示。
    var minutesToEvolution: Int? {
        guard let need = Evolution.thresholdMinutes(for: stage, tuning: tuning) else { return nil }
        return max(0, need - awakeMinutes)
    }

    var nextStage: Stage? { stage.next }

    var mood: String {
        if isDead { return "GONE" }
        if isAsleep { return "ASLEEP" }
        if callKind.isActive { return "CALLING" }
        if injured > 0 { return "HURT" }
        if poop > tuning.maxPoop { return "SMELLY" }
        if hunger == 0 || strength == 0 { return "HUNGRY" }
        if hunger <= 2 { return "PECKISH" }
        return "HAPPY"
    }
}
