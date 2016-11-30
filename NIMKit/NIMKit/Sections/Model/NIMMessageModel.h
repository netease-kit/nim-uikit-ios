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
@property (nonatomic,strong) NIMMessage *message;

/**
 *  时间戳
 *
 *  @discussion 这个时间戳为缓存的界面显示的时间戳，消息发出的时候记录下的本地时间，
 *              由于 NIMMessage 在服务器确认收到后会将自身发送时间 timestamp 字段修正为服务器时间，所以缓存当前发送的本地时间避免刷新时由于发送时间修
 *              改导致的消息界面位置跳跃。
 *              messageTime 和 message.timestamp 会有一定的误差。
 */
@property (nonatomic,readonly) NSTimeInterval messageTime;
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
