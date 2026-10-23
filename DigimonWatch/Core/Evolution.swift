import Foundation

/// Ver.1 进化表。所有阈值来自原版规则（见文档第二节）。
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

    /// Perfect 阶段要求战斗积累；不满足就停在 Adult，不硬推。
    static func isEligible(for next: Stage, from w: World) -> Bool {
        guard next == .perfect else { return true }
        return w.battles >= 15 && w.winRate >= 0.4
    }

    static func species(for next: Stage, from w: World) -> String {
        switch next {
        case .egg: return "DIGITAMA"
        case .baby1: return "BOTAMON"
        case .baby2: return "KOROMON"
        case .child: return w.careMistakes <= 3 ? "AGUMON" : "BETAMON"
        case .adult: return adultSpecies(from: w)
        case .perfect: return perfectSpecies(from: w)
        }
    }

    private static func adultSpecies(from w: World) -> String {
        let m = w.careMistakes
        let train = w.trainCount
        let over = w.overfeed
        let disturb = w.sleepDisturb

        if w.species == "AGUMON" {
            if m <= 3 {
                return train >= 32 ? "GREYMON" : "DEVIMON"
            }
            if (5...15).contains(train) && over >= 3 && (0...4).contains(disturb) {
                return "TYRANOMON"
            }
            if train >= 16 && over >= 3 && (0...6).contains(disturb) {
                return "MERAMON"
            }
            return "NUMEMON"
        }

        if w.species == "BETAMON" {
            if m <= 3 {
                return train >= 48 ? "DEVIMON" : "MERAMON"
            }
            if (8...31).contains(train) {
                if over >= 4 { return "SEADRAMON" }
                if over <= 3 && disturb >= 9 { return "AIDRAMON" }
            }
            return "NUMEMON"
        }

        return "NUMEMON"
    }

    private static func perfectSpecies(from w: World) -> String {
        switch w.species {
        case "GREYMON", "DEVIMON", "AIDRAMON": return "METALGREYMON"
        case "TYRANOMON", "MERAMON", "SEADRAMON": return "MAMEMON"
        case "NUMEMON": return "MONZAEMON"
        default: return "NUMEMON"
        }
    }
}
