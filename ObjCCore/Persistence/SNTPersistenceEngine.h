#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(PersistenceEngine)
@interface SNTPersistenceEngine : NSObject

@property (nonatomic, readonly) NSPersistentContainer *container;
@property (nonatomic, strong) NSMergePolicy *mergePolicy;

+ (instancetype)sharedEngine NS_SWIFT_NAME(shared);
- (instancetype)initWithInMemoryStore:(BOOL)inMemory;

- (NSManagedObjectContext *)backgroundContext;
- (void)performBackgroundSaveBlock:(void (^)(NSManagedObjectContext *ctx))block
                         completion:(void (^)(NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
