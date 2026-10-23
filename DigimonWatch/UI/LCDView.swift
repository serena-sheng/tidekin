import SwiftUI

/// 液晶屏：16×16 点阵 + 底纹。1fps 观感，Always-On 下也不会耗电。
struct LCDView: View {
    let world: World

    private let grid = 16

    private var sprite: [String] {
        Sprites.forSpecies(world.species, stage: world.stage, isDead: world.isDead)
    }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = side / CGFloat(grid)

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black)

                Canvas { ctx, _ in
                    // 底纹点阵：先画满，让屏幕始终有"玻璃"质感
                    for y in 0..<grid {
                        for x in 0..<grid {
                            let r = CGRect(
                                x: CGFloat(x) * cell + cell * 0.34,
                                y: CGFloat(y) * cell + cell * 0.34,
                                width: cell * 0.32,
                                height: cell * 0.32
                            )
                            ctx.fill(Path(roundedRect: r, cornerRadius: cell * 0.12),
                                     with: .color(Theme.lcdDim))
                        }
                    }
                    // 精灵：先求包围盒，再按内容居中缩放到 14 格
                    var minX = grid, maxX = -1, minY = grid, maxY = -1
                    for (y, row) in sprite.enumerated() {
                        for (x, ch) in row.enumerated() where ch == "#" {
                            minX = min(minX, x); maxX = max(maxX, x)
                            minY = min(minY, y); maxY = max(maxY, y)
                        }
                    }
                    if maxX >= minX {
                        let bw = CGFloat(maxX - minX + 1)
                        let bh = CGFloat(maxY - minY + 1)
                        let span = max(bw, bh)
                        let px = cell * 11.0 / span
                        let ox = (side - bw * px) / 2 - CGFloat(minX) * px
                        let oy = (side - bh * px) / 2 - CGFloat(minY) * px
                        for (y, row) in sprite.enumerated() {
                            for (x, ch) in row.enumerated() where ch == "#" {
                                let r = CGRect(
                                    x: ox + CGFloat(x) * px,
                                    y: oy + CGFloat(y) * px,
                                    width: px,
                                    height: px
                                ).insetBy(dx: px * 0.06, dy: px * 0.06)
                                ctx.fill(Path(r), with: .color(Theme.lcd))
                            }
                        }
                    }
                }
                .frame(width: side, height: side)

                cornerBadges
                    .padding(7)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.lcd.opacity(0.28), lineWidth: 1)
            )
            .overlay(
                // 玻璃高光：左上斜向一道，别太亮
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.07), .clear, Color.white.opacity(0.02)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .allowsHitTesting(false)
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

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
