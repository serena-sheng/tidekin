import SwiftUI

struct BattleView: View {
    @ObservedObject var store: Store
    @State private var charge: Double = 0
    @Environment(\.dismiss) private var dismiss

    private var battle: BattleState? { store.battle }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let b = battle {
                VStack(spacing: 6) {
                    enemyRow(b)
                    enemySprite(b)

                    if b.finished {
                        resultBlock(b)
                    } else {
                        chargeBar
                    }

                    playerRow(b)
                    footer(b)
                }
                .padding(.horizontal, 8)
                .padding(.top, 12)
                .padding(.bottom, 4)
            }
        }
        .digitalCrownRotation(
            $charge, from: 0, through: 1, by: 0.05,
            sensitivity: .medium, isContinuous: false, isHapticFeedbackEnabled: true
        )
        .contentShape(Rectangle())
        .onTapGesture {
            guard let b = battle, !b.finished else { return }
            store.battleAttack(charge: charge)
            charge = 0
            Haptics.tap()
        }
        .task {
            if store.battle == nil { store.startBattle() }
        }
    }

    private func enemyRow(_ b: BattleState) -> some View {
        VStack(spacing: 2) {
            HStack {
                Text(b.enemy.name)
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(b.round)/\(BattleState.maxRounds)")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Theme.ink.opacity(0.3))
            }
            bar(value: b.enemyHP, max: 20 + b.enemy.power * 6, color: Theme.danger)
        }
    }

    private func enemySprite(_ b: BattleState) -> some View {
        Group {
            if let img = SpriteStore.image(for: b.enemy.sprite.uppercased()) {
                Image(uiImage: img)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            } else {
                Text(b.enemy.name.prefix(3))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.lcd)
            }
        }
        .frame(height: 72)
        .opacity(b.finished && b.won == true ? 0.25 : 1)
    }

    private var chargeBar: some View {
        VStack(spacing: 3) {
            Text("转动表冠蓄力，点一下出击")
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(Theme.ink.opacity(0.4))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.panel)
                    Capsule()
                        .fill(charge > 0.85 ? Theme.warn : Theme.lcd)
                        .frame(width: max(2, geo.size.width * charge))
                }
            }
            .frame(height: 7)
        }
    }

    private func resultBlock(_ b: BattleState) -> some View {
        VStack(spacing: 4) {
            Text(b.won == true ? "WIN" : "LOSE")
                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                .foregroundStyle(b.won == true ? Theme.lcd : Theme.danger)
            ForEach(Array(b.lines.suffix(2).enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Theme.ink.opacity(0.5))
            }
        }
    }

    private func playerRow(_ b: BattleState) -> some View {
        VStack(spacing: 2) {
            bar(value: b.playerHP, max: BattleState.playerHP(for: store.world), color: Theme.lcd)
            HStack {
                Text(store.world.species)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.ink.opacity(0.7))
                Spacer()
                Text("\(b.playerHP)/\(BattleState.playerHP(for: store.world))")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Theme.ink.opacity(0.35))
            }
        }
    }

    private func footer(_ b: BattleState) -> some View {
        HStack(spacing: 8) {
            if b.finished && !store.world.isDead {
                Button {
                    store.startBattle()
                    charge = 0
                } label: {
                    Text("REMATCH")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Theme.lcd, in: Capsule())
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
            }
            Button {
                store.showBattle = false
                dismiss()
            } label: {
                Text("EXIT")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Theme.panel, in: Capsule())
                    .foregroundStyle(Theme.ink.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
    }

    private func bar(value: Int, max maxValue: Int, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.panel)
                Capsule()
                    .fill(color)
                    .frame(width: max(0, geo.size.width * CGFloat(value) / CGFloat(max(1, maxValue))))
            }
        }
        .frame(height: 5)
    }
}
