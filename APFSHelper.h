#import <Foundation/Foundation.h>

#define DLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);

//49874 == volume busy?
//49154 == volume doesnt exist?
//49890 == missing entitlements

typedef NS_ENUM(NSInteger, APFSErrorCode) {
    
    APFSErrorCodeInvalidVolume = 49154,
    APFSErrorCodeVolumeBusy = 49874,
    APFSErrorCodeBadEntitlements = 49890,
    APFSErrorCodeUnknown
};

@interface NSString (APFS)
- (NSDictionary *)deviceDictionaryFromRegex:(NSString *)pattern;
@end

@interface APFSHelper: NSObject
+ (NSArray *)returnForProcess:(NSString *)call;
+ (NSDictionary *)mountedDevices;
+ (NSArray *)deviceArray;
+ (NSString *)prefixPath;
+ (NSString *)smartPrefixPath;
+ (int)refreshPrefix;
+ (void)listVolumes;
+ (int)deleteVolume:(NSString *)volume;
@end
