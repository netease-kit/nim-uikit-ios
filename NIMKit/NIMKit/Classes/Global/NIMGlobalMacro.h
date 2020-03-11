//
//  NIMGlobalMacro.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#ifndef NIMKit_GlobalMacro_h
#define NIMKit_GlobalMacro_h

#import "NSString+NIMKit.h"

#define NIMKit_IOS11            ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 11.0)
#define NIMKit_UIScreenWidth   [UIScreen mainScreen].bounds.size.width
#define NIMKit_UIScreenHeight  [UIScreen mainScreen].bounds.size.height


#define NIMKit_SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)


#pragma mark - UIColor宏定义

#define NIMKit_UIColorFromRGBA(rgbValue, alphaValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0x0000FF))/255.0 \
alpha:alphaValue]

#define NIMKit_UIColorFromRGB(rgbValue) NIMKit_UIColorFromRGBA(rgbValue, 1.0)

#define NIMKit_Dispatch_Sync_Main(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_sync(dispatch_get_main_queue(), block);\
}

#define NIMKit_Dispatch_Async_Main(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}

/* weak reference */
#define NIMKit_WEAK_SELF(weakSelf) __weak __typeof(&*self) weakSelf = self;
#define NIMKit_STRONG_SELF(strongSelf) __strong __typeof(&*weakSelf) strongSelf = weakSelf;


#endif
