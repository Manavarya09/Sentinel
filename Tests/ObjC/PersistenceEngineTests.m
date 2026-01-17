@import XCTest;
#import "ObjCCore/Persistence/SNTPersistenceEngine.h"
#import "ObjCCore/Models/ActivityEvent.h"

@interface PersistenceEngineTests : XCTestCase
@end

@implementation PersistenceEngineTests

- (void)testInMemorySaveAndFetch {
    SNTPersistenceEngine *engine = [[SNTPersistenceEngine alloc] initWithInMemoryStore:YES];
    XCTestExpectation *exp = [self expectationWithDescription:@"save"];
    [engine performBackgroundSaveBlock:^(NSManagedObjectContext *ctx) {
        ActivityEvent *e = [NSEntityDescription insertNewObjectForEntityForName:@"ActivityEvent" inManagedObjectContext:ctx];
        e.eventID = [NSUUID UUID];
        e.timestamp = [NSDate date];
        e.eventType = @"app.foreground";
        e.sourceApp = @"com.example.test";
        e.duration = @(1.0);
    } completion:^(NSError *error) {
        XCTAssertNil(error);
        [exp fulfill];
    }];
    [self waitForExpectations:@[exp] timeout:2.0];

    NSManagedObjectContext *ctx = [engine backgroundContext];
    [ctx performBlockAndWait:^{
        NSError *err = nil;
        NSUInteger count = [ctx countForFetchRequest:[ActivityEvent fetchRequest] error:&err];
        XCTAssertNil(err);
        XCTAssertEqual(count, 1);
    }];
}

@end
