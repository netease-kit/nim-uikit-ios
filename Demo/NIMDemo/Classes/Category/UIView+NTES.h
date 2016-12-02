//
//  UIView+NTES.h
//  NIMDemo
//
//  Created by ght on 15-1-31.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (NTES)

@property (nonatomic) CGFloat left;

/**
 * Shortcut for frame.origin.y
 *
 * Sets frame.origin.y = top
 */
@property (nonatomic) CGFloat top;

/**
 * Shortcut for frame.origin.x + frame.size.width
 *
 * Sets frame.origin.x = right - frame.size.width
 */
@property (nonatomic) CGFloat right;

/**
 * Shortcut for frame.origin.y + frame.size.height
 *
 * Sets frame.origin.y = bottom - frame.size.height
 */
@property (nonatomic) CGFloat bottom;

/**
 * Shortcut for frame.size.width
 *
 * Sets frame.size.width = width
 */
@property (nonatomic) CGFloat width;

/**
 * Shortcut for frame.size.height
 *
 * Sets frame.size.height = height
 */
@property (nonatomic) CGFloat height;

/**
 * Shortcut for center.x
 *
 * Sets center.x = centerX
 */
@property (nonatomic) CGFloat centerX;

/**
 * Shortcut for center.y
 *
 * Sets center.y = centerY
 */
@property (nonatomic) CGFloat centerY;
/**
 * Shortcut for frame.origin
 */
@property (nonatomic) CGPoint origin;

/**
 * Shortcut for frame.size
 */
@property (nonatomic) CGSize size;

//找到自己的vc
- (UIViewController *)viewController;


@end


@interface UIView (NTESPresent)

//弹出一个类似present效果的窗口
- (void)presentView:(UIView*)view animated:(BOOL)animated complete:(void(^)()) complete;

//获取一个view上正在被present的view
- (UIView *)presentedView;

- (void)dismissPresentedView:(BOOL)animated complete:(void(^)()) complete;

//这个是被present的窗口本身的方法
//如果自己是被present出来的，消失掉
- (void)hideSelf:(BOOL)animated complete:(void(^)()) complete;

@end

