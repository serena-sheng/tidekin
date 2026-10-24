import Foundation
import SwiftUI
import WatchKit

/// 离开期间发生的事。低于 2 小时不出摘要。
struct AwaySummary: Identifiable {
    let id = UUID()
    let duration: TimeInterval
    let lines: [String]
    let evolvedTo: String?
    let died: Bool

    var title: String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        if h > 0 { return "WHILE YOU WERE AWAY · \(h)h \(m)m" }
        return "WHILE YOU WERE AWAY · \(m)m"
    }
}

@MainActor
final class Store: ObservableObject {
    @Published private(set) var world: World
    @Published var page: Int = 0
    @Published var toast: String?
    @Published var showSettings = false
    @Published var showRecords = false
    @Published var showChat = false
    @Published var showBattle = false
    @Published var battle: BattleState?

    // 摘要 / 死亡
    @Published var away: AwaySummary?
    @Published var newEggArmed = false

    // 聊天
    @Published var chatLog: [(role: String, text: String)] = []
    @Published var needsConsent = false
    @Published var isThinking = false
    @Published var chatError: String?

    private var lastScheduled: Date?
    private var askedForNotifications = false
    private var pendingAway: TimeInterval?
    private var toastQueue: [String] = []
    private var toastToken = 0

    enum Action: Int, CaseIterable {
        case feed, train, clean, heal, battle, talk

        var symbol: String {
            switch self {
            case .feed: return "fork.knife"
            case .train: return "dumbbell.fill"
            case .clean: return "sparkles"
            case .heal: return "cross.case"
            case .battle: return "burst.fill"
            case .talk: return "bubble.left.and.bubble.right"
            }
        }

        var label: String {
            switch self {
            case .feed: return "FEED"
            case .train: return "TRAIN"
            case .clean: return "CLEAN"
            case .heal: return "HEAL"
            case .battle: return "FIGHT"
            case .talk: return "TALK"
            }
        }
    }

    init() {
        if let loaded = Persistence.load() {
            world = loaded
            let away = Date().timeIntervalSince(loaded.lastResolvedAt)
            if away > 2 * 3600 { pendingAway = away }
        } else {
            world = .newGame(at: Date())
        }
    }

    // MARK: - 派生

    /// 世界在要哪一个动作。与 selection（游标）区分开。
    var demandIndex: Int? {
        switch world.demand {
        case .feed: return Action.feed.rawValue
        case .train: return Action.train.rawValue
        case .clean: return Action.clean.rawValue
        case .heal: return Action.heal.rawValue
        case .none: return nil
        }
    }

    /// 蛋和睡眠时整个动作栏都无效
    var actionsDisabled: Bool {
        world.isDead || world.isAsleep || world.stage == .egg
    }

    // MARK: - 世界推进

    func tick() {
        let (next, events) = Simulator.resolve(world, now: Date())
        let changed = next.lastResolvedAt != world.lastResolvedAt || next.log.count != world.log.count
        world = next
        if changed { Persistence.save(next) }

        if let awayFor = pendingAway {
            pendingAway = nil
            buildAwaySummary(awayFor: awayFor, events: events)
        } else if let last = events.last {
            flash(last.event.text, world: true)
        }

        rescheduleIfNeeded()
    }

    private func buildAwaySummary(awayFor: TimeInterval, events: [TimedEvent]) {
        var lines: [String] = []
        var evolvedTo: String?
        var died = false
        for e in events {
            switch e.event {
            case .evolved(_, let to): evolvedTo = to
            case .died: died = true
            case .careMistake: lines.append("care mistake")
            case .pooped: break
            case .injured: lines.append("injured")
            default: break
            }
        }
        // 只留三条，同类合并
        var summary: [String] = []
        let mistakes = lines.filter { $0 == "care mistake" }.count
        let injuries = lines.filter { $0 == "injured" }.count
        if evolvedTo != nil { summary.append("evolved") }
        if mistakes > 0 { summary.append("\(mistakes) care mistake\(mistakes > 1 ? "s" : "")") }
        if injuries > 0 { summary.append("\(injuries) injur\(injuries > 1 ? "ies" : "y")") }
        if died { summary.insert("returned to data", at: 0) }

        if summary.isEmpty && !died && evolvedTo == nil { return }
        away = AwaySummary(duration: awayFor,
                           lines: Array(summary.prefix(3)),
                           evolvedTo: evolvedTo,
                           died: died)
    }

    /// 点宠物本体：只回应它此刻的需求，没有需求就不动。
    /// 原来是 perform(selection)，而 selection 恒为 0，等于隐形过量喂食。
    func tapCreature() {
        guard let demand = demandIndex else { return }
        perform(demand)
    }

    func perform(_ index: Int) {
        guard !actionsDisabled else {
            if world.isAsleep { flash("ASLEEP · WAKES 07:00", world: false) }
            else if world.stage == .egg { flash("HATCHING", world: false) }
            Haptics.tap()
            return
        }

        let action = Action(rawValue: index) ?? .feed
        let now = Date()
        switch action {
        case .feed: world = Simulator.feed(world, at: now)
        case .train: world = Simulator.train(world, at: now)
        case .clean: world = Simulator.clean(world, at: now)
        case .heal: world = Simulator.heal(world, at: now)
        case .battle: startBattle(); return
        case .talk: showChat = true; return
        }
        Persistence.save(world)
        rescheduleIfNeeded(force: true)
        Haptics.tap()
        if !askedForNotifications {
            askedForNotifications = true
            Notifier.requestPermission()
        }
    }

    func rescheduleIfNeeded(force: Bool = false) {
        let now = Date()
        if !force, let last = lastScheduled, now.timeIntervalSince(last) < 300 { return }
        lastScheduled = now
        Notifier.reschedule(for: world, now: now)
    }

    // MARK: - 战斗

    func startBattle() {
        guard !world.isDead, !world.isAsleep, world.stage != .egg else { return }
        battle = BattleState.start(world: world, roll: Int(Date().timeIntervalSince1970))
        showBattle = true
    }

    func battleAttack(charge: Double) {
        guard var b = battle, !b.finished else { return }
        b.attack(charge: charge, roll: Int.random(in: 0...99), player: world)
        battle = b
        guard b.finished else { return }

        let (next, events) = Simulator.recordBattle(world, won: b.won == true, at: Date())
        world = next
        Persistence.save(next)
        rescheduleIfNeeded(force: true)
        if let last = events.last { flash(last.event.text, world: true) }
    }

    // MARK: - 健康 / token

    private var stepsKey: String {
        "health.steps.\(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)"
    }

    func syncHealth() async {
        guard HealthSource.isAvailable else { return }
        let steps = await HealthSource.stepsToday()
        let recorded = UserDefaults.standard.integer(forKey: stepsKey)
        let delta = steps - recorded
        guard delta > 0 else { return }
        UserDefaults.standard.set(steps, forKey: stepsKey)

        let (next, events) = Simulator.applyHealth(world, steps: delta, at: Date())
        world = next
        Persistence.save(next)
        rescheduleIfNeeded(force: true)
        if let last = events.last { flash(last.event.text, world: true) }
    }

    func applyTokenDelta(_ delta: Int) {
        let (next, events) = Simulator.applyTokens(world, tokens: delta, at: Date())
        world = next
        Persistence.save(next)
        rescheduleIfNeeded(force: true)
        if let last = events.last { flash(last.event.text, world: true) }
    }

    // MARK: - 对话

    // MARK: - 对话前的同意与内容把关

    private static let consentKey = "consent.talk.accepted"

    var hasConsented: Bool { UserDefaults.standard.bool(forKey: Self.consentKey) }

    func acceptConsent() {
        UserDefaults.standard.set(true, forKey: Self.consentKey)
        needsConsent = false
    }

    /// 最低限度的输出把关。模型仍可能出错，所以同时提供举报入口。
    private static let blockedTerms = [
        "自杀", "自残", "制毒", "爆炸物", "儿童色情", "强奸",
    ]

    static func filtered(_ text: String) -> String? {
        let lowered = text.lowercased()
        for term in blockedTerms where lowered.contains(term) {
            return nil
        }
        return text
    }

    /// 举报留证：watchOS 没有剪贴板，把最近一轮原文追加到 App Group 的 reports.log，
    /// 设置页可以看到条数。真要走申诉时从容器里取。
    func reportLastExchange() {
        let recent = chatLog.suffix(4).map { "\($0.role): \($0.text)" }.joined(separator: "\n")
        let url = Persistence.url
            .deletingLastPathComponent()
            .appendingPathComponent("reports.log")
        var content = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        content += "[\(ISO8601DateFormatter().string(from: Date()))]\n\(recent)\n\n"
        try? content.write(to: url, atomically: true, encoding: .utf8)
        flash("已记录这次对话")
    }

    var reportCount: Int {
        let url = Persistence.url
            .deletingLastPathComponent()
            .appendingPathComponent("reports.log")
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return 0 }
        return text.components(separatedBy: "\n[").count - 1
    }

    func ask(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isThinking else { return }
        guard hasConsented else {
            needsConsent = true
            return
        }
        guard let key = Keychain.get(Keychain.deepSeekKey), !key.isEmpty else {
            chatError = "先在设置里填 API Key"
            return
        }

        chatLog.append((role: "user", text: trimmed))
        isThinking = true
        chatError = nil

        var messages: [DeepSeekClient.Message] = [DeepSeekClient.persona(for: world)]
        for entry in chatLog.suffix(6) {
            messages.append(.init(role: entry.role, content: entry.text))
        }

        do {
            let reply = try await DeepSeekClient(apiKey: key).chat(messages)
            let safe = Self.filtered(reply.text) ?? "（这条回复被拦截了，可以点举报把问题发给我）"
            chatLog.append((role: "assistant", text: safe))
            if reply.tokens > 0 { applyTokenDelta(reply.tokens) }
        } catch {
            chatError = error.localizedDescription
        }
        isThinking = false
    }

    // MARK: - 重生

    func tapNewEgg() {
        if newEggArmed {
            world = .newGame(at: Date())
            page = 0
            Persistence.save(world)
            newEggArmed = false
            away = nil
            rescheduleIfNeeded(force: true)
        } else {
            newEggArmed = true
        }
    }

    func dismissAway() { away = nil }

    // MARK: - 提示队列

    func setTuning(_ tuning: Tuning) {
        world.tuning = tuning
        // 睡眠是派生状态，改完参数要立刻重算，否则要等下一分钟才生效
        world.isAsleep = Simulator.isSleepHour(Date(), tuning: tuning)
        Persistence.save(world)
    }

    func updateWeights(_ weights: Tuning.DriveWeights) {
        world.tuning.weights = weights
        Persistence.save(world)
    }

    /// 玩家动作触发的提示不排队，直接占屏；世界事件排到后面，避免被便便顶掉进化。
    func flash(_ text: String, world isWorldEvent: Bool) {
        if isWorldEvent, toast != nil {
            toastQueue.append(text)
            return
        }
        show(text)
    }

    func flash(_ text: String) { flash(text, world: false) }

    private func show(_ text: String) {
        toastToken += 1
        let token = toastToken
        toast = text
        Task {
            try? await Task.sleep(for: .seconds(2))
            guard toastToken == token else { return }
            if toastQueue.isEmpty {
                toast = nil
            } else {
                let next = toastQueue.removeFirst()
                show(next)
            }
        }
    }

}

enum Haptics {
    static func tap() { WKInterfaceDevice.current().play(.click) }
}
