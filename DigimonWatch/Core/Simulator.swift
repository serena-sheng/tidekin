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

/// 带发生时刻的事件。结算是在事后批量补算的，
/// 所以每个事件的真实时刻必须单独带上，不能统一盖成"你打开 app 的那一刻"。
struct TimedEvent: Equatable {
    let date: Date
    let event: SimEvent

    init(_ date: Date, _ event: SimEvent) {
        self.date = date
        self.event = event
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
    static func resolve(_ input: World, now: Date) -> (World, [TimedEvent]) {
        var w = input
        var events: [TimedEvent] = []

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
                events.append(TimedEvent(t, shouldSleep ? .fellAsleep : .wokeUp))
                if shouldSleep { w.poopAccum = 0 }
            }

            if w.stage == .egg {
                // 蛋只需孵化计时，不吃不拉。孵化不受权重影响——
                // 关掉时间线是为了不让时间推动进化，不是为了永远孵不出来。
                w.driveMinutes += 1.0
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
                    events.append(TimedEvent(t, .pooped))
                    if w.poop > w.tuning.maxPoop && !w.poopingInjuredThisCycle {
                        w.poopingInjuredThisCycle = true
                        w.injured += 1
                        events.append(TimedEvent(t, .injured))
                    }
                }

                // 进化计时（只在清醒时走）
                w.driveMinutes += w.tuning.weights.time
            }

            // Call 与失误
            updateCall(&w, at: t, events: &events)

            // 进化
            checkEvolution(&w, at: t, events: &events)

            // 死亡
            if w.injured >= w.tuning.maxInjury {
                w.isDead = true
                events.append(TimedEvent(t, .died))
                break
            }
        }

        // 停在已消费的分钟边界，余量留给下一次结算
        w.lastResolvedAt = w.isDead ? now : t
        for e in events {
            w.log.append(LogEntry(at: e.date, text: e.event.text))
        }
        if w.log.count > 40 { w.log = Array(w.log.suffix(40)) }
        return (w, events)
    }

    // MARK: -

    private static func updateCall(_ w: inout World, at t: Date, events: inout [TimedEvent]) {
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
            events.append(TimedEvent(t, .called))
            return
        }

        // 窗口内没处理 → 一次失误（饥饿与力量同时归零只算一次，这是原版的宽容设计）
        if !w.callPenalized,
           let started = w.callStartedAt,
           t.timeIntervalSince(started) >= Double(w.tuning.callWindowMinutes * 60) {
            w.callPenalized = true
            w.careMistakes += 1
            events.append(TimedEvent(t, .careMistake))
        }
    }

    /// 单一进化判定入口。时间线每走一分钟调它，健康/token 上报后也调它。
    private static func checkEvolution(_ w: inout World, at t: Date, events: inout [TimedEvent]) {
        guard let need = Evolution.thresholdMinutes(for: w.stage, tuning: w.tuning),
              w.driveMinutes >= Double(need),
              let next = w.stage.next,
              Evolution.isEligible(for: next, from: w) else { return }

        let from = w.species
        let to = Evolution.species(for: next, from: w)
        w.stage = next
        w.species = to
        w.stageStartedAt = t
        w.driveMinutes = 0
        w.hunger = next.maxHearts
        w.strength = next.maxHearts
        w.hungerAccum = 0
        w.strengthAccum = 0
        w.healthStrengthAccum = 0
        w.tokenEffortAccum = 0
        w.careMistakes = 0
        w.sleepDisturb = 0
        w.overfeed = 0
        w.trainCount = 0
        w.effort = 0
        w.callKind = .none
        w.callStartedAt = nil
        w.callPenalized = false
        events.append(TimedEvent(t, .evolved(from: from, to: to)))
    }

    // MARK: - 另外两条驱动线

    /// 健康线：把步数折成驱动分钟，并按每 N 驱动分钟补一颗力量心。
    /// 只认增量；重复上报同一批步数会重复计入，调用方负责去重。
    static func applyHealth(_ input: World, steps: Int, at now: Date) -> (World, [TimedEvent]) {
        var w = resolve(input, now: now).0
        var events: [TimedEvent] = []
        guard steps > 0, !w.isDead, w.stage != .egg else { return (w, events) }

        w.totalSteps += steps
        let units = Double(steps) / max(1, w.tuning.stepsPerDriveMinute)
        let driven = units * w.tuning.weights.health
        w.driveMinutes += driven

        w.healthStrengthAccum += driven
        let per = max(1, w.tuning.healthStrengthPerDriveMinute)
        while w.healthStrengthAccum >= per && w.strength < w.maxHearts {
            w.healthStrengthAccum -= per
            w.strength += 1
            clearCallIfSatisfied(&w)
        }

        checkEvolution(&w, at: now, events: &events)
        if let last = events.last { w.log.append(LogEntry(at: last.date, text: last.event.text)) }
        return (w, events)
    }

    /// Token 线：把 token 折成驱动分钟，并按比例补努力值。
    /// 只统计手表内对话的消耗，且每天有上限，超出部分不计。
    static func applyTokens(_ input: World, tokens: Int, at now: Date) -> (World, [TimedEvent]) {
        var w = resolve(input, now: now).0
        var events: [TimedEvent] = []
        guard tokens > 0, !w.isDead, w.stage != .egg else { return (w, events) }

        let today = dayKey(now)
        if w.tokenDay != today {
            w.tokenDay = today
            w.tokenDayUsed = 0
        }
        let remaining = max(0, w.tuning.dailyTokenCap - w.tokenDayUsed)
        let counted = min(tokens, remaining)
        guard counted > 0 else { return (w, events) }

        w.tokenDayUsed += counted
        w.totalTokens += counted
        let tokens = counted
        let units = Double(tokens) / max(1, w.tuning.tokensPerDriveMinute)
        let driven = units * w.tuning.weights.token
        w.driveMinutes += driven

        w.tokenEffortAccum += driven
        let per = max(1, w.tuning.tokenEffortPerDriveMinute)
        while w.tokenEffortAccum >= per && w.effort < Double(w.maxHearts) {
            w.tokenEffortAccum -= per
            w.effort = min(Double(w.maxHearts), w.effort + 0.05)
        }

        checkEvolution(&w, at: now, events: &events)
        if let last = events.last { w.log.append(LogEntry(at: last.date, text: last.event.text)) }
        return (w, events)
    }

    static func dayKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f.string(from: date)
    }

    // MARK: - 战斗

    /// 记一场战斗的结果。Perfect 进化需要 battles/wins，所以这里要顺手判一次进化。
    static func recordBattle(_ input: World, won: Bool, at now: Date) -> (World, [TimedEvent]) {
        var w = resolve(input, now: now).0
        var events: [TimedEvent] = []
        guard !w.isDead else { return (w, events) }

        w.battles += 1
        if won {
            w.wins += 1
        } else {
            // 输了可能受伤，这是 Ver.1 里唯一会把宠物打死的机制
            w.injured = min(w.tuning.maxInjury, w.injured + 1)
            events.append(TimedEvent(now, .injured))
        }

        if w.injured >= w.tuning.maxInjury {
            w.isDead = true
            events.append(TimedEvent(now, .died))
        } else {
            checkEvolution(&w, at: now, events: &events)
        }
        return (w, events)
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
