import SwiftUI

/// 资源计量条：用液晶同一套网格画段，而不是 SF Symbol。
/// 左端贴边距，右端数字贴边距——两端都与版心对齐。
struct SegmentMeter: View {
    let glyph: String
    let value: Int
    let maxValue: Int

    var body: some View {
        HStack(spacing: 0) {
            Text(glyph)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.ink.opacity(0.6))
                .frame(width: 12, alignment: .leading)

            HStack(spacing: 1) {
                ForEach(0..<maxValue, id: \.self) { i in
                    Rectangle()
                        .fill(i < value ? Theme.lcd : Theme.lcdDim)
                        .frame(width: 5, height: 6)
                }
            }

            Spacer(minLength: 4)

            Text("\(value)/\(maxValue)")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(Theme.ink.opacity(value == 0 ? 0.9 : 0.5))
                .frame(width: 26, alignment: .trailing)
        }
        .frame(height: 8)
    }
}
