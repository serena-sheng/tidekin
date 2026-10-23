import Foundation

enum SimEvent: Equatable {
    case hatched(String)
    case evolved(from: String, to: String)
    case fellAsleep
    case wokeUp
    case called
    case careMistake
    case pooped
    case injured
    case died

    var text: String {
        switch self {
        case .hatched(let s): return "\(s) hatched"
        case .evolved(_, let to): return "evolved into \(to)"
        case .fellAsleep: return "fell asleep"
        case .wokeUp: return "woke up"
        case .called: return "calling for you"
        case .careMistake: return "care mistake"
        case .pooped: return "left a mess"
        case .injured: return "got injured"
        case .died: return "returned to data"
        }
    }
}

/// 时间结算内核。纯函数：同样的 (world, now) 永远得到同样的结果。
enum Simulator {

    static func isSleepHour(_ date: Date, tuning: Tuning) -> Bool {
        let h = Calendar.current.component(.hour, from: date)
        let start = tuning.sleepStartHour
        let end = tuning.sleepEndHour
        if start > end { return h >= start || h < end }
        return h >= start && h < end
    }

    /// 把 world 推进到 now。逐分钟推进，睡眠时暂停一切衰减与进化计时。
    static func resolve(_ input: World, now: Date) -> (World, [SimEvent]) {
        var w = input
        var events: [SimEvent] = []

        guard !w.isDead, now > w.lastResolvedAt else { return (w, events) }

        // 上限：最多推 60 天，防止脏数据把机器拖死
        let capSeconds = 60.0 * 24 * 3600
        let start = max(w.lastResolvedAt, now.addingTimeInterval(-capSeconds))

        // 关键：只消费整分钟，不足一分钟的余量留给下一次。
        // 否则每次前台刷新都会吃掉一个整分钟的配额，世界会跑快 N 倍。
        let wholeMinutes = Int(now.timeIntervalSince(start) / 60)
        guard wholeMinutes > 0 else { return (w, events) }

        var t = start
        for _ in 0..<wholeMinutes {
            t = t.addingTimeInterval(60)

            // 睡觉 / 醒来
            let shouldSleep = isSleepHour(t, tuning: w.tuning)
            if shouldSleep != w.isAsleep {
                w.isAsleep = shouldSleep
                events.append(shouldSleep ? .fellAsleep : .wokeUp)
                if shouldSleep { w.poopAccum = 0 }
            }

            if w.stage == .egg {
                // 蛋只需要孵化计时，不吃不拉
                w.awakeMinutes += 1
            } else if !w.isAsleep {
                // 掉心
                w.hungerAccum += 1
                if w.hungerAccum >= w.tuning.heartDecayMinutes {
                    w.hungerAccum = 0
                    if w.hunger > 0 { w.hunger -= 1 }
                }
                w.strengthAccum += 1
                if w.strengthAccum >= w.tuning.heartDecayMinutes {
                    w.strengthAccum = 0
                    if w.strength > 0 { w.strength -= 1 }
                }

                // 便便
                w.poopAccum += 1
                if w.poopAccum >= w.tuning.poopMinutes {
                    w.poopAccum = 0
                    w.poop += 1
                    events.append(.pooped)
                    if w.poop > w.tuning.maxPoop && !w.poopingInjuredThisCycle {
                        w.poopingInjuredThisCycle = true
                        w.injured += 1
                        events.append(.injured)
                    }
                }

                // 进化计时（只在清醒时走）
                w.awakeMinutes += 1
            }

            // Call 与失误
            updateCall(&w, at: t, events: &events)

            // 进化
            if let need = Evolution.thresholdMinutes(for: w.stage, tuning: w.tuning),
               w.awakeMinutes >= need,
               let next = w.stage.next,
               Evolution.isEligible(for: next, from: w) {
                let from = w.species
                let to = Evolution.species(for: next, from: w)
                w.stage = next
                w.species = to
                w.stageStartedAt = t
                w.awakeMinutes = 0
                w.hunger = next.maxHearts
                w.strength = next.maxHearts
                w.hungerAccum = 0
                w.strengthAccum = 0
                w.careMistakes = 0
                w.sleepDisturb = 0
                w.overfeed = 0
                w.trainCount = 0
                w.effort = 0
                w.callKind = .none
                w.callStartedAt = nil
                w.callPenalized = false
                events.append(.evolved(from: from, to: to))
            }

            // 死亡
            if w.injured >= w.tuning.maxInjury {
                w.isDead = true
                events.append(.died)
                break
            }
        }

        // 停在已消费的分钟边界，余量留给下一次结算
        w.lastResolvedAt = w.isDead ? now : t
        for e in events {
            w.log.append(LogEntry(at: now, text: e.text))
        }
        if w.log.count > 40 { w.log = Array(w.log.suffix(40)) }
        return (w, events)
    }

    // MARK: -

    private static func updateCall(_ w: inout World, at t: Date, events: inout [SimEvent]) {
        guard w.stage != .egg, !w.isAsleep else {
            w.callKind = .none
            w.callStartedAt = nil
            w.callPenalized = false
            return
        }

        let hungry = w.hunger == 0
        let weak = w.strength == 0
        let kind: CallKind = hungry && weak ? .both : hungry ? .hunger : weak ? .strength : .none

        if kind == .none {
            w.callKind = .none
            w.callStartedAt = nil
            w.callPenalized = false
            return
        }

        if !w.callKind.isActive {
            w.callKind = kind
            w.callStartedAt = t
            w.callPenalized = false
            events.append(.called)
            return
        }

        // 窗口内没处理 → 一次失误（饥饿与力量同时归零只算一次，这是原版的宽容设计）
        if !w.callPenalized,
           let started = w.callStartedAt,
           t.timeIntervalSince(started) >= Double(w.tuning.callWindowMinutes * 60) {
            w.callPenalized = true
            w.careMistakes += 1
            events.append(.careMistake)
        }
    }

    // MARK: - 玩家动作

    static func feed(_ input: World, at now: Date) -> World {
        var w = resolve(input, now: now).0
        guard !w.isDead, !w.isAsleep, w.stage != .egg else { return w }

        if w.hunger >= w.maxHearts {
            w.overfeed += 1
        }
        w.hunger = min(w.maxHearts, w.hunger + 1)
        w.weight += w.tuning.feedWeightGain
        clearCallIfSatisfied(&w)
        return w
    }

    static func train(_ input: World, at now: Date) -> World {
        var w = resolve(input, now: now).0
        guard !w.isDead, !w.isAsleep, w.stage != .egg else { return w }

        w.trainCount += 1
        w.effort = min(Double(w.maxHearts), w.effort + w.tuning.trainEffortPerSession)
        if w.strength < w.maxHearts { w.strength += w.tuning.trainStrengthGain }
        w.weight = max(1, w.weight - w.tuning.trainWeightLoss)
        clearCallIfSatisfied(&w)
        return w
    }

    static func clean(_ input: World, at now: Date) -> World {
        var w = resolve(input, now: now).0
        w.poop = 0
        w.poopAccum = 0
        w.poopingInjuredThisCycle = false
        return w
    }

    static func heal(_ input: World, at now: Date) -> World {
        var w = resolve(input, now: now).0
        if w.injured > 0 { w.injured -= 1 }
        return w
    }

    /// 处理 Call：能满足就满足，满足不了（心还空着）就当作安抚，赎回一次失误。
    private static func clearCallIfSatisfied(_ w: inout World) {
        guard w.callKind.isActive else { return }
        let stillHungry = w.hunger == 0
        let stillWeak = w.strength == 0
        if !stillHungry && !stillWeak {
            w.callKind = .none
            w.callStartedAt = nil
            if w.callPenalized {
                w.callPenalized = false
                if w.tuning.forgiveness == .redeemable, w.careMistakes > 0 {
                    w.careMistakes -= 1
                }
            }
        }
    }
}
