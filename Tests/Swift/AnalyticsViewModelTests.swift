import XCTest
@testable import SentinelHybrid

final class AnalyticsViewModelTests: XCTestCase {
    func testMappingFromObjCDictionary() {
        let dict: [String: Any] = [
            "day": Date(),
            "countsByType": ["app.foreground": 2, "scene.background": 1],
            "totalDuration": 6.0,
            "sessionCount": 1
        ]
        let day = dict["day"] as! Date
        let counts = dict["countsByType"] as! [String: Int]
        let total = dict["totalDuration"] as! Double
        let sessions = dict["sessionCount"] as! Int
        let model = ActivitySummary(day: day, countsByType: counts, totalDuration: total, sessionCount: sessions)
        XCTAssertEqual(model.countsByType["app.foreground"], 2)
        XCTAssertEqual(model.countsByType["scene.background"], 1)
        XCTAssertEqual(model.totalDuration, 6.0)
        XCTAssertEqual(model.sessionCount, 1)
    }
}
