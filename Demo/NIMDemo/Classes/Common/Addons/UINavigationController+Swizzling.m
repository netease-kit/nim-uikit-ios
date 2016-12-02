//
//  UINavigationController+Swizzling.m
//  NIM
//
//  Created by chris on 15/10/26.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "UINavigationController+Swizzling.h"
#import "SwizzlingDefine.h"
#import "UIView+NTES.h"

@implementation UINavigationController (Swizzling)

+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swizzling_exchangeMethod([UINavigationController class] ,@selector(supportedInterfaceOrientations), @selector(swizzling_supportedInterfaceOrientations));
        swizzling_exchangeMethod([UINavigationController class] ,@selector(shouldAutorotate), @selector(swizzling_shouldAutorotate));
    });
}

#pragma mark - ShouldAutorotate
- (BOOL)swizzling_shouldAutorotate
{
    return [self.topViewController shouldAutorotate];
}


#pragma mark - SupportedInterfaceOrientations
- (UIInterfaceOrientationMask)swizzling_supportedInterfaceOrientations{
    return [self.topViewController supportedInterfaceOrientations];
}




@end
