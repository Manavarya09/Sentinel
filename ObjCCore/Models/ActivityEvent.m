#import "ActivityEvent.h"

@implementation ActivityEvent
@dynamic eventID;
@dynamic timestamp;
@dynamic eventType;
@dynamic sourceApp;
@dynamic duration;
@end

@implementation ActivityEvent (Convenience)
+ (NSFetchRequest<ActivityEvent *> *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"ActivityEvent"];
}
@end
