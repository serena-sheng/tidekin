import SwiftUI

/// 首次对话前的告知页。Apple 要求在用第三方 AI 处理用户输入前明确说明接收方与用途。
struct ConsentView: View {
    @ObservedObject var store: Store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("TALK 前需要你同意")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.ink)

                Text("你发的文字、以及它当前的状态（饥饿/力量/心情），会发送给你在设置里配置的第三方对话服务。")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.ink.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)

                Text("本 app 不建账号、不上传健康数据。步数只在本机换算成成长进度。聊天记录只保留在手表上，最多 6 轮参与下一次请求。")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.ink.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)

                Text("输出由模型生成，可能不准确；被判定为不适宜的回复会被拦截并提示。你可以随时在对话页举报。")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.ink.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    store.acceptConsent()
                    dismiss()
                } label: {
                    Text("同意并继续")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Theme.lcd, in: Capsule())
                        .foregroundStyle(.black)
                }
                .buttonStyle(PressableStyle())
                .padding(.top, 4)

                Button("返回") { dismiss() }
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.ink.opacity(0.5))
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("BEFORE TALK")
    }
}
