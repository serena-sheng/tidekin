import Foundation

// 固定时间基准验证结算内核
var exitCode: Int32 = 0
func check(_ cond: Bool, _ label: String) {
    print(cond ? "  PASS  \(label)" : "  FAIL  \(label)")
    if !cond { exitCode = 1 }
}

var cal = Calendar(identifier: .gregorian)
cal.timeZone = TimeZone(identifier: "Asia/Shanghai")!
func date(_ d: Int, _ h: Int, _ m: Int = 0) -> Date {
    var c = DateComponents()
    c.year = 2026; c.month = 10; c.day = d; c.hour = h; c.minute = m
    return cal.date(from: c)!
}
func plus(_ d: Date, _ minutes: Int) -> Date { d.addingTimeInterval(Double(minutes) * 60) }

let t = Tuning()
let start = date(23, 9, 0)

// 1. 孵化
var w = World.newGame(at: start, tuning: t)
w = Simulator.resolve(w, now: plus(start, 2)).0
check(w.stage == .baby1 && w.species == "spume", "2 分钟孵出 BOTAMON（\(w.stage.display)/\(Characters.display(w.species))）")

// 2. Baby II
w = Simulator.resolve(w, now: plus(start, 13)).0
check(w.stage == .baby2 && w.species == "calf", "13 分钟到 KOROMON（\(w.stage.display)/\(Characters.display(w.species))）")

// 3. 放任 5 小时：应饿空并记失误，但仍未进化
w = Simulator.resolve(w, now: plus(start, 13 + 5 * 60)).0
check(w.stage == .baby2, "5 小时仍停在 BABY II（\(w.stage.display)）")
check(w.careMistakes >= 1, "放任不管产生失误（\(w.careMistakes) 次）")

// 4. 到 6h13m 进化，失误清零
w = Simulator.resolve(w, now: plus(start, 13 + 6 * 60)).0
check(w.stage == .child, "6 小时后到 CHILD（\(w.stage.display)）")
check(w.careMistakes == 0, "进化后失误清零（\(w.careMistakes)）")

// 5. 幂等
let a = Simulator.resolve(w, now: plus(start, 60 * 7)).0
let b = Simulator.resolve(a, now: plus(start, 60 * 7)).0
check(a.hunger == b.hunger && a.driveMinutes == b.driveMinutes, "同一时刻重复结算结果一致")

// 6. 睡眠暂停
var s = World.newGame(at: start, tuning: t)
s = Simulator.resolve(s, now: plus(start, 20)).0
let before = s.driveMinutes
s = Simulator.resolve(s, now: date(23, 23, 30)).0
check(s.isAsleep, "23:30 处于睡眠")
let woke = Simulator.resolve(s, now: date(24, 7, 30)).0
check(woke.driveMinutes < 15 * 60, "睡眠的 8 小时没有计入进化计时（睡眠前 \(before) 分 → 醒后 \(woke.driveMinutes) 分）")

// 7. 精心照料 → 0 失误 → AGUMON
var c = World.newGame(at: start, tuning: t)
var now = start
for _ in 0..<(7 * 60) {
    now = plus(now, 1)
    c = Simulator.resolve(c, now: now).0
    if c.stage != .egg && c.hunger < c.maxHearts { c = Simulator.feed(c, at: now) }
    if c.stage != .egg && c.strength < c.maxHearts { c = Simulator.train(c, at: now) }
}
check(c.stage == .child, "精心照料 7 小时到 CHILD（\(c.stage.display)/\(Characters.display(c.species))）")
check(c.careMistakes == 0, "全程照料 0 失误（\(c.careMistakes)）")
check(c.species == "cetal", "0 失误 → AGUMON（\(Characters.display(c.species))）")

// 8. 持续照料 + 训练 ≥32 → GREYMON
var g = c
var gnow = now
// 先补够训练次数
while g.trainCount < 40 {
    gnow = plus(gnow, 1)
    g = Simulator.train(g, at: gnow)
}
check(g.trainCount >= 32, "训练计数累计（\(g.trainCount)）")
// 再按 10 分钟粒度推进到成年，期间照常照料
let target = plus(gnow, 62 * 60)
while gnow < target {
    gnow = plus(gnow, 10)
    g = Simulator.resolve(g, now: gnow).0
    if g.stage != .egg && g.hunger < g.maxHearts { g = Simulator.feed(g, at: gnow) }
    if g.stage != .egg && g.strength < g.maxHearts { g = Simulator.train(g, at: gnow) }
}
check(g.stage == .adult, "持续照料后到 ADULT（\(g.stage.display)）")
check(g.species == "breacher", "0 失误 + 训练 ≥32 → GREYMON（\(Characters.display(g.species)) / 失误 \(g.careMistakes) / 训练 \(g.trainCount)）")

// 9. Perfect 需要战斗积累，不够就不进化
let p = Simulator.resolve(g, now: plus(gnow, 60 * 60)).0
check(p.stage == .adult, "无战斗积累不推进 PERFECT（\(p.stage.display)）")

// 10. 回归：高频刷新不能把世界跑快
var q = World.newGame(at: start, tuning: t)
q = Simulator.resolve(q, now: plus(start, 2)).0
let frozen = q.driveMinutes
for i in 1...5 {
    q = Simulator.resolve(q, now: start.addingTimeInterval(120 + Double(i) * 10)).0
}
check(q.driveMinutes == frozen, "10 秒一次的高频刷新不推进世界（\(frozen) → \(q.driveMinutes)）")
// 再补足到 60 秒，应该只推进 1 分钟
q = Simulator.resolve(q, now: start.addingTimeInterval(180)).0
check(q.driveMinutes == frozen + 1, "跨过整分钟只推进 1 分钟（期望 \(frozen + 1) 实际 \(q.driveMinutes)）")

// 11. 通知预测：下一事件应是饥饿归零的时刻
var n = World.newGame(at: start, tuning: t)
n = Simulator.resolve(n, now: plus(start, 13)).0    // KOROMON, 4 心满
check(n.stage == .baby2 && n.hunger == 4, "预测前置：BABY II 满心")
if let ev = Schedule.nextEvent(world: n, from: n.lastResolvedAt) {
    let minutes = Int(ev.date.timeIntervalSince(n.lastResolvedAt) / 60)
    // 4 心 × 60 分钟 = 240 分钟；期间若跨入睡时段会推后，13:00 起不跨夜
    let expect = 240 - n.hungerAccum
    check(minutes == expect, "下一事件在 \(expect) 分钟后（实际 \(minutes) 分钟：\(ev.title)）")
} else {
    check(false, "预测应返回事件")
}

// 12. 事件时间戳必须是发生时刻，而不是批量结算的时刻
var e = World.newGame(at: start, tuning: t)
let (e1, evs1) = Simulator.resolve(e, now: plus(start, 1))
if let first = evs1.first {
    let delta = first.date.timeIntervalSince(plus(start, 1))
    check(abs(delta) < 0.001, "孵化事件戳在发生的那一分钟（偏差 \(delta) 秒，事件 \(first.event.text)）")
} else {
    check(false, "应产生孵化事件")
}
let (_, evs2) = Simulator.resolve(e1, now: plus(start, 400))
check(evs2.allSatisfy { $0.date <= plus(start, 400) }, "所有事件戳不晚于结算时刻")
check(evs2.contains { $0.date < plus(start, 400) }, "长跨度结算后事件戳仍保留真实时刻")

// 13-16. 三线驱动
var ht = Tuning()
ht.weights = .init(time: 0, health: 1, token: 0)
var h = World.newGame(at: start, tuning: ht)
h = Simulator.resolve(h, now: plus(start, 2)).0
check(h.stage == .baby1, "时间权重 0 时，孵化前仍需时间（\(h.stage.display)）")
h.driveMinutes = 0
let (h2, _) = Simulator.applyHealth(h, steps: 11 * 100, at: plus(start, 3))
check(h2.stage == .baby2, "只靠步数也能推进阶段（\(h2.stage.display)）")

var hh = h2
hh.strength = 1
hh.tuning.weights = .init(time: 0, health: 1, token: 0)
let (h3, _) = Simulator.applyHealth(hh, steps: 3000, at: plus(start, 4))
check(h3.strength >= 2, "3000 步补 1 颗力量心（\(hh.strength) → \(h3.strength)）")

var tk = h2
tk.effort = 0
tk.tuning.weights = .init(time: 0, health: 0, token: 1)
let (tk2, _) = Simulator.applyTokens(tk, tokens: 80000, at: plus(start, 5))
check(tk2.effort > 0, "8 万 token 补努力值（\(tk.effort) → \(tk2.effort)）")
check(tk2.totalTokens == 20000, "单日 token 计入封顶 20000（\(tk2.totalTokens)）")

var cap = h2
cap.tuning.weights = .init(time: 0, health: 0, token: 1)
let (c1, _) = Simulator.applyTokens(cap, tokens: 50000, at: plus(start, 6))
check(c1.tokenDayUsed == 20000, "超额部分不计入（\(c1.tokenDayUsed)）")
let (c2, _) = Simulator.applyTokens(c1, tokens: 5000, at: plus(start, 7))
check(c2.tokenDayUsed == 20000, "同一天继续聊不涨额度（\(c2.tokenDayUsed)）")
let (c3, _) = Simulator.applyTokens(c2, tokens: 3000, at: date(24, 9, 0))
check(c3.tokenDayUsed == 3000, "跨天额度重置（\(c3.tokenDayUsed)）")

var zt = Tuning()
zt.weights = .init(time: 0, health: 0, token: 0)
var z = World.newGame(at: start, tuning: zt)
z = Simulator.resolve(z, now: plus(start, 600)).0
check(z.driveMinutes == 0, "三条线全关时，纯时间不推进进化（\(z.driveMinutes)）")

// 17-19. 战斗
var fighter = World.newGame(at: start, tuning: t)
fighter = Simulator.resolve(fighter, now: plus(start, 13)).0   // KOROMON
fighter.strength = 4

var strong = BattleState.start(world: fighter, roll: 0)
let beforeHP = strong.enemyHP
strong.attack(charge: 1.0, roll: 1, player: fighter)
let highDamage = beforeHP - strong.enemyHP

var weak = BattleState.start(world: fighter, roll: 0)
weak.attack(charge: 0.0, roll: 1, player: fighter)
let lowDamage = beforeHP - weak.enemyHP
check(highDamage > lowDamage, "蓄力越高伤害越大（\(highDamage) vs \(lowDamage)）")

var long = BattleState.start(world: fighter, roll: 2)
for i in 0..<6 where !long.finished {
    long.attack(charge: 0.5, roll: i, player: fighter)
}
check(long.finished, "5 回合内必定结束（实际 \(long.round) 回合）")
check(long.won != nil, "结束后有结果")

var rec = fighter
rec.battles = 3; rec.wins = 1
let (rec2, _) = Simulator.recordBattle(rec, won: false, at: plus(start, 14))
check(rec2.battles == 4 && rec2.wins == 1, "输了记 battles+1、wins 不变（\(rec2.battles)/\(rec2.wins)）")
check(rec2.injured == rec.injured + 1, "输了会受伤（\(rec.injured) → \(rec2.injured)）")

// 20-25. 潮线成人分化与完全体映射
func childWorld(mistakes: Int, train: Int, tokens: Int) -> World {
    var w = World.newGame(at: start, tuning: t)
    w.stage = .child
    w.species = "cetal"
    w.careMistakes = mistakes
    w.trainCount = train
    w.totalTokens = tokens
    return w
}
check(Evolution.species(for: .adult, from: childWorld(mistakes: 4, train: 0, tokens: 0)) == "drift",
      "失养 → 漂雾")
check(Evolution.species(for: .adult, from: childWorld(mistakes: 0, train: 32, tokens: 0)) == "breacher",
      "训练满 → 跃潮")
check(Evolution.species(for: .adult, from: childWorld(mistakes: 0, train: 0, tokens: 6000)) == "abyss",
      "token 深线 → 潜渊")
check(Evolution.species(for: .adult, from: childWorld(mistakes: 0, train: 0, tokens: 0)) == "current",
      "均衡 → 游潮")

var pf = childWorld(mistakes: 0, train: 0, tokens: 0)
pf.species = "breacher"
check(Evolution.species(for: .perfect, from: pf) == "kraken", "跃潮 → 沧主")
pf.species = "current"
check(Evolution.species(for: .perfect, from: pf) == "siren", "游潮 → 歌潮")
pf.species = "abyss"
check(Evolution.species(for: .perfect, from: pf) == "kun", "潜渊 → 鲲")

print(exitCode == 0 ? "\nALL PASS" : "\nHAS FAILURES")
exit(exitCode)
