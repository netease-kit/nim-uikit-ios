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
#import "NIMInputBarItemType.h"


@protocol NIMSessionConfig <NSObject>
@optional

/**
 *  输入按钮类型，请填入 NIMInputBarItemType 枚举，按顺序排列。不实现则按默认排列。
 */
- (NSArray<NSNumber *> *)inputBarItemTypes;


/**
 *  可以显示在点击输入框“+”按钮之后的多媒体按钮
 */
- (NSArray<NIMMediaItem *> *)mediaItems;


/**
 *  禁用贴图表情
 */
- (BOOL)disableCharlet;


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
 *  是否禁用在贴耳的时候自动切换成听筒模式
 */
- (BOOL)disableProximityMonitor;


/**
 *  在进入会话的时候是否禁止自动去拿历史消息,默认打开
 */
- (BOOL)autoFetchWhenOpenSession;

/**
 *  是否需要处理已读回执
 *
 */
- (BOOL)shouldHandleReceipt;

/**
 *  这次消息时候需要做已读回执的处理
 *
 *  @param message 消息
 *
 *  @return 是否需要
 */
- (BOOL)shouldHandleReceiptForMessage:(NIMMessage *)message;

/**
 *  录音类型
 *
 *  @return 录音类型
 */
- (NIMAudioType)recordType;

/**
 *  最大录音时长
 *
 *  @return 录音时常
 */
- (NSTimeInterval)maxRecordDuration;

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
 *  @return 排版配置，可以继承 NIMCellLayoutDefaultConfig 或者自己定义一个配置类实现 NIMCellLayoutConfig 接口。
 *                  每次新的消息都会调用一次这个方法获取排版配置。
                    如果方法返回nil，会有一套消息默认的配置布局。
 */
- (id<NIMCellLayoutConfig>)layoutConfigWithMessage:(NIMMessage *)message;

@end
