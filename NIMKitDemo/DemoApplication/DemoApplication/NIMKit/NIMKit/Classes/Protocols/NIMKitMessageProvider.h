//
//  NIMKitMessageProvider.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NIMMessageModel;
@class NIMMessage;
/**
 *  返回消息结果集的回调
 *  @param messages 消息结果集
 *  @discussion 消息结果需要排序，内部按消息结果已经事先排序处理。
 */
typedef void (^NIMKitDataProvideHandler)(NSError *error, NSArray *messages);

@protocol NIMKitMessageProvider <NSObject>

/**
 *  下拉加载数据
 *  @param hanlder 返回消息结果集的回调
 *  @param firstMessage 最上部的一条消息，
 *  @discussion 当开始没有数据时，也会触发此回调，firstMessage为nil。
 */
- (void)pullDown:(NIMMessage *)firstMessage handler:(NIMKitDataProvideHandler)handler;


@end
