import SwiftUI

/// 三条驱动线的开关与换算，加上两个凭据入口。
struct SettingsView: View {
    @ObservedObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey = Keychain.get(Keychain.deepSeekKey) ?? ""
    @State private var healthMessage = "未授权"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                section("驱动线")
                weightRow("时间", "clock", \.time, 1)
                weightRow("健康", "figure.walk", \.health, 1)
                weightRow("Token", "number", \.token, 1)

                Divider()

                section("健康数据")
                Button("授权步数") {
                    Task {
                        let ok = await HealthSource.requestAuthorization()
                        healthMessage = ok ? "已授权" : "被拒绝或不可用"
                    }
                }
                .buttonStyle(.bordered)
                Text(healthMessage)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.secondary)
                Button("同步今天的步数") {
                    Task { await store.syncHealth() }
                }
                .buttonStyle(.bordered)

                Divider()

                section("Token（仅手表内对话）")
                Text("今日 \(store.world.tokenDayUsed) / \(store.world.tuning.dailyTokenCap)")
                    .font(.system(size: 10, design: .monospaced))
                Text("累计 \(store.world.totalTokens)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.secondary)
                Text("\(Int(store.world.tuning.tokensPerDriveMinute)) token = 1 分钟成长")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.secondary)

                Divider()

                section("DeepSeek")
                SecureField("API Key", text: $apiKey)
                    .font(.system(size: 10, design: .monospaced))
                Button("保存 Key") {
                    Keychain.set(apiKey, for: Keychain.deepSeekKey)
                    store.flash("KEY SAVED")
                }
                .buttonStyle(.bordered)

                Divider()

                Button("NEW EGG") { store.newGame() }
                    .buttonStyle(.bordered)
                    .tint(Theme.danger)
            }
            .padding(.horizontal, 2)
        }
        .navigationTitle("SETUP")
    }

    private func section(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(Theme.lcd.opacity(0.8))
    }

    private func weightRow(_ label: String, _ symbol: String,
                           _ key: WritableKeyPath<Tuning.DriveWeights, Double>,
                           _ fallback: Double) -> some View {
        let binding = Binding<Bool>(
            get: { store.world.tuning.weights[keyPath: key] > 0 },
            set: { on in
                var w = store.world.tuning.weights
                w[keyPath: key] = on ? fallback : 0
                store.updateWeights(w)
            }
        )
        return Toggle(isOn: binding) {
            Label(label, systemImage: symbol)
                .font(.system(size: 10, design: .monospaced))
        }
    }
}
