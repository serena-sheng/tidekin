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
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.black)

                // 像素画要求网格＝像素格；这里不画假网格，让精灵自己承担结构
                if bitmap != nil, !world.isDead {
                    // 眨眼：每 4 秒闭眼 0.2 秒。原版每隔几秒也会动一下，
                    // 静止的宠物看起来像截图而不是活物。
                    TimelineView(.periodic(from: .now, by: 0.1)) { context in
                        let phase = context.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: 4.0)
                        let blinking = !world.isAsleep && phase < 0.2
                        if let img = SpriteStore.image(for: world.species, blink: blinking) {
                            Image(uiImage: img)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                        }
                    }
                        
                } else {
                    Canvas { ctx, _ in
                        drawCharacterArt(ctx, cell: cell, side: side)
                    }
                    .frame(width: side, height: side)
                }

                cornerBadges
                    .padding(7)
            }
            .frame(width: side, height: side)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Theme.lcd.opacity(0.15), lineWidth: 1)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
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

