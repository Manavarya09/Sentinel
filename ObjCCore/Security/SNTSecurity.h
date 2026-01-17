#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Security)
@interface SNTSecurity : NSObject
- (BOOL)storeSecret:(NSData *)secret forKey:(NSString *)key error:(NSError **)error NS_SWIFT_NAME(store(secret:forKey:));
- (nullable NSData *)secretForKey:(NSString *)key error:(NSError **)error NS_SWIFT_NAME(secret(forKey:));
- (BOOL)applyFileProtectionCompleteToPath:(NSString *)path error:(NSError **)error NS_SWIFT_NAME(applyFileProtection(path:));
@end

NS_ASSUME_NONNULL_END
