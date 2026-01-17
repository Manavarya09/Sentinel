@import XCTest;
#import "ObjCCore/Analytics/SNTAnalyticsEngine.h"
#import "ObjCCore/Persistence/SNTPersistenceEngine.h"
#import "ObjCCore/Models/ActivityEvent.h"

@interface AnalyticsEngineTests : XCTestCase
@end

@implementation AnalyticsEngineTests

- (void)testDailySummaryDeterministic {
    SNTPersistenceEngine *engine = [[SNTPersistenceEngine alloc] initWithInMemoryStore:YES];
    // Seed deterministic events
    [engine performBackgroundSaveBlock:^(NSManagedObjectContext *ctx) {
        for (int i = 0; i < 3; i++) {
            ActivityEvent *e = [NSEntityDescription insertNewObjectForEntityForName:@"ActivityEvent" inManagedObjectContext:ctx];
            e.eventID = [NSUUID UUID];
            e.timestamp = [NSDate date];
            e.eventType = (i % 2 == 0) ? @"app.foreground" : @"scene.background";
            e.sourceApp = @"com.example.test";
            e.duration = @(i + 1);
        }
    } completion:nil];

    SNTAnalyticsEngine *analytics = [SNTAnalyticsEngine sharedEngine];
    XCTestExpectation *exp = [self expectationWithDescription:@"summary"];
    [analytics dailySummaryWithCompletion:^(NSDictionary *summary) {
        NSDictionary *counts = summary[@"countsByType"];
        NSNumber *fg = counts[@"app.foreground"] ?: @(0);
        NSNumber *bg = counts[@"scene.background"] ?: @(0);
        XCTAssertEqual(fg.intValue, 2);
        XCTAssertEqual(bg.intValue, 1);
        NSNumber *total = summary[@"totalDuration"];
        XCTAssertEqualWithAccuracy(total.doubleValue, 6.0, 0.001);
        [exp fulfill];
    }];
    [self waitForExpectations:@[exp] timeout:2.0];
}

@end
