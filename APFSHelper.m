#import "APFSHelper.h"
#include <sys/stat.h>
#import "iokit.h"

int APFSVolumeDelete(const char *path);

//([@./\w-]*)\son\s([./\w]*)\s\(([\w]*)

@implementation NSString (APFS)

- (NSDictionary *)deviceDictionary  {
    NSMutableDictionary *devices = [NSMutableDictionary new];
    NSError *error = NULL;
    NSRange range = NSMakeRange(0, self.length);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([@./\\w-]*)\\son\\s([./\\w]*)\\s\\(([\\w]*)" options:NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines error:&error];
    NSArray *matches = [regex matchesInString:self options:NSMatchingReportProgress range:range];
    for (NSTextCheckingResult *entry in matches) {
        NSMutableDictionary *dict = [NSMutableDictionary new];
        for (NSInteger i = 1; i < entry.numberOfRanges; i++) {
            NSRange range = [entry rangeAtIndex:i];
            if (range.location != NSNotFound){
                NSString *text = [self substringWithRange:range];
                switch (i) {
                    case 1:
                        dict[@"BSDName"] = text;
                        break;
                    case 2:
                        dict[@"Path"] = text;
                        break;
                    case 3:
                        dict[@"Type"] = text;
                        break;
                }
            }
        }
        devices[dict[@"BSDName"]] = dict;
    }
    return devices;
}

@end

@implementation APFSHelper

+ (int)deleteVolume:(NSString *)volume {
    if ([self queryUserWithString:@"Are you sure you want to delete this volume? This cannot be undone and all data will be lost!"]) {
        APFSErrorCode deleteProgress = APFSVolumeDelete([volume UTF8String]);
        //DLog(@"\nVolume deleted with return status: %d", deleteProgress);
        switch (deleteProgress) {
            case APFSErrorCodeInvalidVolume:
                DLog(@"\n%@ doesn't exist.\n\n", volume);
                break;
            case APFSErrorCodeVolumeBusy:
                DLog(@"\nThe volume is currently busy, try unmounting first!\n\n");
                break;
            case APFSErrorCodeBadEntitlements:
                DLog(@"\n\nMissing entitlements to delete APFS volumes\n\n");
                break;
            case APFSErrorCodeNone:
                DLog(@"\n\nVolume deleted successfully!\n\n");
                break;
            default:
                DLog(@"\n\nAn unknown error has occured, error code: %ld\n\n", (long)deleteProgress);
                break;
        }
        return deleteProgress;
    }
    return -1;
}

+ (void)listVolumes {
    NSArray *deviceArray = [self deviceArray];
    DLog(@"%@", deviceArray);
}

+ (BOOL)queryUserWithString:(NSString *)query {
    NSString *errorString = [NSString stringWithFormat:@"\n%@ [y/n]? ", query];
    char c;
    printf("%s", [errorString UTF8String] );
    c=getchar();
    while(c!='y' && c!='n') {
        if (c!='\n'){
            printf("[y/n]");
        }
        c=getchar();
    }
    if (c == 'n') {
        return false;
    } else if (c == 'y') {
        return true;
    }
    return false;
}

+ (NSArray *)returnForProcess:(NSString *)call {
    if (call==nil)
        return 0;
    char line[200];
    //DLog(@"\nRunning process: %@\n", call);
    FILE* fp = popen([call UTF8String], "r");
    NSMutableArray *lines = [[NSMutableArray alloc]init];
    if (fp) {
        while (fgets(line, sizeof line, fp)){
            NSString *s = [NSString stringWithCString:line encoding:NSUTF8StringEncoding];
            s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [lines addObject:s];
        }
    }
    pclose(fp);
    return lines;
}

+ (NSString *)mountDetails {
    return [[self returnForProcess:@"/sbin/mount"]componentsJoinedByString:@"\n"];
}

+ (NSDictionary *)mountedDevices {
    NSString *mount = [self mountDetails];
    //NSLog(@"mount: %@", mount);
    return [mount deviceDictionary];
}

+ (NSArray *)deviceArray {
    NSMutableArray *deviceArray = [NSMutableArray new];
    NSDictionary *mountedDevices = [self mountedDevices];
    //DLog(@"mountedDevices: %@", mountedDevices);
    mach_port_t masterPort = 0;
    IOMasterPort(MACH_PORT_NULL, &masterPort);
    CFMutableDictionaryRef classesToMatch = IOServiceMatching("AppleAPFSVolume");
    io_iterator_t matchingServices;
    kern_return_t kernResult = IOServiceGetMatchingServices(masterPort, classesToMatch, &matchingServices);
    if (kernResult != KERN_SUCCESS) {
        DLog(@"failed to find AppleAPFSVolume services");
        return nil;
    }
    io_service_t svc = 0;
    CFMutableDictionaryRef properties = 0;
    io_string_t path;
    while ((svc = IOIteratorNext(matchingServices))) {
        assert(KERN_SUCCESS == IORegistryEntryCreateCFProperties(svc, &properties, 0, 0));
        NSDictionary* propd = ((__bridge NSDictionary*)properties);
        NSNumber *roleValue = propd[@"RoleValue"];
        NSString *fullName = propd[@"FullName"];
        NSNumber *bsdUnitNumber = propd[@"BSD Unit"];
        NSString *bsdName = propd[@"BSD Name"];
        NSNumber *size = propd[@"Size"];
        NSNumber *open = propd[@"Open"];
        NSString *bsdPath = [@"/dev" stringByAppendingPathComponent:bsdName];
        NSDictionary *mounted = mountedDevices[bsdPath];
        NSString *mountedPath = mounted[@"Path"];
        IORegistryEntryGetPath(svc, kIOServicePlane, path);
        NSString *pathString = [NSString stringWithUTF8String:path];
        NSString *pathName = [pathString lastPathComponent];
        NSArray *pathComponents = [pathName componentsSeparatedByString:@"@"];
        NSString *lpc = [pathComponents lastObject];
        if (!fullName) {
            fullName = [pathComponents firstObject];
        }
        NSMutableDictionary *newProps = [NSMutableDictionary new];
        int i = [lpc intValue];
        newProps[@"BSD Name"] = bsdName;
        newProps[@"BSD Path"] = bsdPath;
        newProps[@"FullName"] = fullName;
        newProps[@"RoleValue"] = roleValue;
        newProps[@"Path"] = pathString;
        newProps[@"BSDUnit"] = bsdUnitNumber;
        newProps[@"BSD Partition"] = @(i);
        newProps[@"Size"] = size;
        newProps[@"Open"] = open;
        if (mountedPath){
            newProps[@"MountPath"] = mountedPath;
        }
        [deviceArray addObject:newProps];
    }
    IOObjectRelease(svc);
    IOObjectRelease(matchingServices);
    mach_port_deallocate(mach_task_self(), masterPort);
    return deviceArray;
}

+ (NSString *)prefixConfigPath {
    return @"/etc/cr_prefix";
}

+ (int)refreshPrefix {
    NSString *prefixPath = [self prefixPath];
    if (prefixPath) {
        DLog(@"Found prefix path: %@", prefixPath);
        return [prefixPath writeToFile:[self prefixConfigPath] atomically:true encoding:NSUTF8StringEncoding error:nil];
    }
    return -1;
}

+ (NSString *)smartPrefixPath {
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self prefixConfigPath]]){
        return [NSString stringWithContentsOfFile:[self prefixConfigPath] encoding:NSUTF8StringEncoding error:nil];
    } else {
        [self refreshPrefix];
    }
    return [self prefixPath];
}

+ (NSString *)prefixPath {
    NSArray *deviceArray = [self deviceArray];
    NSDictionary *checkra1n = [[deviceArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"FullName == 'checkra1n'"]] lastObject];
    //DLog(@"checkra1n: %@", checkra1n);
    return checkra1n[@"MountPath"];
}

@end
