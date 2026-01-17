#import <Foundation/Foundation.h>
#import "Models/ActivityEvent.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SNTEventCaptureDelegate;

NS_SWIFT_NAME(EventCaptureManager)
@interface SNTEventCaptureManager : NSObject

@property (nonatomic, weak, nullable) id<SNTEventCaptureDelegate> delegate;

+ (instancetype)sharedManager NS_SWIFT_NAME(shared);
- (void)startObserving;
- (void)stopObserving;

- (void)recordLifecycleEventWithType:(NSString *)type
                            sourceApp:(NSString *)sourceApp
                             duration:(nullable NSNumber *)duration NS_SWIFT_NAME(recordLifecycleEvent(type:sourceApp:duration:));

@end

@protocol SNTEventCaptureDelegate <NSObject>
- (void)eventCaptureManagerDidRecordEvent:(ActivityEvent *)event;
@end

NS_ASSUME_NONNULL_END
