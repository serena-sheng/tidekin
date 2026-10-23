import SwiftUI
import WatchKit

struct RootView: View {
    @StateObject private var store = Store()
    @State private var crownValue: Double = 0
    @Environment(\.scenePhase) private var phase

    var body: some View {
        VStack(spacing: 6) {
            header
            LCDView(world: store.world)
                .overlay(alignment: .bottom) {
                    if let toast = store.toast {
                        Text(toast.uppercased())
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.lcd)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.8), in: Capsule())
                            .padding(.bottom, 8)
                            .transition(.opacity)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { store.perform(store.selection) }
                .onLongPressGesture { store.startBattle() }
            meters
            actionBar
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.black)
        .digitalCrownRotation(
            $crownValue,
            from: 0, through: Double(Store.actions.count - 1), by: 1,
            sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true
        )
        .onChange(of: crownValue) { _, new in
            let idx = Int(new.rounded())
            if idx != store.selection {
                store.selection = idx
                Haptics.tap()
            }
        }
        .onChange(of: store.selection) { _, new in
            if abs(crownValue - Double(new)) > 0.5 { crownValue = Double(new) }
        }
        .onChange(of: phase) { _, new in
            if new == .active { store.tick() }
        }
        .task {
            // 调试用：xcrun simctl launch <dev> <bundle> -debugBattle YES
            if UserDefaults.standard.bool(forKey: "debugBattle") {
                store.startBattle()
            }
            store.tick()
            await store.syncHealth()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                store.tick()
            }
        }
        .sheet(isPresented: $store.showDetail) {
            DetailView(store: store)
        }
        .sheet(isPresented: $store.showChat) {
            NavigationStack { ChatView(store: store) }
        }
        .sheet(isPresented: $store.showBattle) {
            BattleView(store: store)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(store.world.species)
                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if store.world.stage != .egg {
                Text(store.world.stage.display)
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.ink.opacity(0.3))
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Text(store.world.mood)
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundStyle(moodColor)
        }
    }

    private var moodColor: Color {
        switch store.world.mood {
        case "CALLING", "HURT", "GONE": return Theme.danger
        case "HUNGRY", "PECKISH", "SMELLY": return Theme.warn
        default: return Theme.lcd
        }
    }

    @ViewBuilder
    private var meters: some View {
        if store.world.stage == .egg {
            Text("HATCHING...")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.ink.opacity(0.25))
                .frame(height: 20)
        } else {
            VStack(spacing: 2) {
                HeartMeter(label: "HNG", value: store.world.hunger, maxValue: store.world.maxHearts)
                HeartMeter(label: "PWR", value: store.world.strength, maxValue: store.world.maxHearts)
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 3) {
            ForEach(Array(Store.actions.enumerated()), id: \.offset) { index, action in
                let selected = index == store.selection
                Image(systemName: action.symbol)
                    .font(.system(size: selected ? 15 : 12, weight: .semibold))
                    .foregroundStyle(selected ? Color.black : Theme.ink.opacity(0.5))
                    .frame(width: 25, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(selected ? Theme.lcd : Theme.panel)
                    )
                    .onTapGesture {
                        store.selection = index
                        store.perform(index)
                    }
            }
        }
        .padding(.top, 2)
    }
}

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
                row("BATTLES", "\(store.world.battles)")
                row("INJURY", "\(store.world.injured)/20")
                row("NEXT", nextEvolutionText)

                Divider().padding(.vertical, 2)

                Text("HIDDEN")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
                row("MISS", "\(store.world.careMistakes)")
                row("TRAIN", "\(store.world.trainCount)")
                row("OVRF", "\(store.world.overfeed)")
                row("WKDN", "\(store.world.sleepDisturb)")

                Button {
                    store.showDetail = false
                    store.startBattle()
                } label: {
                    Label("BATTLE", systemImage: "bolt.fill")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .buttonStyle(.bordered)
                .tint(Theme.warn)

                HStack {
                    Text("BATTLES")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(store.world.wins)/\(store.world.battles)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                }

                NavigationLink("SETUP") { SettingsView(store: store) }
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tint(Theme.lcd)

                Button("NEW EGG") { store.newGame() }
                    .buttonStyle(.bordered)
                    .tint(Theme.danger)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 4)
        }
        .onAppear {
            // 进详情页才要通知权限：先让用户看到宠物，再谈提醒
            if !askedNotifications {
                askedNotifications = true
                Notifier.requestPermission()
            }
        }
    }

    private var nextEvolutionText: String {
        guard let m = store.world.minutesToEvolution, let next = store.world.nextStage else {
            return "MAX"
        }
        if m < 60 { return "\(next.display) \(m)m" }
        return "\(next.display) \(m / 60)h"
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
            Spacer()
            Text(v)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
        }
    }
}
