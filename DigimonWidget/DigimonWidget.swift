import WidgetKit
import SwiftUI

/// 表盘小组件的数据。
///
/// 只读 App Group 里那份 world.json —— 与 app 同一个文件，
/// 所以表盘上看到的永远是最后一次结算后的状态。
struct PetEntry: TimelineEntry {
    let date: Date
    let world: World?
}

struct PetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PetEntry {
        PetEntry(date: Date(), world: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (PetEntry) -> Void) {
        completion(PetEntry(date: Date(), world: Persistence.load()))
    }

    /// 下一次刷新取"下一个关键事件"的时刻；拿不到就 30 分钟后再来。
    /// watchOS 的 complication 刷新配额很紧，宁可保守。
    func getTimeline(in context: Context, completion: @escaping (Timeline<PetEntry>) -> Void) {
        let now = Date()
        let world = Persistence.load()

        // 不引 Schedule：那会把 Simulator 整条链拖进 extension。
        // 30 分钟一次足够——表盘只是"抬眼确认"，真正的事件由 app 的通知负责。
        let next = now.addingTimeInterval(30 * 60)
        completion(Timeline(entries: [PetEntry(date: now, world: world)], policy: .after(next)))
    }
}

struct TidekinComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TidekinComplication", provider: PetProvider()) { entry in
            ComplicationView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Tidekin")
        .description("它现在要不要你、还剩多久。")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct ComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PetEntry

    private var world: World? { entry.world }

    var body: some View {
        switch family {
        case .accessoryCircular:
            circular
        case .accessoryRectangular:
            rectangular
        case .accessoryInline:
            Text(inlineText)
        default:
            circular
        }
    }

    // MARK: - 圆形

    /// 圆形槽位太小放不下精灵，只表达"要不要你"：心数 + 状态。
    private var circular: some View {
        VStack(spacing: 0) {
            if let world {
                Text(world.isDead ? "—" : "\(world.hunger)")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(tint)
                Image(systemName: symbol)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(tint.opacity(0.8))
            } else {
                Image(systemName: "questionmark")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - 矩形

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let world {
                Text(world.isDead ? "GONE" : world.species)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .lineLimit(1)
                Text(headline(world))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(tint)
                    .lineLimit(1)
                if !world.isDead, let progress = progress(world) {
                    Text(progress)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } else {
                Text("TIDEKIN")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                Text("open the app")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: -

    private var inlineText: String {
        guard let world else { return "Tidekin" }
        if world.isDead { return "GONE" }
        return "\(world.species) · \(headline(world))"
    }

    private var symbol: String {
        guard let world else { return "questionmark" }
        if world.isDead { return "leaf.fill" }
        if world.isAsleep { return "moon.zzz.fill" }
        switch world.demand {
        case .feed: return "fork.knife"
        case .train: return "dumbbell.fill"
        case .clean: return "sparkles"
        case .heal: return "cross.case.fill"
        case .none: return "heart.fill"
        }
    }

    private var tint: Color {
        guard let world else { return .secondary }
        if world.isDead { return .red }
        if world.demand == .none { return .green }
        return .yellow
    }

    private func headline(_ world: World) -> String {
        if world.isAsleep { return "ASLEEP" }
        switch world.demand {
        case .feed: return "FEED ME"
        case .train: return "TRAIN ME"
        case .clean: return "CLEAN ME"
        case .heal: return "HEAL ME"
        case .none: return "FINE"
        }
    }

    private func progress(_ world: World) -> String? {
        guard let need = world.battlesToPerfect, need > 0 else {
            guard let m = world.minutesToEvolution else { return nil }
            return m < 60 ? "\(m)m" : "\(m / 60)h"
        }
        return "\(need) FIGHTS"
    }
}

@main
struct TidekinWidgetBundle: WidgetBundle {
    var body: some Widget {
        TidekinComplication()
    }
}
