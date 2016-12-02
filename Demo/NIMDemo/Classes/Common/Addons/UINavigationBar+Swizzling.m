//
//  UINavigationBar+Swizzling.m
//  NIM
//
//  Created by chris on 15/6/23.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "UINavigationBar+Swizzling.h"
#import "UIView+NTES.h"
#import "SwizzlingDefine.h"
@implementation UINavigationBar (Swizzling)

+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swizzling_exchangeMethod([UINavigationBar class] ,@selector(layoutSubviews), @selector(swizzling_layoutSubviews));
    });
}

#pragma mark - LayoutSubviews
#define NavigationBtnMargin 28
#define TitleMargin 43
- (void)swizzling_layoutSubviews{
    [self swizzling_layoutSubviews];
    UINavigationItem *navigationItem = [self topItem];
    UIView *subview  = [[navigationItem leftBarButtonItem] customView];
    subview.left = NavigationBtnMargin;
    
    //解决标题过长时，设置navigationItem.title导致标题偏移的问题
    UILabel *label = (UILabel *)navigationItem.titleView;
    UIFont *font   = self.titleTextAttributes[NSFontAttributeName];
    if (font) {
        label.font = font;
    }
    UIColor *color = self.titleTextAttributes[NSForegroundColorAttributeName];
    if (color) {
        label.textColor = color;
    }
    [label sizeToFit];
    [self layoutLabel];
    
    if (!IOS8) {
        UIViewController *vc = self.viewController;
        //在竖屏转横屏后，iOS7下导航条会变成32，但是并没有通知到对应vc...这里手动加一个... 否则排版会出问题
        [vc.view setNeedsLayout];
    }
}

#pragma mark - Private
- (void)layoutLabel{
    UINavigationItem *navigationItem = [self topItem];
    UIView *leftView   = [[navigationItem leftBarButtonItems].lastObject customView];
    UIView *rightView  = [[navigationItem rightBarButtonItems].firstObject customView];
    CGFloat left  = leftView.right;
    CGFloat right = rightView ? rightView.right : self.width;
    
    CGFloat maxWidth   = right - left - 2 * TitleMargin;
    UIView *view = navigationItem.titleView;
    view.width   = view.width > maxWidth ? maxWidth : view.width;
    view.centerX = self.width  * .5f;
    view.centerY = self.height * .5f;
}


@end
