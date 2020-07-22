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


@property (nonatomic, readonly) UIEdgeInsets  contentViewInsets;

@property (nonatomic, readonly) UIEdgeInsets  bubbleViewInsets;

@property (nonatomic, readonly) UIEdgeInsets  replyContentViewInsets;

@property (nonatomic, readonly) UIEdgeInsets  replyBubbleViewInsets;

@property (nonatomic, strong) NSString *pinUserName;

@property (nonatomic, readonly) CGPoint avatarMargin;

@property (nonatomic, readonly) CGPoint nickNameMargin;

@property (nonatomic, readonly) CGSize avatarSize;

@property (nonatomic, readonly) BOOL shouldShowAvatar;

@property (nonatomic, readonly) BOOL shouldShowNickName;

@property (nonatomic, readonly) BOOL shouldShowLeft;

@property (nonatomic) BOOL focreShowAvatar; //强制显示头像

@property (nonatomic) BOOL focreShowNickName; //强制显示昵称

@property (nonatomic) BOOL focreShowLeft; //强制左边显示

@property (nonatomic) BOOL shouldShowReadLabel; //显示已读

@property (nonatomic) BOOL shouldShowSelect; //显示选择按钮

@property (nonatomic) BOOL disableSelected; //不允许用户选择

@property (nonatomic) BOOL selected; //选择状态




@property (nonatomic) BOOL shouldShowPinContent; //显示PIN标记

/*** 该消息的父、子消息 ***/
@property (nonatomic) BOOL enableSubMessages;

@property (nonatomic,strong) NIMMessage *parentMessage;

@property (nonatomic,copy) NSArray *childMessages;

@property (nonatomic,assign) NSInteger childMessagesCount;


/*** 该消息回复的消息内容 ****/
@property (nonatomic,strong) NIMMessage *repliedMessage;

@property (nonatomic) BOOL enableRepliedContent; //显示被回复消息内容

/*** 快捷回复数据 ***/
@property (nonatomic) BOOL enableQuickComments; //显示快捷表情回复内容

@property (nonatomic,strong) NSMapTable *quickComments;

@property (nonatomic) CGSize emoticonsContainerSize; //显示快捷表情回复内容


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


/**
 *  计算内容大小
 */
- (CGSize)contentSize:(CGFloat)width;

/**
 *  计算回复内容大小
 */
- (CGSize)replyContentSize:(CGFloat)width;

/**
 *  更新布局配置
 */
- (void)updateLayoutConfig;

/**
 * thread talk 显示被回复内容
 *
 * @return 是否显示回复内容
 */
- (BOOL)needShowRepliedContent;

/**
 *  @return 是否显示该消息被回复的条数内容
 */
- (BOOL)needShowReplyCountContent;

/**
 *  @return 是否显示快捷表情内容
 */
- (BOOL)needShowEmoticonsView;

/**
 *  @param message 目标消息
 *  @param completion 完成回调
 */
- (void)quickComments:(NIMMessage *)message
           completion:(void(^)(NSMapTable *))completion;

@end
