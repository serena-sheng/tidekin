import SwiftUI

/// 死亡是全屏互斥态：没有心条、没有动作栏，也不再有"压暗"的中间状态。
struct GoneView: View {
    @ObservedObject var store: Store
    @State private var showActions = true

    private var ageText: String {
        let h = Int(store.world.ageHours)
        let d = h / 24
        return d > 0 ? "\(d)D \(h % 24)H" : "\(h)H"
    }

    var body: some View {
        VStack(spacing: 6) {
            VStack(spacing: 1) {
                Text("GONE")
                    .font(.system(size: 15, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Theme.danger)
                Text("\(store.world.displayName) RETURNED TO DATA · \(ageText)")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Theme.ink.opacity(0.4))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            LCDView(world: store.world)
                .frame(maxHeight: 118)

            if showActions {
                VStack(spacing: 4) {
                    Button {
                        store.tapNewEgg()
                        Haptics.tap()
                    } label: {
                        Text(store.newEggArmed ? "TAP AGAIN · ERASES \(store.world.displayName)" : "NEW EGG")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(store.newEggArmed ? Theme.danger : Theme.lcd, in: Capsule())
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.plain)

                    Button {
                        showActions = false
                    } label: {
                        Text("KEEP WATCHING")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Theme.ink.opacity(0.45))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

/// 离开超过两小时才出现。只留三件事：进化、失误、受伤。
struct AwaySummaryView: View {
    let summary: AwaySummary
    @ObservedObject var store: Store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(summary.title)
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .foregroundStyle(Theme.lcd)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            VStack(alignment: .leading, spacing: 4) {
                if let evolved = summary.evolvedTo {
                    line("EVOLVED INTO \(evolved)", color: Theme.lcd)
                }
                ForEach(Array(summary.lines.enumerated()), id: \.offset) { _, text in
                    line(text.uppercased(), color: Theme.ink.opacity(0.6))
                }
            }

            Spacer(minLength: 0)

            Button {
                store.dismissAway()
                dismiss()
            } label: {
                Text("OK")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Theme.panel, in: Capsule())
                    .foregroundStyle(Theme.ink)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private func line(_ text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text("·")
                .foregroundStyle(Theme.lcd.opacity(0.5))
            Text(text)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .font(.system(size: 9, design: .monospaced))
    }
}
