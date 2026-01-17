#import "SNTPersistenceEngine.h"

@interface SNTPersistenceEngine ()
@property (nonatomic, strong) NSPersistentContainer *container;
@property (nonatomic, assign) BOOL inMemory;
@end

@implementation SNTPersistenceEngine

+ (instancetype)sharedEngine {
    static SNTPersistenceEngine *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SNTPersistenceEngine alloc] initWithInMemoryStore:NO];
    });
    return instance;
}

- (instancetype)initWithInMemoryStore:(BOOL)inMemory {
    if (self = [super init]) {
        _inMemory = inMemory;
        _mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        NSManagedObjectModel *model = [self buildModel];
        _container = [[NSPersistentContainer alloc] initWithName:@"SentinelHybrid" managedObjectModel:model];

        NSPersistentStoreDescription *desc = [NSPersistentStoreDescription persistentStoreDescriptionWithURL:[self storeURL]];
        if (inMemory) {
            desc = [NSPersistentStoreDescription persistentStoreDescriptionWithURL:[NSURL URLWithString:@"/dev/null"]];
            desc.type = NSInMemoryStoreType;
        }
        desc.shouldAddStoreAsynchronously = NO;
        desc.setOption(@YES, NSMigratePersistentStoresAutomaticallyOption);
        desc.setOption(@YES, NSInferMappingModelAutomaticallyOption);

        _container.persistentStoreDescriptions = @[desc];
        [_container loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull description, NSError * _Nullable error) {
            if (error) {
                abort();
            }
        }];

        _container.viewContext.mergePolicy = _mergePolicy;
        _container.viewContext.automaticallyMergesChangesFromParent = YES;
        _container.viewContext.undoManager = nil;
        _container.viewContext.shouldDeleteInaccessibleFaults = YES;
    }
    return self;
}

- (NSURL *)storeURL {
    NSURL *appSupport = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] firstObject];
    NSURL *dir = [appSupport URLByAppendingPathComponent:@"SentinelHybrid" isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:@{NSFileProtectionKey: NSFileProtectionComplete} error:nil];
    return [dir URLByAppendingPathComponent:@"SentinelHybrid.sqlite"];
}

- (NSManagedObjectModel *)buildModel {
    NSEntityDescription *activity = [[NSEntityDescription alloc] init];
    activity.name = @"ActivityEvent";
    activity.managedObjectClassName = @"ActivityEvent";

    NSAttributeDescription *eventID = [[NSAttributeDescription alloc] init];
    eventID.name = @"eventID";
    eventID.attributeType = NSUUIDAttributeType;
    eventID.optional = NO;

    NSAttributeDescription *timestamp = [[NSAttributeDescription alloc] init];
    timestamp.name = @"timestamp";
    timestamp.attributeType = NSDateAttributeType;
    timestamp.optional = NO;

    NSAttributeDescription *eventType = [[NSAttributeDescription alloc] init];
    eventType.name = @"eventType";
    eventType.attributeType = NSStringAttributeType;
    eventType.optional = NO;

    NSAttributeDescription *sourceApp = [[NSAttributeDescription alloc] init];
    sourceApp.name = @"sourceApp";
    sourceApp.attributeType = NSStringAttributeType;
    sourceApp.optional = NO;

    NSAttributeDescription *duration = [[NSAttributeDescription alloc] init];
    duration.name = @"duration";
    duration.attributeType = DoubleAttributeType;
    duration.optional = YES;

    activity.properties = @[eventID, timestamp, eventType, sourceApp, duration];

    // Indexing: timestamp + eventType for fast aggregations
    NSFetchIndexElementDescription *tsIndexElem = [[NSFetchIndexElementDescription alloc] initWithProperty:timestamp collationType:NSFetchIndexElementTypeBinary];
    NSFetchIndexElementDescription *typeIndexElem = [[NSFetchIndexElementDescription alloc] initWithProperty:eventType collationType:NSFetchIndexElementTypeBinary];
    NSFetchIndexDescription *idx = [[NSFetchIndexDescription alloc] initWithName:@"idx_ts_type" elements:@[tsIndexElem, typeIndexElem]];
    activity.indexes = @[idx];

    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] init];
    model.entities = @[activity];
    return model;
}

- (NSManagedObjectContext *)backgroundContext {
    NSManagedObjectContext *ctx = [self.container newBackgroundContext];
    ctx.mergePolicy = self.mergePolicy;
    ctx.undoManager = nil;
    return ctx;
}

- (void)performBackgroundSaveBlock:(void (^)(NSManagedObjectContext *))block completion:(void (^)(NSError *))completion {
    NSManagedObjectContext *ctx = [self backgroundContext];
    [ctx performBlock:^{
        block(ctx);
        NSError *err = nil;
        if ([ctx hasChanges]) {
            if (![ctx save:&err]) { /* fallthrough */ }
        }
        if (completion) { completion(err); }
    }];
}

@end
