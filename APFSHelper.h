#import <Foundation/Foundation.h>

#define DLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);

//49874 == volume busy?
//49154 == volume doesnt exist?
//49890 == missing entitlements

typedef NS_ENUM(NSInteger, APFSErrorCode) {
    
    APFSErrorCodeInvalidVolume = 49154,
    APFSErrorCodeVolumeBusy = 49874,
    APFSErrorCodeBadEntitlements = 49890,
    APFSErrorCodeNone = 0,
    APFSErrorCodeUnknown
};

@interface NSString (APFS)
- (NSDictionary *)deviceDictionary;
@end

@interface APFSHelper: NSObject
+ (NSString *)returnForProcess:(NSString *)format, ...;
+ (NSDictionary *)mountedDevices;
+ (NSArray *)deviceArray;
+ (NSString *)prefixPath;
+ (NSString *)smartPrefixPath;
+ (int)refreshPrefix;
+ (void)listVolumes;
+ (int)deleteVolume:(NSString *)volume;
@end
