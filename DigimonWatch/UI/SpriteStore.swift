import UIKit

/// 官方 Digital Monster Color 的 16×16 彩色精灵。
///
/// 来源：Wikimon 图库的 `<Name>_vpet_dmc.gif`（48×48，按 3 倍最近邻还原成 16×16）。
/// 这些是 Bandai 的版权素材，只在个人复刻项目里本地使用，不要随包分发或公开再发布。
enum SpriteStore {
    /// 物种名 → 资源名。缺图的用同族顶替，并在注释里标出来。
    /// 现在 15 张全部自绘，不再需要顶替映射。
    private static let aliases: [String: String] = [:]

    private static var cache: [String: UIImage] = [:]

    static func image(for species: String) -> UIImage? {
        let key = aliases[species] ?? species.lowercased()
        if let hit = cache[key] { return hit }
        guard let raw = load(key) else { return nil }
        let canvas = centerOnCanvas(raw) ?? raw
        cache[key] = canvas
        return canvas
    }

    private static func load(_ key: String) -> UIImage? {
        if let img = UIImage(named: key) { return img }
        if let url = Bundle.main.url(forResource: key, withExtension: "png", subdirectory: "Sprites") {
            return UIImage(contentsOfFile: url.path)
        }
        if let url = Bundle.main.url(forResource: key, withExtension: "png") {
            return UIImage(contentsOfFile: url.path)
        }
        return nil
    }

    /// 官方图的留白不对称（Botamon 贴在画布底部），
    /// 所以按 alpha 包围盒裁出来，再放回 16×16 的正中央。
    /// 只平移不缩放——体量关系是原机设计的一部分，小兽就该小。
    private static func centerOnCanvas(_ image: UIImage, canvas: Int = 16) -> UIImage? {
        guard let content = trimToContent(image), let cg = content.cgImage else { return nil }
        let w = cg.width, h = cg.height
        guard w > 0, h > 0,
              let ctx = CGContext(
                data: nil, width: canvas, height: canvas,
                bitsPerComponent: 8, bytesPerRow: canvas * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return nil }
        ctx.interpolationQuality = .none
        ctx.draw(cg, in: CGRect(x: (canvas - w) / 2, y: (canvas - h) / 2,
                                width: w, height: h))
        guard let out = ctx.makeImage() else { return nil }
        return UIImage(cgImage: out)
    }

    /// 按 alpha 包围盒裁掉透明留白。
    private static func trimToContent(_ image: UIImage) -> UIImage? {
        guard let cg = image.cgImage else { return image }
        let w = cg.width, h = cg.height
        guard w > 0, h > 0 else { return image }

        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(
            data: &pixels, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return image }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

        var minX = w, maxX = -1, minY = h, maxY = -1
        for y in 0..<h {
            for x in 0..<w {
                if pixels[(y * w + x) * 4 + 3] > 8 {
                    minX = min(minX, x); maxX = max(maxX, x)
                    minY = min(minY, y); maxY = max(maxY, y)
                }
            }
        }
        guard maxX >= minX, maxY >= minY else { return image }

        let rect = CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
        guard let cropped = cg.cropping(to: rect) else { return image }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }
}
