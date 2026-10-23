import SwiftUI

/// 液晶屏。优先用官方彩色精灵（16×16 最近邻放大），
/// 没有资源的物种回退到手绘字符画。1fps 观感，Always-On 下不耗电。
struct LCDView: View {
    let world: World

    private let grid = 16

    private var sprite: [String] {
        Sprites.forSpecies(world.species, stage: world.stage, isDead: world.isDead)
    }

    private var bitmap: UIImage? {
        guard !world.isDead else { return nil }
        return SpriteStore.image(for: world.species)
    }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = side / CGFloat(grid)

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black)

                // 极淡网格：给彩色像素一点"屏幕"质感，但不跟精灵抢注意力
                Canvas { ctx, size in
                    var path = Path()
                    for i in 1..<grid {
                        let x = CGFloat(i) * cell
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        let y = CGFloat(i) * cell
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    ctx.stroke(path, with: .color(Theme.lcdDim.opacity(0.22)), lineWidth: 0.5)
                }
                .frame(width: side, height: side)

                if let bitmap {
                    // 极淡背光：Botamon 这类深色精灵在黑底上几乎没有轮廓
                    RadialGradient(
                        colors: [Color.white.opacity(0.07), .clear],
                        center: .center, startRadius: 0, endRadius: side * 0.45
                    )
                    .allowsHitTesting(false)

                    Image(uiImage: bitmap)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .padding(cell * 0.35)
                } else {
                    Canvas { ctx, _ in
                        drawCharacterArt(ctx, cell: cell, side: side)
                    }
                    .frame(width: side, height: side)
                }

                cornerBadges
                    .padding(7)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.lcd.opacity(0.28), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.06), .clear, Color.white.opacity(0.02)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .allowsHitTesting(false)
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - 字符画回退

    private func drawCharacterArt(_ ctx: GraphicsContext, cell: CGFloat, side: CGFloat) {
        var minX = grid, maxX = -1, minY = grid, maxY = -1
        for (y, row) in sprite.enumerated() {
            for (x, ch) in row.enumerated() where ch == "#" {
                minX = min(minX, x); maxX = max(maxX, x)
                minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        guard maxX >= minX else { return }

        let bw = CGFloat(maxX - minX + 1)
        let bh = CGFloat(maxY - minY + 1)
        let span = max(bw, bh)
        let px = cell * 11.0 / span
        let ox = (side - bw * px) / 2 - CGFloat(minX) * px
        let oy = (side - bh * px) / 2 - CGFloat(minY) * px

        for (y, row) in sprite.enumerated() {
            for (x, ch) in row.enumerated() where ch == "#" {
                let r = CGRect(x: ox + CGFloat(x) * px,
                               y: oy + CGFloat(y) * px,
                               width: px, height: px)
                    .insetBy(dx: px * 0.06, dy: px * 0.06)
                ctx.fill(Path(r), with: .color(Theme.lcd))
            }
        }
    }

    // MARK: - 角标

    private var cornerBadges: some View {
        VStack {
            HStack(alignment: .top) {
                Spacer()
                if world.isDead {
                    tag("R.I.P")
                } else if world.callKind.isActive {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.danger)
                }
            }
            Spacer()
            HStack(alignment: .bottom) {
                if world.isAsleep {
                    Text("Zz")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.lcd.opacity(0.6))
                }
                Spacer()
                if world.poop > 0 {
                    Text(String(repeating: "▪", count: min(world.poop, 4)))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Theme.lcd.opacity(0.55))
                }
            }
        }
    }

    private func tag(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundStyle(Theme.lcd.opacity(0.7))
    }
}

/// 心形计量条：点亮用液晶绿而非红色，保持整机只有一个色系。
struct HeartMeter: View {
    let label: String
    let value: Int
    let maxValue: Int

    var body: some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.ink.opacity(0.35))
                .frame(width: 26, alignment: .leading)
            ForEach(0..<maxValue, id: \.self) { i in
                Image(systemName: "heart.fill")
                    .font(.system(size: 6.5))
                    .foregroundStyle(i < value ? Theme.lcd : Theme.ink.opacity(0.12))
            }
            Spacer(minLength: 0)
        }
    }
}
