//
//  UIView+Swizzling.m
//  NIM
//
//  Created by chris on 15/10/27.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "UIView+Swizzling.h"
#import "SwizzlingDefine.h"

@implementation UIView (Swizzling)

+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //响应链日志，在调试的时候开启
        //swizzling_exchangeMethod([UIView class] ,@selector(hitTest:withEvent:), @selector(swizzling_hitTest:withEvent:));
    });
}

#pragma mark - ShouldAutorotate
- (UIView *)swizzling_hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [self swizzling_hitTest:point withEvent:event];
    if (view) {
        DDLogDebug(@"--hit test--，%@ hit view : %@",[self class],[view class]);
    }
    return view;
}



@end
