import SwiftUI
import WatchKit

struct RootView: View {
    @StateObject private var store = Store()
    @State private var crownValue: Double = 0
    @Environment(\.scenePhase) private var phase

    var body: some View {
        Group {
            if store.world.isDead {
                GoneView(store: store)
            } else {
                mainScreen
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black)
        .sheet(item: $store.away) { summary in
            AwaySummaryView(summary: summary, store: store)
        }
        .sheet(isPresented: $store.showDetail) {
            NavigationStack { DetailView(store: store) }
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
            store.tick()
            await store.syncHealth()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                store.tick()
            }
        }
    }

    // MARK: - 主屏

    private var mainScreen: some View {
        VStack(spacing: Grid.gap) {
            header.frame(height: Grid.rowHeader, alignment: .top)
            lcd.frame(height: Grid.rowScreen)
            meters.frame(height: Grid.rowMeters, alignment: .center)
            actionBar.frame(height: Grid.rowActions)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .digitalCrownRotation(
            $crownValue,
            from: 0, through: Double(Store.actions.count - 1), by: 1,
            sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true
        )
        .onChange(of: crownValue) { _, new in
            let idx = Int(new.rounded())
            if idx != store.selection {
                store.selection = idx
                store.noteCrownMove()
                Haptics.tap()
            }
        }
        .onChange(of: store.selection) { _, new in
            if abs(crownValue - Double(new)) > 0.5 { crownValue = Double(new) }
        }
    }

    /// 第一行是安静的身份，第二行是世界在说什么，右边是还差多久。
    private var header: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Button {
                    store.showDetail = true
                } label: {
                    Text(worldTitle)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.ink.opacity(0.6))
                        .lineLimit(1)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 2)

                Text(store.world.progressText)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink.opacity(0.65))
                    .lineLimit(1)
            }
            HStack(alignment: .firstTextBaseline) {
                Text(store.world.headline)
                    .font(.system(size: 15, weight: .heavy, design: .monospaced))
                    .foregroundStyle(headlineColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 4)
                if store.world.stage != .egg {
                    Text(store.selectedAction.label)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.ink.opacity(0.35))
                }
            }
        }
    }

    private var worldTitle: String {
        if store.world.stage == .egg { return "DIGIEGG" }
        return "\(store.world.species) · \(store.world.stage.display)"
    }

    private var headlineColor: Color {
        switch store.world.demand {
        case .feed, .train, .clean, .heal: return Theme.warn
        case .none: break
        }
        if store.world.isAsleep { return Theme.ink.opacity(0.35) }
        if store.world.stage == .egg { return Theme.ink.opacity(0.6) }
        // 正常态用白字：绿色是稀缺资源，只给"需要你"和交互
        return Theme.ink.opacity(0.95)
    }

    private var lcd: some View {
        LCDView(world: store.world)
            .frame(height: 110)
            .overlay(alignment: .bottom) {
                if let toast = store.toast {
                    Text(toast.uppercased())
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.lcd)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.85), in: Capsule())
                        .padding(.bottom, 8)
                        .transition(.opacity)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { store.perform(store.selection) }
    }

    @ViewBuilder
    private var meters: some View {
        if store.world.stage == .egg {
            VStack(spacing: 1) {
                Text("THIS IS YOUR DIGIEGG")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.ink.opacity(0.4))
                Text("HATCHES IN A MINUTE")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Theme.ink.opacity(0.25))
            }
            .frame(height: 22)
        } else {
            VStack(spacing: 1) {
                SegmentMeter(glyph: "♥", value: store.world.hunger, maxValue: store.world.maxHearts)
                SegmentMeter(glyph: "⚡", value: store.world.strength, maxValue: store.world.maxHearts)
            }
        }
    }

    /// 六格位置永远固定，只换视觉：选中是描边，推荐是底色。
    private var actionBar: some View {
        HStack(spacing: 3) {
            ForEach(Array(Store.actions.enumerated()), id: \.offset) { index, action in
                cell(index: index, symbol: action.symbol)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func cell(index: Int, symbol: String) -> some View {
        let selected = index == store.selection
        let demanded = index == store.demandIndex && !store.actionsDisabled
        let dimmed = store.actionsDisabled

        let iconColor: Color = dimmed ? Theme.lcdDim
            : (selected || demanded) ? Theme.lcd
            : Theme.ink.opacity(0.55)

        // 圆角矩形回归：选中用细描边，推荐用淡底。两者都不铺满，绿色不泛滥
        let fieldColor: Color = demanded ? Theme.lcd.opacity(0.15)
            : selected ? Theme.ink.opacity(0.07)
            : .clear

        return Image(systemName: symbol)
            .font(.system(size: selected ? 15 : 13, weight: .semibold))
            .foregroundStyle(iconColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous).fill(fieldColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(selected ? Theme.lcd : .clear, lineWidth: 1)
            )
            .onTapGesture {
                store.selection = index
                store.noteCrownMove()
                store.perform(index)
            }
    }
}

// MARK: - 详情

struct DetailView: View {
    @ObservedObject var store: Store
    @State private var askedNotifications = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                row("STAGE", store.world.stage.display)
                row("AGE", String(format: "%.1f h", store.world.ageHours))
                row("WEIGHT", "\(store.world.weight) g")
                row("EFFORT", String(format: "%.2f", store.world.effort))
                row("BATTLES", "\(store.world.wins)/\(store.world.battles)")
                row("INJURY", "\(store.world.injured)/20")
                row("NEXT", nextText)

                Divider().padding(.vertical, 2)

                Text("HIDDEN")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
                row("MISS", "\(store.world.careMistakes)")
                row("TRAIN", "\(store.world.trainCount)")
                row("OVRF", "\(store.world.overfeed)")
                row("WKDN", "\(store.world.sleepDisturb)")

                Divider()

                NavigationLink("SETUP") { SettingsView(store: store) }
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tint(Theme.lcd)
            }
            .padding(.horizontal, 4)
        }
        .onAppear {
            if !askedNotifications {
                askedNotifications = true
                Notifier.requestPermission()
            }
        }
    }

    private var nextText: String {
        if let need = store.world.battlesToPerfect, need > 0 {
            return "\(need) FIGHTS"
        }
        guard let m = store.world.minutesToEvolution, let next = store.world.nextStage else {
            return "MAX"
        }
        return m < 60 ? "\(next.display) \(m)m" : "\(next.display) \(m / 60)h"
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
            Spacer()
            Text(v)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .monospacedDigit()
        }
    }
}
