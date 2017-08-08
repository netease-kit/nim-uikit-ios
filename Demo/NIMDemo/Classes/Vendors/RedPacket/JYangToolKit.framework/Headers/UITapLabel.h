//
//  UITapLabel.h
//  RedEnvelopeDemo
//
//  Created by 一路财富 on 16/2/27.
//  Copyright © 2016年 一路财富. All rights reserved.
//
//  可点击的UILabel

#import <UIKit/UIKit.h>

@class UITapLabel;
@protocol UITapLabelDelegate <NSObject>

@required
/**
 *  UITapLabel 代理函数
 *
 *  @param tapLabel     当前UITapLabel
 *  @param tag          当前UITapLabel的Tag值
 */
- (void)tapLabel:(UITapLabel *)tapLabel touchesWithTag:(NSInteger)tag;

@end

@interface UITapLabel : UILabel

@property (nonatomic, assign) id <UITapLabelDelegate> delegate;

/**
 *  字体颜色
 */
@property (nonatomic, strong) UIColor * txtColor;

/**
 *  是否可点击
 */
@property (nonatomic, assign) BOOL enable;


@end
