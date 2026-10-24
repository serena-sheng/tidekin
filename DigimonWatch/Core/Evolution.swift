import Foundation

/// 潮线（Whale Line）进化表。
///
/// 六阶段结构不动，只换角色与判定：
/// 失养 → 漂雾；练得多 → 跃潮；聊得多（token 深线）→ 潜渊；否则游潮。
/// 完全体由成人形态决定，其中潜渊与漂雾殊途同归，都沉成鲲。
enum Evolution {

    static func thresholdMinutes(for stage: Stage, tuning: Tuning) -> Int? {
        switch stage {
        case .egg: return tuning.eggHatchMinutes
        case .baby1: return tuning.baby1Minutes
        case .baby2: return tuning.baby2ToChildMinutes
        case .child: return tuning.childToAdultMinutes
        case .adult: return tuning.adultToPerfectMinutes
        case .perfect: return nil
        }
    }

    /// 完全体要求战斗积累；不满足就停在成人期，不硬推。
    static func isEligible(for next: Stage, from w: World) -> Bool {
        guard next == .perfect else { return true }
        return w.battles >= 15 && w.winRate >= 0.4
    }

    static func species(for next: Stage, from w: World) -> String {
        switch next {
        case .egg: return "tideseed"
        case .baby1: return "spume"
        case .baby2: return "calf"
        case .child: return w.careMistakes <= 3 ? "cetal" : "mael"
        case .adult: return adultSpecies(from: w)
        case .perfect: return perfectSpecies(from: w)
        }
    }

    private static func adultSpecies(from w: World) -> String {
        if w.careMistakes > 3 { return "drift" }
        if w.trainCount >= 32 { return "breacher" }
        if w.totalTokens >= w.tuning.deepPathTokens { return "abyss" }
        return "current"
    }

    private static func perfectSpecies(from w: World) -> String {
        switch Characters.id(for: w.species) {
        case "breacher": return "kraken"
        case "current": return "siren"
        default: return "kun"
        }
    }
}
