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
