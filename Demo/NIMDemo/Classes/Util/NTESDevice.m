//
//  NTESDevice.m
//  NIM
//
//  Created by chris on 15/9/18.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NTESDevice.h"
#import "Reachability.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <sys/sysctl.h>
#import <sys/utsname.h>

#define NormalImageSize       (1280 * 960)


@interface NTESDevice ()

@property (nonatomic,strong)    NSDictionary    *networkTypes;

@end

@implementation NTESDevice

- (instancetype)init
{
    if (self = [super init])
    {
        [self buildDeviceInfo];
    }
    return self;
}


+ (NTESDevice *)currentDevice{
    static NTESDevice *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NTESDevice alloc] init];
    });
    return instance;
}

- (void)buildDeviceInfo
{
    _networkTypes = @{
                          CTRadioAccessTechnologyGPRS:@(NTESNetworkType2G),
                          CTRadioAccessTechnologyEdge:@(NTESNetworkType2G),
                          CTRadioAccessTechnologyWCDMA:@(NTESNetworkType3G),
                          CTRadioAccessTechnologyHSDPA:@(NTESNetworkType3G),
                          CTRadioAccessTechnologyHSUPA:@(NTESNetworkType3G),
                          CTRadioAccessTechnologyCDMA1x:@(NTESNetworkType3G),
                          CTRadioAccessTechnologyCDMAEVDORev0:@(NTESNetworkType3G),
                          CTRadioAccessTechnologyCDMAEVDORevA:@(NTESNetworkType3G),
                          CTRadioAccessTechnologyCDMAEVDORevB:@(NTESNetworkType3G),
                          CTRadioAccessTechnologyeHRPD:@(NTESNetworkType3G),
                          CTRadioAccessTechnologyLTE:@(NTESNetworkType4G),
                     };
}


//图片/音频推荐参数
- (CGFloat)suggestImagePixels{
    return NormalImageSize;
}

- (CGFloat)compressQuality{
    return 0.5;
}


//App状态
- (BOOL)isUsingWifi{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus status =  [reachability currentReachabilityStatus];
    return status == ReachableViaWiFi;
}

- (BOOL)isInBackground{
    return [[UIApplication sharedApplication] applicationState] != UIApplicationStateActive;
}

- (NTESNetworkType)currentNetworkType{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus status =  [reachability currentReachabilityStatus];
    switch (status) {
        case ReachableViaWiFi:
            return NTESNetworkTypeWifi;
        case ReachableViaWWAN:
        {
            CTTelephonyNetworkInfo *telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
            NSNumber *number = [_networkTypes objectForKey:telephonyInfo.currentRadioAccessTechnology];
            return number ? (NTESNetworkType)[number integerValue] : NTESNetworkTypeWwan;
        }
        default:
            return NTESNetworkTypeUnknown;
    }
}

- (NSInteger)cpuCount{
    size_t size = sizeof(int);
    int results;
    
    int mib[2] = {CTL_HW, HW_NCPU};
    sysctl(mib, 2, &results, &size, NULL, 0);
    return (NSUInteger) results;
}

- (BOOL)isLowDevice{
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    return [[NSProcessInfo processInfo] processorCount] <= 1;
#endif
}

- (BOOL)isIphone{
    NSString *deviceModel = [UIDevice currentDevice].model;
    if ([deviceModel isEqualToString:@"iPhone"]) {
        return YES;
    }else {
        return NO;
    }
}

- (NSString *)machineName{
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}


- (CGFloat)statusBarHeight{
    CGFloat height = [UIApplication sharedApplication].statusBarFrame.size.height;
    if (!IOS8 && ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)) {
        height = [UIApplication sharedApplication].statusBarFrame.size.width;
    }
    return height;
}


@end
