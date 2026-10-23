import SwiftUI

/// 资源计量条：用液晶同一套网格画段，而不是 SF Symbol。
/// 段宽 5、缝 1，未点亮用 lcdDim——黑底上能看出"缺几颗"，矢量心做不到。
struct SegmentMeter: View {
    let glyph: String
    let value: Int
    let maxValue: Int

    var body: some View {
        HStack(spacing: 3) {
            Text(glyph)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.ink.opacity(0.6))
                .frame(width: 10, alignment: .leading)

            HStack(spacing: 1) {
                ForEach(0..<maxValue, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(i < value ? Theme.lcd : Theme.lcdDim)
                        .frame(width: 5, height: 6)
                }
            }

            Text("\(value)")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(Theme.ink.opacity(value == 0 ? 0.9 : 0.35))
                .frame(width: 10, alignment: .trailing)

            Spacer(minLength: 0)
        }
    }
}
