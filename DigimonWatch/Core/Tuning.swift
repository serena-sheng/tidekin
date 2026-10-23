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

    // MARK: - 三线驱动
    //
    // 三个源各自折算成"驱动分钟"，加权后推进进化进度。
    // 权重设 0 就关掉那条线；time=1 且其余=0 时行为与经典复刻完全一致。

    var weights = DriveWeights()
    /// 多少步算一个驱动分钟（约 100 步 ≈ 1 分钟，1 万步 ≈ 100 分钟）
    var stepsPerDriveMinute: Double = 100
    /// 多少 token 算一个驱动分钟（约 2000 token ≈ 1 分钟，20 万 token ≈ 100 分钟）
    var tokensPerDriveMinute: Double = 2000
    /// 每走满多少个驱动分钟，健康线补 1 颗力量心
    var healthStrengthPerDriveMinute: Double = 30
    /// 每多少个驱动分钟，token 线补 0.05 努力值
    var tokenEffortPerDriveMinute: Double = 40

    struct DriveWeights: Codable, Equatable {
        var time: Double = 1.0
        var health: Double = 1.0
        var token: Double = 1.0
    }
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
