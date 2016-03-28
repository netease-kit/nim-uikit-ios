//
//  NIMMessageModel.h
//  NIMKit
//
//  Created by NetEase.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMSessionConfig.h"

@interface NIMMessageModel : NSObject

/**
 *  消息数据
 */
@property (nonatomic, strong) NIMMessage *message;

/**
 *  消息对应的布局配置
 */
@property (nonatomic,strong) id<NIMCellLayoutConfig> layoutConfig;

/**
 *  消息对应的session配置
 */
@property (nonatomic,strong) id<NIMSessionConfig>  sessionConfig;

@property (nonatomic, readonly) CGSize     contentSize;

@property (nonatomic, readonly) UIEdgeInsets  contentViewInsets;

@property (nonatomic, readonly) UIEdgeInsets  bubbleViewInsets;

@property (nonatomic, readonly) CGFloat avatarMargin;

@property (nonatomic, readonly) CGFloat nickNameMargin;

@property (nonatomic, readonly) BOOL shouldShowAvatar;

@property (nonatomic, readonly) BOOL shouldShowNickName;

@property (nonatomic, readonly) BOOL shouldShowLeft;

@property (nonatomic) BOOL shouldShowReadLabel;

/**
 *  计算内容大小
 *
 *  @param width 内容宽度
 */
- (void)calculateContent:(CGFloat)width force:(BOOL)force;

/**
 *  NIMMessage封装成NIMMessageModel的方法
 *
 *  @param  message 消息体
 *
 *  @return NIMMessageModel实例
 */
- (instancetype)initWithMessage:(NIMMessage*)message;

/**
 *  清楚缓存的排版数据
 */
- (void)cleanCache;

@end
