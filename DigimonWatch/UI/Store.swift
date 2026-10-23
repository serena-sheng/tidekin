import Foundation
import SwiftUI
import WatchKit

@MainActor
final class Store: ObservableObject {
    @Published private(set) var world: World
    @Published var selection: Int = 0
    @Published var toast: String?
    @Published var showDetail = false
    @Published var showChat = false

    // 聊天
    @Published var chatLog: [(role: String, text: String)] = []
    @Published var isThinking = false
    @Published var chatError: String?

    private var lastScheduled: Date?

    static let actions: [(symbol: String, label: String)] = [
        ("fork.knife", "FEED"),
        ("figure.strengthtraining.traditional", "TRAIN"),
        ("trash", "CLEAN"),
        ("cross.case", "HEAL"),
        ("bubble.left.and.bubble.right", "TALK"),
        ("chart.bar", "STATS"),
    ]

    init() {
        if let loaded = Persistence.load() {
            world = loaded
        } else {
            world = .newGame(at: Date())
        }
    }

    // MARK: - 世界推进

    func tick() {
        let (next, events) = Simulator.resolve(world, now: Date())
        let changed = next.lastResolvedAt != world.lastResolvedAt || next.log.count != world.log.count
        world = next
        if let last = events.last { flash(last.event.text) }
        if changed { Persistence.save(next) }
        rescheduleIfNeeded()
    }

    func perform(_ index: Int) {
        let now = Date()
        switch index {
        case 0: world = Simulator.feed(world, at: now)
        case 1: world = Simulator.train(world, at: now)
        case 2: world = Simulator.clean(world, at: now)
        case 3: world = Simulator.heal(world, at: now)
        case 4: showChat = true; return
        default: showDetail = true; return
        }
        Persistence.save(world)
        rescheduleIfNeeded(force: true)
        Haptics.tap()
    }

    func rescheduleIfNeeded(force: Bool = false) {
        let now = Date()
        if !force, let last = lastScheduled, now.timeIntervalSince(last) < 300 { return }
        lastScheduled = now
        Notifier.reschedule(for: world, now: now)
    }

    // MARK: - 健康线

    private var stepsKey: String { "health.steps.\(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)" }

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
        if let last = events.last { flash(last.event.text) }
    }

    // MARK: - Token 线（只统计手表内对话消耗）

    func applyTokenDelta(_ delta: Int) {
        let (next, events) = Simulator.applyTokens(world, tokens: delta, at: Date())
        world = next
        Persistence.save(next)
        rescheduleIfNeeded(force: true)
        if let last = events.last { flash(last.event.text) }
    }

    // MARK: - 对话

    func ask(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isThinking else { return }
        guard let key = Keychain.get(Keychain.deepSeekKey), !key.isEmpty else {
            chatError = "先在设置里填 DeepSeek API Key"
            return
        }

        chatLog.append((role: "user", text: trimmed))
        isThinking = true
        chatError = nil

        var messages: [DeepSeekClient.Message] = [
            DeepSeekClient.persona(for: world)
        ]
        // 只带最近 6 轮，手表屏幕小、token 也省
        for entry in chatLog.suffix(6) {
            messages.append(.init(role: entry.role, content: entry.text))
        }

        do {
            let reply = try await DeepSeekClient(apiKey: key).chat(messages)
            chatLog.append((role: "assistant", text: reply.text))
            // 闭环：跟它说话本身就消耗 token，本身就会喂它
            if reply.tokens > 0 { applyTokenDelta(reply.tokens) }
        } catch {
            chatError = error.localizedDescription
        }
        isThinking = false
    }

    // MARK: -

    func updateWeights(_ weights: Tuning.DriveWeights) {
        world.tuning.weights = weights
        Persistence.save(world)
    }

    func newGame() {
        world = .newGame(at: Date())
        Persistence.save(world)
        rescheduleIfNeeded(force: true)
        showDetail = false
    }

    func flash(_ text: String) {
        toast = text
        Task {
            try? await Task.sleep(for: .seconds(2))
            if toast == text { toast = nil }
        }
    }
}

enum Haptics {
    static func tap() { WKInterfaceDevice.current().play(.click) }
    static func chime() { WKInterfaceDevice.current().play(.success) }
}
