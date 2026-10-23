import Foundation
import SwiftUI

@MainActor
final class Store: ObservableObject {
    @Published private(set) var world: World
    @Published var selection: Int = 0
    @Published var toast: String?
    @Published var showDetail = false

    /// 5 个动作，与原机 A/B/C 三键的"功能层"对应
    static let actions: [(symbol: String, label: String)] = [
        ("fork.knife", "FEED"),
        ("figure.strengthtraining.traditional", "TRAIN"),
        ("trash", "CLEAN"),
        ("cross.case", "HEAL"),
        ("info.circle", "INFO"),
    ]

    init() {
        if let loaded = Persistence.load() {
            world = loaded
        } else {
            world = .newGame(at: Date())
        }
    }

    /// 唯一的世界推进入口。幂等，重复调用安全。
    func tick() {
        let (next, events) = Simulator.resolve(world, now: Date())
        let changed = next.lastResolvedAt != world.lastResolvedAt || next.log.count != world.log.count
        world = next
        if let last = events.last { flash(last.text) }
        if changed { Persistence.save(next) }
    }

    func perform(_ index: Int) {
        let now = Date()
        switch index {
        case 0: world = Simulator.feed(world, at: now)
        case 1: world = Simulator.train(world, at: now)
        case 2: world = Simulator.clean(world, at: now)
        case 3: world = Simulator.heal(world, at: now)
        default: showDetail = true; return
        }
        Persistence.save(world)
        Haptics.tap()
    }

    func newGame() {
        world = .newGame(at: Date())
        Persistence.save(world)
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
    static func tap() {
        WKInterfaceDevice.current().play(.click)
    }
    static func chime() {
        WKInterfaceDevice.current().play(.success)
    }
}
