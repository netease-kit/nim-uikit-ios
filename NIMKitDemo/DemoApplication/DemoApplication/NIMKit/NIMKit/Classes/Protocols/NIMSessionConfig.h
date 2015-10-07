//
//  NIMSessionConfig.h
//  NIMKit
//
//  Created by amao on 8/12/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMMediaItem.h"
#import "NIMCellConfig.h"
#import "NIMKitMessageProvider.h"


@protocol NIMSessionConfig <NSObject>
@optional

/**
 *  可以显示在点击输入框“+”按钮之后的多媒体按钮
 */
- (NSArray *)mediaItems;

/**
 *  是否隐藏多媒体按钮
 *  @param item 多媒体按钮
 */
- (BOOL)shouldHideItem:(NIMMediaItem *)item;


/**
 *  是否禁用输入控件
 */
- (BOOL)disableInputView;

/**
 *  输入控件最大输入长度
 */
- (NSInteger)maxInputLength;

/**
 *  输入控件placeholder
 *
 *  @return placeholder
 */
- (NSString *)inputViewPlaceholder;


/**
 *  一次最多显示的消息条数
 *
 *  @return 消息分页条数
 */
- (NSInteger)messageLimit;


/**
 *  返回多久显示一次消息顶部的时间戳
 *
 *  @return 消息顶部时间戳的显示间隔，秒为单位
 */
- (NSTimeInterval)showTimestampInterval;


/**
 *  是否禁掉语音未读红点
 */
- (BOOL)disableAudioPlayedStatusIcon;

/**
 *  消息数据提供器
 *
 *  @return 消息数据提供者，如果不实现则读取本地聊天记录
 */
- (id<NIMKitMessageProvider>)messageDataProvider;


/**
 *  消息的排版配置，只有使用默认的NIMMessageCell，才会触发此回调
 *
 *  @param message 需要排版的消息
 *
 *  @return 排版配置
 */
- (id<NIMCellLayoutConfig>)layoutConfigWithMessage:(NIMMessage *)message;

@end
