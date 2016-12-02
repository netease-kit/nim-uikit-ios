//
//  UINavigationItem+Swizzling.m
//  NIM
//
//  Created by chris on 15/7/21.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "UINavigationItem+Swizzling.h"
#import "SwizzlingDefine.h"
#import "UIView+NTES.h"

#define MaxTitleWidth 200

@implementation UINavigationItem (Swizzling)

+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swizzling_exchangeMethod([UINavigationItem class] ,@selector(setTitle:), @selector(swizzling_setTitle:));
        swizzling_exchangeMethod([UINavigationItem class] ,@selector(title), @selector(swizzling_title));
    });
}


#pragma mark - SetTitle
- (void)swizzling_setTitle:(NSString *)title{
    UILabel *label = (UILabel *)self.titleView;
    if (!label) {
        label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.lineBreakMode = NSLineBreakByTruncatingMiddle;
        self.titleView = label;
    }
    if ([label isKindOfClass:[UILabel class]]) {
        label.text = title;
    }
    [label.superview setNeedsLayout];
}

- (NSString *)swizzling_title{
    if (self.swizzling_title.length) {
        return self.swizzling_title;
    }
    UILabel *label = (UILabel *)self.titleView;
    if ([label isKindOfClass:[UILabel class]]) {
        return label.text;
    }
    return nil;
}



@end
