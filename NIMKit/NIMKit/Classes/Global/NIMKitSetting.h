//
//  NIMKitSetting.h
//  NIMKit
//
//  Created by chris on 2017/10/30.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  气泡设置
 */
@interface NIMKitSetting : NSObject

/**
 *  设置消息 Contentview 内间距
 */
@property (nonatomic, assign) UIEdgeInsets contentInsets;

/**
 *  设置消息 Contentview 的文字颜色
 */
@property (nonatomic, strong) UIColor *textColor;

/**
 *  设置消息 Contentview 的文字字体
 */
@property (nonatomic, strong) UIFont *font;

/**
 *  设置消息 Reply Message Contentview 的文字颜色
 */
@property (nonatomic, strong) UIColor *replyedTextColor;

/**
 *  设置消息 Reply Message Contentview 的文字字体
 */
@property (nonatomic, strong) UIFont *replyedFont;

/**
 *  设置消息是否显示头像
 */
@property (nonatomic, assign) BOOL showAvatar;

/**
 *  设置消息普通模式下的背景图
 */
@property (nonatomic, strong) UIImage *normalBackgroundImage;

/**
 *  设置消息按压模式下的背景图
 */
@property (nonatomic, strong) UIImage *highLightBackgroundImage;


- (instancetype)init:(BOOL)isRight;

@end





