import Foundation
import HealthKit

/// 健康线数据源。只读步数——够用，且不需要运动权限。
@MainActor
enum HealthSource {
    private static let store = HKHealthStore()

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    static func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        guard let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: [steps])
            return true
        } catch {
            return false
        }
    }

    /// 今天 0 点到现在累计走了多少步。
    static func stepsToday() async -> Int {
        guard isAvailable,
              let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }

        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(value))
            }
            store.execute(query)
        }
    }
}
