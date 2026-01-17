#import "SNTSecurity.h"
#import <Security/Security.h>

@implementation SNTSecurity

- (BOOL)storeSecret:(NSData *)secret forKey:(NSString *)key error:(NSError **)error {
    NSDictionary *query = @{ (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                             (__bridge id)kSecAttrAccount: key,
                             (__bridge id)kSecValueData: secret,
                             (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly };
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    if (status == errSecDuplicateItem) {
        NSDictionary *updateQuery = @{ (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                       (__bridge id)kSecAttrAccount: key };
        NSDictionary *attributesToUpdate = @{ (__bridge id)kSecValueData: secret };
        status = SecItemUpdate((__bridge CFDictionaryRef)updateQuery, (__bridge CFDictionaryRef)attributesToUpdate);
    }
    if (status != errSecSuccess && error) {
        *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        return NO;
    }
    return YES;
}

- (NSData *)secretForKey:(NSString *)key error:(NSError **)error {
    NSDictionary *query = @{ (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                             (__bridge id)kSecAttrAccount: key,
                             (__bridge id)kSecReturnData: @YES,
                             (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne };
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status != errSecSuccess) {
        if (error) *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        return nil;
    }
    return (__bridge_transfer NSData *)result;
}

- (BOOL)applyFileProtectionCompleteToPath:(NSString *)path error:(NSError **)error {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL ok = [fm setAttributes:@{ NSFileProtectionKey: NSFileProtectionComplete } ofItemAtPath:path error:error];
    return ok;
}

@end
