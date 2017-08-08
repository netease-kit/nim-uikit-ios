//
//  SVProgressHUD+Swizzling.m
//  NIM
//
//  Created by chris on 2017/7/26.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import "SVProgressHUD+Swizzling.h"
#import "SwizzlingDefine.h"

@implementation SVProgressHUD (Swizzling)

+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL selector = NSSelectorFromString(@"visibleKeyboardHeight");
        swizzling_exchangeMethod([SVProgressHUD class], selector, @selector(swizzling_visibleKeyboardHeight));
    });
}


- (CGFloat)swizzling_visibleKeyboardHeight
{
#if !defined(SV_APP_EXTENSIONS)
    UIWindow *keyboardWindow = nil;
    for (UIWindow *testWindow in UIApplication.sharedApplication.windows) {
        if(![testWindow.class isEqual:UIWindow.class]) {
            keyboardWindow = testWindow;
            break;
        }
    }
    
    for (__strong UIView *possibleKeyboard in keyboardWindow.subviews) {
        NSString *viewName = NSStringFromClass(possibleKeyboard.class);
        if([viewName hasPrefix:@"UI"]){
            if([viewName hasSuffix:@"PeripheralHostView"] || [viewName hasSuffix:@"Keyboard"]){
                return CGRectGetHeight(possibleKeyboard.bounds);
            } else if ([viewName hasSuffix:@"InputSetContainerView"]){
                for (__strong UIView *possibleKeyboardSubview in possibleKeyboard.subviews) {
                    viewName = NSStringFromClass(possibleKeyboardSubview.class);
                    if([viewName hasPrefix:@"UI"] && [viewName hasSuffix:@"InputSetHostView"]) {
                        return CGRectGetHeight(possibleKeyboardSubview.bounds);
                    }
                }
            }
        }
    }
#endif
    return 0;
}


@end
