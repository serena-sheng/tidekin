import SwiftUI
import WatchKit

struct RootView: View {
    @StateObject private var store = Store()
    @Environment(\.scenePhase) private var phase

    var body: some View {
        Group {
            if store.world.isDead {
                GoneView(store: store)
            } else {
                pages
            }
        }
        .sheet(item: $store.away) { summary in
            AwaySummaryView(summary: summary, store: store)
        }
        .sheet(isPresented: $store.showChat) {
            NavigationStack { ChatView(store: store) }
        }
        .sheet(isPresented: $store.showBattle) {
            BattleView(store: store)
        }
        .onChange(of: phase) { _, new in
            if new == .active { store.tick() }
        }
        .task {
            if UserDefaults.standard.bool(forKey: "debugBattle") { store.startBattle() }
            if UserDefaults.standard.object(forKey: "debugPage") != nil {
                store.page = UserDefaults.standard.integer(forKey: "debugPage")
            }
            store.tick()
            await store.syncHealth()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                store.tick()
            }
        }
    }

    /// 三页：伴侣（美术）→ 状态（数据）→ 记录（低频）。
    /// Crown 用来翻页，这是 watchOS 的既定语法；动作改成点按直接执行。
    private var pages: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $store.page) {
                CompanionPage(store: store).tag(0)
                StatusPage(store: store).tag(1)
                RecordsPage(store: store).tag(2)
            }
            .tabViewStyle(.verticalPage)

            // 世界事件与玩家动作的反馈挂在三页之外，翻到哪一页都看得见
            if let toast = store.toast {
                Text(toast.uppercased())
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.ink.opacity(0.92))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.72), in: Capsule())
                    .padding(.bottom, 6)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .containerBackground(for: .tabView) { Color.black }
    }
}

// MARK: - 第一页：伴侣

/// 第一屏只做一件事：让宠物成为画面本身。
struct CompanionPage: View {
    @ObservedObject var store: Store

    var body: some View {
        VStack(spacing: 0) {
            Text(store.world.headline)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(headlineColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.easeOut(duration: 0.18), value: store.world.headline)

            LCDView(world: store.world, showMeters: false, spriteMax: 140)
                .frame(maxHeight: .infinity)
                .padding(.top, 7)
                .contentShape(Rectangle())
                .onTapGesture { store.tapCreature() }

            actionBar
                .padding(.top, 9)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, Grid.margin)
        .padding(.top, 2)
        .padding(.bottom, 2)
    }

    private var headlineColor: Color {
        switch store.world.demand {
        case .feed, .train, .clean, .heal: return Theme.warn
        case .none: break
        }
        if store.world.isAsleep { return Theme.ink.opacity(0.55) }
        return Theme.ink.opacity(0.6)
    }

    /// 动作串：横向可滑，一屏露出约 2.8 个。
    /// 既满足「一行最多 3 个」的可见密度，又不用翻页找次要动作。
    private var actionBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Store.Action.allCases, id: \.rawValue) { action in
                    cell(action)
                        .frame(width: 54)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: Grid.rowActions)
    }

    private func cell(_ action: Store.Action) -> some View {
        let demanded = action.rawValue == store.demandIndex && !store.actionsDisabled
        let dimmed = store.actionsDisabled

        let iconColor: Color = dimmed ? Theme.ink.opacity(0.3)
            : demanded ? Theme.lcd
            : Theme.ink.opacity(0.72)

        return Button {
            store.perform(action.rawValue)
        } label: {
            Image(systemName: action.symbol)
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(maxWidth: .infinity)
                .frame(height: Grid.rowActions)
                .background(
                    RoundedRectangle(cornerRadius: Grid.actionRadius, style: .continuous)
                        .fill(demanded ? Theme.lcd.opacity(0.16) : Theme.ink.opacity(0.07))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Grid.actionRadius, style: .continuous)
                        .strokeBorder(demanded ? Theme.lcd.opacity(0.55) : .clear, lineWidth: 1)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(action.label)
    }
}

/// 按压态：HIG 要求自定义按钮必须有可见反馈。
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 第二页：状态

struct StatusPage: View {
    @ObservedObject var store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if store.world.stage == .egg {
                Text("HATCHING")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.ink.opacity(0.55))
                    .padding(.top, 16)
            } else if store.world.isAsleep {
                Text("ASLEEP · WAKES 07:00")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.ink.opacity(0.55))
                    .padding(.top, 16)
            } else {
                VStack(spacing: 7) {
                    bigMeter(glyph: "♥", value: store.world.hunger, label: "HUNGER")
                    bigMeter(symbol: "bolt.fill", value: store.world.strength, label: "POWER")
                }
                .padding(.top, 10)
            }

            Spacer(minLength: 8)

            Divider().opacity(0.15).padding(.bottom, 9)

            VStack(spacing: 5) {
                row("BATTLES", "\(store.world.wins)/\(store.world.battles)")
                row("NEXT", nextText)
            }
            .padding(.bottom, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, Grid.margin)
        .padding(.top, 2)
    }

    private var stageLine: String {
        if store.world.stage == .egg { return "DIGIEGG" }
        let h = String(format: "%.0f", store.world.ageHours)
        return "\(store.world.stage.display) · \(h)h · \(store.world.weight)g"
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(stageLine)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.ink.opacity(0.55))
            Text(store.world.species)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func bigMeter(glyph: String? = nil, symbol: String? = nil,
                          value: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                if let glyph {
                    Text(glyph)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.ink.opacity(0.55))
                }
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.ink.opacity(0.55))
                }
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.ink.opacity(0.55))
                Spacer(minLength: 0)
                Text("\(value)/\(store.world.maxHearts)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink.opacity(0.75))
            }
            SegmentMeter(glyph: "", value: value, maxValue: store.world.maxHearts, glyphWidth: 0)
                .frame(height: 8)
        }
    }

    /// 战斗与治疗放这一页：打不打要看力量，治不治要看伤，判断依据都在这屏。
    private var actionRow: some View {
        HStack(spacing: 6) {
            actionButton(.battle)
            actionButton(.heal)
        }
    }

    private func actionButton(_ action: Store.Action) -> some View {
        let demanded = action.rawValue == store.demandIndex && !store.actionsDisabled
        return Button {
            store.perform(action.rawValue)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: action.symbol)
                    .font(.system(size: 15, weight: .medium))
                Text(action.label)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(demanded ? Theme.lcd : Theme.ink.opacity(0.75))
            .frame(maxWidth: .infinity)
            .frame(height: Grid.rowActions)
            .background(
                RoundedRectangle(cornerRadius: Grid.actionRadius, style: .continuous)
                    .fill(demanded ? Theme.lcd.opacity(0.16) : Theme.ink.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Grid.actionRadius, style: .continuous)
                    .strokeBorder(demanded ? Theme.lcd.opacity(0.55) : .clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(action.label)
    }

    private var nextText: String {
        if let need = store.world.battlesToPerfect, need > 0 {
            return "\(need) fights"
        }
        guard let m = store.world.minutesToEvolution, let next = store.world.nextStage else {
            return "max"
        }
        return m < 60 ? "\(next.display) \(m)m" : "\(next.display) \(m / 60)h"
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.ink.opacity(0.55))
            Spacer()
            Text(v)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(Theme.ink.opacity(0.85))
        }
    }
}

// MARK: - 第三页：记录与入口

struct RecordsPage: View {
    @ObservedObject var store: Store

    private var hasRecords: Bool {
        let w = store.world
        return w.careMistakes + w.trainCount + w.overfeed + w.sleepDisturb + w.totalTokens > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("RECORDS")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.ink.opacity(0.55))
                .padding(.bottom, 10)

            if hasRecords {
                VStack(spacing: 6) {
                    row("MISS", "\(store.world.careMistakes)")
                    row("TRAIN", "\(store.world.trainCount)")
                    row("OVRFEED", "\(store.world.overfeed)")
                    row("TOKENS", "\(store.world.totalTokens)")
                }
            } else {
                Text("NO RECORDS YET")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.ink.opacity(0.4))
            }

            Spacer(minLength: 8)

            Button {
                store.showChat = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: Store.Action.talk.symbol)
                        .font(.system(size: 15, weight: .medium))
                    Text("TALK")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                }
                .frame(maxWidth: .infinity)
                .frame(height: Grid.rowActions)
                .background(Theme.ink.opacity(0.07),
                            in: RoundedRectangle(cornerRadius: Grid.actionRadius, style: .continuous))
                .foregroundStyle(Theme.ink.opacity(0.75))
            }
            .buttonStyle(PressableStyle())
            .padding(.bottom, 6)

            Button {
                store.showSettings = true
            } label: {
                Text("SETUP")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Theme.panel, in: Capsule())
                    .foregroundStyle(Theme.ink.opacity(0.85))
            }
            .buttonStyle(PressableStyle())
            .sheet(isPresented: $store.showSettings) {
                NavigationStack { SettingsView(store: store) }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, Grid.margin)
        .padding(.top, 2)
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.ink.opacity(0.55))
            Spacer()
            Text(v)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(Theme.ink.opacity(0.85))
        }
    }
}
