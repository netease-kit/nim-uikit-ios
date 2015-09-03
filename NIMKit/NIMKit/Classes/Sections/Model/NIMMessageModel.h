//
//  NIMMessageModel.h
//  NIMKit
//
//  Created by NetEase.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMCellConfig.h"

@interface NIMMessageModel : NSObject

/**
 *  消息数据
 */
@property (nonatomic, strong) NIMMessage *message;

/**
 *  消息对应的布局配置
 */
@property (nonatomic,strong) id<NIMCellLayoutConfig> layoutConfig;


@property (nonatomic, readonly) CGSize     contentSize;

@property (nonatomic, readonly) UIEdgeInsets  contentViewInsets;

@property (nonatomic, readonly) UIEdgeInsets  bubbleViewInsets;

@property (nonatomic, readonly) BOOL shouldShowAvatar;

@property (nonatomic, readonly) BOOL shouldShowNickName;

/**
 *  计算内容大小
 *
 *  @param width 内容宽度
 */
- (void)calculateContent:(CGFloat)width;

/**
 *  NIMMessage封装成NIMMessageModel的方法
 *
 *  @param  message 消息体
 *
 *  @return NIMMessageModel实例
 */
- (instancetype)initWithMessage:(NIMMessage*)message;

@end
