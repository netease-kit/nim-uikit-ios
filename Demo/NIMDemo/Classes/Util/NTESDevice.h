//
//  NTESDevice.h
//  NIM
//
//  Created by chris on 15/9/18.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger,NTESNetworkType) {
    NTESNetworkTypeUnknown,
    NTESNetworkTypeWifi,
    NTESNetworkTypeWwan,
    NTESNetworkType2G,
    NTESNetworkType3G,
    NTESNetworkType4G,
};

@interface NTESDevice : NSObject

+ (NTESDevice *)currentDevice;

//图片/音频推荐参数
- (CGFloat)suggestImagePixels;

- (CGFloat)compressQuality;

//App状态
- (BOOL)isUsingWifi;
- (BOOL)isInBackground;

- (NTESNetworkType)currentNetworkType;

- (NSInteger)cpuCount;

- (BOOL)isLowDevice;
- (BOOL)isIphone;
- (NSString *)machineName;


- (CGFloat)statusBarHeight;

@end
