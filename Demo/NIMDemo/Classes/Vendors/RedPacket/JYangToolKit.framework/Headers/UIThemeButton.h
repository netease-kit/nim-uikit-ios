//
//  UIThemeButton.h
//  JrmfWalletKit
//
//  Created by 一路财富 on 16/10/31.
//  Copyright © 2016年 JYang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIThemeButton : UIButton

/**
 自定义按钮

 @param Ori_Y Y值
 @param bgColor 默认颜色
 @return 按钮
 */
- (instancetype)initWithOri_Y:(float)Ori_Y WithThemeColor:(UIColor *)bgColor;

/**
 自定义按钮

 @param frame 位置
 @param bgColor 默认颜色
 @return 按钮
 */
- (instancetype)initWithFrame:(CGRect)frame WithThemeColor:(UIColor *)bgColor;


@end
