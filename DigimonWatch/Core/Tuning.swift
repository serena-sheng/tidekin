import Foundation

/// 所有玩法数值集中在这里。改玩法 = 只改这个文件。
struct Tuning: Codable, Equatable {
    // 时间尺度
    var minuteScale: Double = 1.0          // 调试用：>1 加速，<1 减速
    var eggHatchMinutes: Int = 1
    var baby1Minutes: Int = 10
    var baby2ToChildMinutes: Int = 6 * 60
    var childToAdultMinutes: Int = 24 * 60
    var adultToPerfectMinutes: Int = 36 * 60

    // 资源衰减
    var heartDecayMinutes: Int = 60        // 每 N 分钟掉 1 心
    var callWindowMinutes: Int = 20        // 亮灯后多久算一次失误
    var poopMinutes: Int = 240             // 每 N 分钟一坨
    var sleepStartHour: Int = 22
    var sleepEndHour: Int = 7

    // 上限
    var maxPoop: Int = 4
    var maxInjury: Int = 20

    // 失误模型：0 单向累计（原版） / 1 可补（每次处理赎回 1 次）
    var forgiveness: Forgiveness = .redeemable

    enum Forgiveness: String, Codable { case none, redeemable, decaying }

    // 训练
    var trainEffortPerSession: Double = 0.25
    var trainStrengthGain: Int = 1
    var trainWeightLoss: Int = 1
    var feedWeightGain: Int = 1
    var overfeedThreshold: Int = 3          // 连续在满腹时喂食
}

/// 阶段。原版 6 段 + 蛋。
enum Stage: Int, Codable, CaseIterable {
    case egg, baby1, baby2, child, adult, perfect

    var display: String {
        switch self {
        case .egg: return "DIGITAMA"
        case .baby1: return "BABY I"
        case .baby2: return "BABY II"
        case .child: return "CHILD"
        case .adult: return "ADULT"
        case .perfect: return "PERFECT"
        }
    }

    var maxHearts: Int {
        switch self {
        case .egg, .baby1: return 4
        case .baby2: return 4
        case .child: return 5
        case .adult, .perfect: return 6
        }
    }

    var next: Stage? {
        switch self {
        case .egg: return .baby1
        case .baby1: return .baby2
        case .baby2: return .child
        case .child: return .adult
        case .adult: return .perfect
        case .perfect: return nil
        }
    }
}
