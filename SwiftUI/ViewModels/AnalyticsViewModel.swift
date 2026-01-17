import Foundation
import Combine
// import ObjCCore (module exposing AnalyticsEngine via NS_SWIFT_NAME)

final class AnalyticsViewModel: ObservableObject {
    @Published var summary: ActivitySummary?

    private let engine = AnalyticsEngine.shared()

    func refreshDaily() {
        engine.dailySummary { [weak self] dict in
            guard let self = self else { return }
            // Parse dictionary from ObjC into Swift model
            let day = dict["day"] as? Date ?? Date()
            let counts = dict["countsByType"] as? [String: NSNumber] ?? [:]
            let swiftCounts = counts.mapValues { $0.intValue }
            let total = (dict["totalDuration"] as? NSNumber)?.doubleValue ?? 0
            let sessions = (dict["sessionCount"] as? NSNumber)?.intValue ?? 0
            let model = ActivitySummary(day: day, countsByType: swiftCounts, totalDuration: total, sessionCount: sessions)
            DispatchQueue.main.async {
                self.summary = model
            }
        }
    }
}
