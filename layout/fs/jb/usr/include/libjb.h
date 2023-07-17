#import <Foundation/Foundation.h>

@interface JBManager: NSObject
+(NSString *)jbPrefix;
+(int)refreshPrefix;
+ (int)deleteVolume:(NSString *)volume;
+ (NSArray *)deviceArray;
@end
