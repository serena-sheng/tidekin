import SwiftUI

/// 液晶屏与整机的色阶。
///
/// 关键约束来自 HIG：材质只用于控制层，内容层用标准材质 + 亮度分层。
/// 所以这里不靠描边分层（描边对纯黑只有 1.5:1，等于不存在），靠亮度与色块面积分层。
enum Theme {
    /// 强调色。面积必须小：只给卡底、计量、选中态
    static let lcd = Color(red: 0.58, green: 0.88, blue: 0.52)
    /// 计量槽 / 未点亮
    static let lcdDim = Color(red: 0.13, green: 0.20, blue: 0.12)
    /// 需求提示（比红温和，不与应用图标抢）
    static let warn = Color(red: 0.95, green: 0.76, blue: 0.31)
    static let danger = Color(red: 0.95, green: 0.35, blue: 0.38)
    /// 控制层底色
    static let panel = Color.white.opacity(0.08)
    static let ink = Color.white

    /// 卡底：同色 10% → 2.5% 的垂直渐变。亮色必须有托底，否则直接浮在黑上会发脏。
    static var cardFill: LinearGradient {
        LinearGradient(
            colors: [lcd.opacity(0.14), lcd.opacity(0.03)],
            startPoint: .top, endPoint: .bottom
        )
    }
}

/// 版式栅格。数值来自 46mm 实际像素 208×248（416×496 @2x）。
enum Grid {
    static let margin: CGFloat = 10
    static let gap: CGFloat = 7

    static let rowHeader: CGFloat = 38
    static let rowCard: CGFloat = 120
    static let rowActions: CGFloat = 42

    /// 动作格
    static let actionWidth: CGFloat = 28
    static let actionRadius: CGFloat = 12
    static let actionGap: CGFloat = 4

    /// 卡内
    static let cardRadius: CGFloat = 20
    static let cardPadding: CGFloat = 8
    static let spriteSize: CGFloat = 88
    static let meterWidth: CGFloat = 96
    static let meterHeight: CGFloat = 5
}
