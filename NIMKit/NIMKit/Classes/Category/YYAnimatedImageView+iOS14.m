//
//  YYAnimatedImageView+iOS14.m
//  NIMKit
//
//  Created by Genning on 2020/9/25.
//  Copyright © 2020 NetEase. All rights reserved.
//  

#import "YYAnimatedImageView+iOS14.h"
#import <objc/runtime.h>

@implementation YYAnimatedImageView (iOS14)

+ (void)load {

    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{

        Method method1;

        Method method2;

        method1 = class_getInstanceMethod([self class], @selector(lz_displayLayer:));

        method2 = class_getInstanceMethod([self class], @selector(displayLayer:));

        method_exchangeImplementations(method1, method2);

    });

}

- (void)lz_displayLayer:(CALayer *)layer {

    Ivar ivar = class_getInstanceVariable(self.class, "_curFrame");

    UIImage *_curFrame = object_getIvar(self, ivar);

    if (_curFrame) {

        layer.contents = (__bridge id)_curFrame.CGImage;

    }else{

        if (@available(iOS 14.0, *)) {

            [super displayLayer:layer];

        }

    }

}

@end
