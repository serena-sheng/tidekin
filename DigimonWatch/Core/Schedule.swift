import Foundation

/// 计算"下一个值得叫醒你的时刻"。用于排本地通知。
///
/// 规则：这里只做前向预测，不改世界。睡眠时段跳过，与原版一致。
/// 返回最早发生的那一件事，因为 watchOS 的待发通知配额紧张，
/// 一次只排一条、每次结算后续排。
enum Schedule {

    struct Event {
        let date: Date
        let title: String
        let body: String
    }

    /// 最多向前看 7 天，避免长时间不动时空转。
    private static let horizonMinutes = 7 * 24 * 60

    static func nextEvent(world w: World, from now: Date) -> Event? {
        guard !w.isDead else { return nil }

        var hunger = w.hunger
        var strength = w.strength
        var awake = w.awakeMinutes
        var hungerAccum = w.hungerAccum
        var strengthAccum = w.strengthAccum
        var t = w.lastResolvedAt > now ? w.lastResolvedAt : now

        let decay = max(1, w.tuning.heartDecayMinutes)

        for _ in 0..<horizonMinutes {
            t = t.addingTimeInterval(60)
            let asleep = Simulator.isSleepHour(t, tuning: w.tuning)

            if w.stage == .egg {
                awake += 1
                if let need = Evolution.thresholdMinutes(for: .egg, tuning: w.tuning),
                   awake >= need {
                    return Event(date: t, title: "HATCHING", body: "Your egg is waking up.")
                }
                continue
            }

            if asleep { continue }

            // 饥饿
            hungerAccum += 1
            if hungerAccum >= decay {
                hungerAccum = 0
                if hunger > 0 {
                    hunger -= 1
                    if hunger == 0 {
                        return Event(date: t,
                                     title: "\(w.species) IS CALLING",
                                     body: "Hungry. Feed it before it counts as a care mistake.")
                    }
                }
            }

            // 力量
            strengthAccum += 1
            if strengthAccum >= decay {
                strengthAccum = 0
                if strength > 0 {
                    strength -= 1
                    if strength == 0 {
                        return Event(date: t,
                                     title: "\(w.species) IS CALLING",
                                     body: "Out of power. Train it.")
                    }
                }
            }

            // 进化
            awake += 1
            if let need = Evolution.thresholdMinutes(for: w.stage, tuning: w.tuning),
               awake >= need {
                return Event(date: t,
                             title: "EVOLVING",
                             body: "\(w.species) is about to change.")
            }
        }

        return nil
    }
}
