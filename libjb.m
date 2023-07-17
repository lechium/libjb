#import "libjb.h"
#import "APFSHelper.h"

@implementation JBManager

+ (NSString *)jbPrefix {
    return [APFSHelper smartPrefixPath];
}

+ (int)refreshPrefix {
    return [APFSHelper refreshPrefix];
}

+ (NSArray *)deviceArray {
    return [APFSHelper deviceArray];
}

+ (int)deleteVolume:(NSString *)volume {
    return [APFSHelper deleteVolume:volume];
}

@end
