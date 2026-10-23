import Foundation
import UserNotifications

/// 本地通知。watchOS 的待发通知配额有限，且后台刷新不可靠，
/// 所以策略是：永远只保留一条，每次结算后重排。
enum Notifier {

    private static let identifier = "next-event"

    static func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// 重排下一条通知。喂食/训练之后一定要调，否则提醒还是旧的。
    static func reschedule(for world: World, now: Date = Date()) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard let event = Schedule.nextEvent(world: world, from: now) else { return }

        // watchOS 不接受过近的间隔，给 10 秒下限
        let interval = max(10, event.date.timeIntervalSince(now))

        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = event.body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        center.add(UNNotificationRequest(identifier: identifier,
                                         content: content,
                                         trigger: trigger))
    }

    static func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
