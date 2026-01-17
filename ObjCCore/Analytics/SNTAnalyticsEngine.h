#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AnalyticsEngine)
@interface SNTAnalyticsEngine : NSObject
+ (instancetype)sharedEngine NS_SWIFT_NAME(shared);
- (void)dailySummaryWithCompletion:(void (^)(NSDictionary *summary))completion NS_SWIFT_NAME(dailySummary(completion:));
@end

NS_ASSUME_NONNULL_END
