import SwiftUI

/// 液晶屏的统一色阶。改这里 = 改整机气质。
enum Theme {
    /// 点亮的像素（偏黄绿，模拟 90 年代 STN 液晶）
    static let lcd = Color(red: 0.58, green: 0.88, blue: 0.52)
    /// 未点亮的底纹
    static let lcdDim = Color(red: 0.11, green: 0.20, blue: 0.13)
    /// 告警
    static let warn = Color(red: 0.95, green: 0.72, blue: 0.28)
    /// 紧急
    static let danger = Color(red: 0.95, green: 0.35, blue: 0.38)
    /// 面板底色
    static let panel = Color.white.opacity(0.08)
    static let ink = Color.white
}

/// 版式网格。所有间距只能取这里的值，否则一定会歪。
///
/// 参照瑞士平面设计的做法：先定列与边距，元素只落在网格线上。
/// 46mm 表屏宽 198pt，左右各留 8，内容宽 182，6 列每列 30.33。
enum Grid {
    static let margin: CGFloat = 8
    static let gap: CGFloat = 6
    static let columns = 6

    // 纵向行高，加起来必须 ≤ 可用高度（242 - 状态栏)
    static let rowHeader: CGFloat = 30
    static let rowScreen: CGFloat = 100
    static let rowMeters: CGFloat = 20
    static let rowActions: CGFloat = 32

    /// 6 列里占几列的宽度
    static func span(_ n: Int, total: CGFloat) -> CGFloat {
        let inner = total - margin * 2
        return inner * CGFloat(n) / CGFloat(columns)
    }
}
