import SwiftUI

struct ChatView: View {
    @ObservedObject var store: Store
    @State private var draft = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    Text("今日已计入 \(store.world.tokenDayUsed)/\(store.world.tuning.dailyTokenCap) token")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(Theme.ink.opacity(0.28))
                    if store.chatLog.isEmpty {
                        Text("跟 \(store.world.displayName) 说点什么")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                    ForEach(Array(store.chatLog.enumerated()), id: \.offset) { _, entry in
                        bubble(entry.role, entry.text)
                    }
                    if store.isThinking {
                        Text("…")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Theme.lcd)
                    }
                    if let err = store.chatError {
                        Text(err)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Theme.danger)
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 2)
            }
            .onChange(of: store.chatLog.count) { _, _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }

            HStack(spacing: 4) {
                TextField("说…", text: $draft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                Button {
                    let text = draft
                    draft = ""
                    Task { await store.ask(text) }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(Theme.lcd)
                }
                .buttonStyle(.plain)
                .disabled(draft.isEmpty || store.isThinking)
            }
            .padding(.top, 4)
        }
        .navigationTitle("TALK")
    }

    private func bubble(_ role: String, _ text: String) -> some View {
        HStack {
            if role == "user" { Spacer(minLength: 12) }
            Text(text)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(role == "user" ? Color.black : Theme.ink)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(role == "user" ? Theme.lcd : Theme.panel)
                )
            if role != "user" { Spacer(minLength: 12) }
        }
    }
}
