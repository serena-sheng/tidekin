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

    /// 进化进度，单位是"驱动分钟"= 三个源加权折算后的和。
    /// 时间源每分钟 +1×weights.time；健康与 token 由 applyHealth/applyTokens 累加。
    var driveMinutes: Double
    var healthStrengthAccum: Double
    var tokenEffortAccum: Double
    /// 累计走过多少步、花过多少 token（终身统计，不随进化清零）
    var totalSteps: Int
    var totalTokens: Int
    /// 当日 token 记账（用于每日上限），格式 yyyy-MM-dd
    var tokenDay: String
    var tokenDayUsed: Int

    // 内部累加器（分钟）
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
            driveMinutes: 0, healthStrengthAccum: 0, tokenEffortAccum: 0,
            totalSteps: 0, totalTokens: 0, tokenDay: "", tokenDayUsed: 0,
            hungerAccum: 0, strengthAccum: 0, poopAccum: 0,
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
        return Int(max(0, Double(need) - driveMinutes))
    }

    var nextStage: Stage? { stage.next }

    /// 世界在向玩家要什么。优先级：死亡 > 受伤 > 便便超限 > 饿 > 力竭。
    /// 注意与「选中」区分：这是需求，不是游标。
    enum Demand: String {
        case none, feed, train, clean, heal
    }

    var demand: Demand {
        if isDead || isAsleep || stage == .egg { return .none }
        if injured > 0 { return .heal }
        if poop > tuning.maxPoop { return .clean }
        if hunger == 0 { return .feed }
        if strength == 0 { return .train }
        return .none
    }

    /// Perfect 只差多少场；nil 表示还差胜率或不在成人期。
    var battlesToPerfect: Int? {
        guard stage == .adult else { return nil }
        return battles < 15 ? 15 - battles : nil
    }

    /// 主屏右上角的"还有多久"。成人期先看战斗条件，再看时间。
    var progressText: String {
        if isDead { return "" }
        if stage == .egg { return "" }
        if stage == .perfect { return "MAX" }
        if let need = battlesToPerfect, need > 0 { return "\(need) FIGHTS" }
        if stage == .adult, battles >= 15, winRate < 0.4 { return "WIN MORE" }
        guard let m = minutesToEvolution else { return "MAX" }
        if m < 60 { return "\(m)m" }
        return "\(m / 60)h\(m % 60 == 0 ? "" : "\(m % 60 / 6 * 10)m")"
    }

    /// 主屏第二行：需求优先，没有需求才报心情。
    var headline: String {
        switch demand {
        case .feed: return "FEED ME"
        case .train: return "TRAIN ME"
        case .clean: return "CLEAN ME"
        case .heal: return "HEAL ME"
        case .none: break
        }
        if isDead { return "GONE" }
        if stage == .egg { return "HATCHING" }
        if isAsleep { return "ASLEEP" }
        if callKind.isActive { return "CALLING" }
        if hunger <= 1 || strength <= 1 { return "PECKISH" }
        return "FINE"
    }

    var mood: String {
        if isDead { return "GONE" }
        if stage == .egg { return "HATCHING" }
        if isAsleep { return "ASLEEP" }
        if callKind.isActive { return "CALLING" }
        if injured > 0 { return "HURT" }
        if poop > tuning.maxPoop { return "SMELLY" }
        if hunger == 0 || strength == 0 { return "HUNGRY" }
        if hunger <= 2 { return "PECKISH" }
        return "HAPPY"
    }
}
