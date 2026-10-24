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
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Theme.ink.opacity(0.35))

                    if store.chatLog.isEmpty {
                        Text("跟 \(store.world.displayName) 说点什么")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(Theme.ink.opacity(0.55))
                            .padding(.top, 6)
                    }

                    ForEach(Array(store.chatLog.enumerated()), id: \.offset) { _, entry in
                        bubble(entry.role, entry.text)
                    }

                    if store.isThinking {
                        Text("…")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(Theme.lcd)
                    }

                    if let err = store.chatError {
                        Text(err)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Theme.danger)
                    }

                    if !store.chatLog.isEmpty {
                        Button {
                            store.reportLastExchange()
                        } label: {
                            Text("举报最近一条")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Theme.ink.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }

                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 2)
            }
            .onChange(of: store.chatLog.count) { _, _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }

            if store.hasConsented {
                HStack(spacing: 4) {
                    TextField("说…", text: $draft)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
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
            } else {
                Button {
                    store.needsConsent = true
                } label: {
                    Text("开始前先读一遍说明")
                        .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Theme.panel, in: Capsule())
                        .foregroundStyle(Theme.ink.opacity(0.8))
                }
                .buttonStyle(PressableStyle())
                .padding(.top, 4)
            }
        }
        .navigationTitle("TALK")
        .sheet(isPresented: $store.needsConsent) {
            NavigationStack { ConsentView(store: store) }
        }
    }

    private func bubble(_ role: String, _ text: String) -> some View {
        HStack {
            if role == "user" { Spacer(minLength: 10) }
            Text(text)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(role == "user" ? Color.black : Theme.ink)
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(role == "user" ? Theme.lcd : Theme.panel)
                )
            if role != "user" { Spacer(minLength: 10) }
        }
    }
}
