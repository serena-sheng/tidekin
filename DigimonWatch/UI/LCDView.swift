import SwiftUI

/// 宠物画面：只有精灵本身，没有卡片底、没有计量条。
/// 计量在第二页，这里只负责"它现在长什么样、是不是活着"。
struct LCDView: View {
    @Environment(\.isLuminanceReduced) private var dimmed
    @State private var blinking = false

    let world: World
    /// 精灵最大边长。第一页给大值，让宠物成为画面主角。
    var spriteMax: CGFloat = Grid.spriteSize

    var body: some View {
        Group {
            if world.isDead {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Theme.ink.opacity(0.25))
            } else if let bitmap = SpriteStore.image(for: world.species) {
                // 眨眼：事件驱动而不是轮询。常亮屏（AOD）与睡眠时不闪。
                let shown = blinking && !world.isAsleep && !dimmed
                Image(uiImage: SpriteStore.image(for: world.species, blink: shown) ?? bitmap)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(maxWidth: spriteMax, maxHeight: spriteMax)
                    .id(world.species)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: world.species)
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
                // 资源缺失时的占位，不再维护第二套字符画
                Image(systemName: "questionmark.square.dashed")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.ink.opacity(0.2))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(world.isAsleep ? 0.7 : 1)
    }
}
