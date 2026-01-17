import Foundation

public struct ActivitySummary: Identifiable {
    public var id: Date { day }
    public let day: Date
    public let countsByType: [String: Int]
    public let totalDuration: TimeInterval
    public let sessionCount: Int
}
