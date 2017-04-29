//
//  NIMKitDevice.m
//  NIM
//
//  Created by chris on 15/9/18.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NIMKitDevice.h"
#import "NIMGlobalMacro.h"

#define NIMKitNormalImageSize       (1280 * 960)


@interface NIMKitDevice ()

@end

@implementation NIMKitDevice

- (instancetype)init
{
    if (self = [super init])
    {
        
    }
    return self;
}


+ (NIMKitDevice *)currentDevice{
    static NIMKitDevice *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NIMKitDevice alloc] init];
    });
    return instance;
}


//图片/音频推荐参数
- (CGFloat)suggestImagePixels{
    return NIMKitNormalImageSize;
}

- (CGFloat)compressQuality{
    return 0.5;
}


- (CGFloat)statusBarHeight{
    CGFloat height = [UIApplication sharedApplication].statusBarFrame.size.height;
    if (!NIMKit_IOS8 && ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)) {
        height = [UIApplication sharedApplication].statusBarFrame.size.width;
    }
    return height;
}


@end
