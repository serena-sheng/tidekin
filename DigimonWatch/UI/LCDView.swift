import SwiftUI

/// 状态卡：宠物与计量住在同一张卡里，而不是各自飘在黑底上。
/// 借鉴 Activity 的做法——同色低透明度渐变托底，一个 hero，亮度分层。
struct LCDView: View {
    let world: World
    var showMeters: Bool = true

    private var bitmap: UIImage? {
        guard !world.isDead else { return nil }
        return SpriteStore.image(for: world.species)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Grid.cardRadius, style: .continuous)
                .fill(world.isDead ? AnyShapeStyle(Theme.panel) : AnyShapeStyle(Theme.cardFill))

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                sprite
                Spacer(minLength: 0)
                if showMeters && !world.isDead && world.stage != .egg {
                    meters
                }
            }
            .padding(Grid.cardPadding)
        }
    }

    // MARK: - 宠物

    private var sprite: some View {
        Group {
            if world.isDead {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Theme.ink.opacity(0.25))
            } else if let bitmap {
                // 眨眼：每 4 秒闭眼 0.2 秒。静止的宠物看起来像截图而不是活物。
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
                .frame(maxWidth: Grid.spriteSize, maxHeight: Grid.spriteSize)
            } else {
                Canvas { ctx, size in
                    drawCharacterArt(ctx, size: size)
                }
                .frame(maxWidth: Grid.spriteSize, maxHeight: Grid.spriteSize)
            }
        }
        .frame(maxWidth: .infinity)
        .opacity(world.isAsleep ? 0.55 : 1)
    }

    // MARK: - 计量

    private var meters: some View {
        VStack(spacing: 6) {
            SegmentMeter(glyph: "♥", value: world.hunger, maxValue: world.maxHearts)
            SegmentMeter(glyph: "⚡", value: world.strength, maxValue: world.maxHearts)
        }
        .frame(width: Grid.meterWidth)
    }

    // MARK: - 字符画回退（资源缺失时）

    private func drawCharacterArt(_ ctx: GraphicsContext, size: CGSize) {
        let rows = Sprites.forSpecies(world.species, stage: world.stage, isDead: world.isDead)
        guard rows.count == 16 else { return }
        let cell = min(size.width, size.height) / 16
        for (y, row) in rows.enumerated() {
            for (x, ch) in row.enumerated() where ch == "#" {
                let r = CGRect(x: CGFloat(x) * cell, y: CGFloat(y) * cell,
                               width: cell, height: cell)
                ctx.fill(Path(r), with: .color(Theme.lcd))
            }
        }
    }
}
