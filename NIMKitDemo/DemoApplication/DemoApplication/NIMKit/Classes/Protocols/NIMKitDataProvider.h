//
//  NIMKitDataProvider.h
//  NIMKit
//
//  Created by amao on 8/13/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NIMSession;
@class NIMKitInfo;

@protocol NIMKitDataProvider <NSObject>

@optional

/**
 *  上层提供用户信息的接口
 *
 *  @param userId  用户ID
 *  @param session 所在的会话
 *
 *  @return 用户信息
 */
- (NIMKitInfo *)infoByUser:(NSString *)userId
                 inSession:(NIMSession *)session;

/**
 *  上层提供用户信息的接口
 *
 *  @param userId  用户ID
 *  @param message 所在的消息
 *
 *  @return 用户信息
 */
- (NIMKitInfo *)infoByUser:(NSString *)userId
               withMessage:(NIMMessage *)message;

/**
 *  上层提供群组信息的接口
 *
 *  @param teamId 群组ID
 *
 *  @return 群组信息
 */
- (NIMKitInfo *)infoByTeam:(NSString *)teamId;


/**
 *  当消息作为提醒时(即会话里灰色的提示条)，需要显示的文本
 *
 *  @param message 消息
 *
 *  @return 显示文本
 */
- (NSString *)tipMessage:(NIMMessage *)message;


@end
