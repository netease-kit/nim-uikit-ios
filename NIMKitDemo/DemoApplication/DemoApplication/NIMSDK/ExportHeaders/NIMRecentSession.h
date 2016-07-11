//
//  NIMRecentSession.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class NIMMessage;
@class NIMSession;

/**
 *  最近会话
 */
@interface NIMRecentSession : NSObject

/**
 *  当前会话
 */
@property (nullable,nonatomic,readonly,copy)   NIMSession  *session;

/**
 *  最后一条消息
 */
@property (nullable,nonatomic,readonly,strong)   NIMMessage  *lastMessage;

/**
 *  未读消息数
 */
@property (nonatomic,readonly,assign)   NSInteger   unreadCount;

@end


NS_ASSUME_NONNULL_END