import SwiftUI

/// 资源计量条：只靠图形说话，不写数字。
///
/// 段的宽度按整行等分拉伸，所以满格时最后一格正好顶到右边距；
/// 空格子保留暗绿槽位，能一眼数出上限与当前值。
struct SegmentMeter: View {
    let glyph: String
    let value: Int
    let maxValue: Int

    private let segGap: CGFloat = 3
    private let segHeight: CGFloat = 6

    var body: some View {
        HStack(spacing: 0) {
            Text(glyph)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.ink.opacity(0.7))
                .frame(width: 11, alignment: .leading)

            HStack(spacing: segGap) {
                ForEach(0..<maxValue, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(i < value ? Theme.lcd : Theme.lcdDim)
                        .frame(maxWidth: .infinity)
                        .frame(height: segHeight)
                }
            }
        }
    }
}
