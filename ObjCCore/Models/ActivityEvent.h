#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface ActivityEvent : NSManagedObject
@property (nonatomic, strong) NSUUID *eventID;
@property (nonatomic, strong) NSDate *timestamp;
@property (nonatomic, copy) NSString *eventType;
@property (nonatomic, copy) NSString *sourceApp;
@property (nonatomic, strong, nullable) NSNumber *duration; // NSTimeInterval wrapper
@end

@interface ActivityEvent (Convenience)
+ (NSFetchRequest<ActivityEvent *> *)fetchRequest;
@end

NS_ASSUME_NONNULL_END
