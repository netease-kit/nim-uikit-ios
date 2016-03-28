//
//  NIMKitMessageProvider.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMSDK.h"

@class NIMMessageModel;

/**
 *  返回消息结果集的回调
 *  @param messages 消息结果集
 *  @discussion 消息结果需要排序，内部按消息结果已经事先排序处理。
 */
typedef void (^NIMKitDataProvideHandler)(NSError *error, NSArray<NIMMessage *> *messages);

@protocol NIMKitMessageProvider <NSObject>

@optional

/**
 *  下拉加载数据
 *  @param hanlder 返回消息结果集的回调
 *  @param firstMessage 最上部的一条消息，
 *  @discussion 当开始没有数据时，也会触发此回调，firstMessage为nil。
 */
- (void)pullDown:(NIMMessage *)firstMessage handler:(NIMKitDataProvideHandler)handler;


/**
 *  是否需要时间戳显示
 *
 *  @return 是否需要时间戳
 */
- (BOOL)needTimetag;


@end
