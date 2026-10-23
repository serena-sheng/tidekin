import SwiftUI

/// 状态卡：宠物与计量住在同一张卡里，而不是各自飘在黑底上。
/// 借鉴 Activity 的做法——同色低透明度渐变托底，一个 hero，亮度分层。
struct LCDView: View {
    @Environment(\.isLuminanceReduced) private var dimmed
    @State private var blinking = false

    let world: World
    var showMeters: Bool = true
    /// 精灵最大边长。第一页给大值，让宠物成为画面主角。
    var spriteMax: CGFloat = Grid.spriteSize

    private var bitmap: UIImage? {
        guard !world.isDead else { return nil }
        return SpriteStore.image(for: world.species)
    }

    var body: some View {
        ZStack {
            // 不再有卡片底：宠物直接站在黑底上
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                sprite
                Spacer(minLength: 0)
                if showMeters && !world.isDead && world.stage != .egg {
                    meters
                }
            }

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
                // 眨眼：事件驱动而不是 10Hz 轮询。
                // 常亮屏（AOD）下不闪，睡眠时不闪。
                let shown = blinking && !world.isAsleep && !dimmed
                Image(uiImage: SpriteStore.image(for: world.species, blink: shown) ?? bitmap)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(maxWidth: spriteMax, maxHeight: spriteMax)
                    .task(id: world.isAsleep) {
                        guard !world.isAsleep else { return }
                        while !Task.isCancelled {
                            try? await Task.sleep(for: .seconds(3.8))
                            blinking = true
                            try? await Task.sleep(for: .seconds(0.2))
                            blinking = false
                        }
                    }
            } else {
                Canvas { ctx, size in
                    drawCharacterArt(ctx, size: size)
                }
                .frame(maxWidth: spriteMax, maxHeight: spriteMax)
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
