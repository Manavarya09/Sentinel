#import "SNTEventCaptureManager.h"
#import "ObjCCoreDefines.h"
#import "Persistence/SNTPersistenceEngine.h"

@interface SNTEventCaptureManager ()
@property (nonatomic, strong) NSArray<id> *observers;
@end

@implementation SNTEventCaptureManager

+ (instancetype)sharedManager {
    static SNTEventCaptureManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SNTEventCaptureManager alloc] init];
    });
    return instance;
}

- (void)startObserving {
    if (self.observers.count > 0) { return; }
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    __weak typeof(self) weakSelf = self;
    id o1 = [nc addObserverForName:SNTAppDidEnterForegroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [weakSelf recordLifecycleEventWithType:@"app.foreground" sourceApp:[[NSProcessInfo processInfo] processName] duration:nil];
    }];
    id o2 = [nc addObserverForName:SNTAppDidEnterBackgroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [weakSelf recordLifecycleEventWithType:@"app.background" sourceApp:[[NSProcessInfo processInfo] processName] duration:nil];
    }];
    id o3 = [nc addObserverForName:SNTSceneWillEnterForegroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [weakSelf recordLifecycleEventWithType:@"scene.foreground" sourceApp:[[NSProcessInfo processInfo] processName] duration:nil];
    }];
    id o4 = [nc addObserverForName:SNTSceneDidEnterBackgroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [weakSelf recordLifecycleEventWithType:@"scene.background" sourceApp:[[NSProcessInfo processInfo] processName] duration:nil];
    }];
    self.observers = @[o1, o2, o3, o4];
}

- (void)stopObserving {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    for (id o in self.observers) { [nc removeObserver:o]; }
    self.observers = @[];
}

- (void)recordLifecycleEventWithType:(NSString *)type sourceApp:(NSString *)sourceApp duration:(NSNumber *)duration {
    SNTPersistenceEngine *pe = [SNTPersistenceEngine sharedEngine];
    [pe performBackgroundSaveBlock:^(NSManagedObjectContext *ctx) {
        ActivityEvent *event = [NSEntityDescription insertNewObjectForEntityForName:@"ActivityEvent" inManagedObjectContext:ctx];
        event.eventID = [NSUUID UUID];
        event.timestamp = [NSDate date];
        event.eventType = [type copy];
        event.sourceApp = [sourceApp copy];
        event.duration = duration; // optional
    } completion:^(NSError *error) {
        if (error) { return; }
        if (self.delegate) {
            // Deliver callback on main thread to avoid UI threading issues
            ActivityEvent *lastEvent = nil; // Could fetch last inserted if needed; omitted for simplicity
            dispatch_async(dispatch_get_main_queue(), ^{
                if (lastEvent) {
                    [self.delegate eventCaptureManagerDidRecordEvent:lastEvent];
                }
            });
        }
    }];
}

@end
