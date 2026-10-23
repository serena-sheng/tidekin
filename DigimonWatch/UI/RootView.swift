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
            card.frame(height: Grid.rowCard)
            actionBar.frame(height: Grid.rowActions)
        }
        .padding(.horizontal, Grid.margin)
        .padding(.top, 10)
        .digitalCrownRotation(
            $crownValue,
            from: 0, through: Double(Store.actions.count - 1), by: 1,
            sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true
        )
        .onChange(of: crownValue) { _, new in
            let idx = Int(new.rounded())
            if idx != store.selection {
                withAnimation(.easeOut(duration: 0.12)) { store.selection = idx }
                store.noteCrownMove()
                Haptics.tap()
            }
        }
        .onChange(of: store.selection) { _, new in
            if abs(crownValue - Double(new)) > 0.5 { crownValue = Double(new) }
        }
    }

    /// 两行：安静的身份在上，世界的状态在下，字号断层就是层级。
    private var header: some View {
        VStack(alignment: .leading, spacing: 1) {
            Button {
                store.showDetail = true
            } label: {
                Text(worldTitle)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.ink.opacity(0.55))
                    .lineLimit(1)
            }
            .buttonStyle(.plain)

            // 状态词与倒计时同一行：避开状态栏的时钟，也把两件事并成一条视线
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(store.world.headline)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(headlineColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .animation(.easeOut(duration: 0.18), value: store.world.headline)

                Spacer(minLength: 2)

                Text(store.world.progressText)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink.opacity(0.5))
                    .lineLimit(1)
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
        if store.world.isAsleep { return Theme.ink.opacity(0.45) }
        return Theme.ink.opacity(0.92)
    }

    private var card: some View {
        LCDView(world: store.world)
            .overlay(alignment: .bottom) {
                if let toast = store.toast {
                    Text(toast.uppercased())
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.ink.opacity(0.9))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.55), in: Capsule())
                        .padding(.bottom, 10)
                        .transition(.opacity)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { store.perform(store.selection) }
    }

    /// 六格固定：选中＝淡填充，需求＝细环。绿色只在这两处出现。
    private var actionBar: some View {
        HStack(spacing: Grid.actionGap) {
            ForEach(Array(Store.actions.enumerated()), id: \.offset) { index, action in
                cell(index: index, symbol: action.symbol)
            }
        }
    }

    private func cell(index: Int, symbol: String) -> some View {
        let selected = index == store.selection
        let demanded = index == store.demandIndex && !store.actionsDisabled
        let dimmed = store.actionsDisabled

        let iconColor: Color = dimmed ? Theme.lcdDim
            : demanded ? Theme.lcd
            : selected ? Color(red: 0.78, green: 0.93, blue: 0.75)
            : Theme.ink.opacity(0.5)

        return Image(systemName: symbol)
            .font(.system(size: selected ? 16 : 14, weight: .medium))
            .foregroundStyle(iconColor)
            .frame(width: Grid.actionWidth, height: Grid.rowActions)
            .background(
                RoundedRectangle(cornerRadius: Grid.actionRadius, style: .continuous)
                    .fill(selected ? Theme.lcd.opacity(0.16) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Grid.actionRadius, style: .continuous)
                    .strokeBorder(demanded ? Theme.lcd.opacity(0.55) : .clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.12)) { store.selection = index }
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
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.ink.opacity(0.45))
                row("MISS", "\(store.world.careMistakes)")
                row("TRAIN", "\(store.world.trainCount)")
                row("OVRF", "\(store.world.overfeed)")
                row("WKDN", "\(store.world.sleepDisturb)")

                Divider()

                NavigationLink("SETUP") { SettingsView(store: store) }
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
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
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.ink.opacity(0.45))
            Spacer()
            Text(v)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(Theme.ink.opacity(0.85))
        }
    }
}
