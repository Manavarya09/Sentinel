#import "SNTAnalyticsEngine.h"
#import "ObjCCoreDefines.h"
#import "Persistence/SNTPersistenceEngine.h"
#import "Models/ActivityEvent.h"

@interface SNTAnalyticsEngine ()
@property (nonatomic) dispatch_queue_t queue;
@end

@implementation SNTAnalyticsEngine

+ (instancetype)sharedEngine {
    static SNTAnalyticsEngine *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SNTAnalyticsEngine alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.queue = dispatch_queue_create([SNTAnalyticsQueueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(self.queue, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0));
    }
    return self;
}

- (void)dailySummaryWithCompletion:(void (^)(NSDictionary *))completion {
    // Only run off the main thread
    dispatch_async(self.queue, ^{
        SNTPersistenceEngine *pe = [SNTPersistenceEngine sharedEngine];
        NSManagedObjectContext *ctx = [pe backgroundContext];
        [ctx performBlock:^{
            NSDate *now = [NSDate date];
            NSCalendar *cal = [NSCalendar currentCalendar];
            NSDate *startOfDay = nil; NSTimeInterval interval = 0;
            [cal rangeOfUnit:NSCalendarUnitDay startDate:&startOfDay interval:&interval forDate:now];
            NSDate *endOfDay = [startOfDay dateByAddingTimeInterval:interval - 1];

            NSFetchRequest *fr = [ActivityEvent fetchRequest];
            fr.predicate = [NSPredicate predicateWithFormat:@"timestamp >= %@ AND timestamp <= %@", startOfDay, endOfDay];
            fr.includesSubentities = NO;
            fr.returnsObjectsAsFaults = YES; // leverage faulting

            NSError *err = nil;
            NSArray<ActivityEvent *> *events = [ctx executeFetchRequest:fr error:&err];
            if (err) { if (completion) completion(@{}); return; }

            NSMutableDictionary<NSString *, NSNumber *> *countsByType = [NSMutableDictionary dictionary];
            double totalDuration = 0.0;
            NSMutableSet<NSString *> *sessionApps = [NSMutableSet set];
            for (ActivityEvent *e in events) {
                NSNumber *count = countsByType[e.eventType] ?: @(0);
                countsByType[e.eventType] = @(count.integerValue + 1);
                if (e.duration) { totalDuration += e.duration.doubleValue; }
                if (e.sourceApp) { [sessionApps addObject:e.sourceApp]; }
            }

            NSDictionary *summary = @{ @"day": startOfDay,
                                       @"countsByType": countsByType.copy,
                                       @"totalDuration": @(totalDuration),
                                       @"sessionCount": @([sessionApps count]) };
            if (completion) { completion(summary); }
        }];
    });
}

@end
