//
//  NIMMessageChatroomExtension.h
//  NIMLib
//
//  Created by Netease.
//  Copyright © 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  消息内的聊天室拓展信息
 *  @discussion 用户进入聊天室时填的 NIMChatroomEnterRequest 中的额外信息将在发送聊天室信息时将转换为消息中聊天拓展信息
 */
@interface NIMMessageChatroomExtension : NSObject
/**
 *  用户在聊天室内的昵称
 */
@property (nonatomic,copy)  NSString    *roomNickname;

/**
 *  用户在聊天室内的头像
 */
@property (nonatomic,copy)  NSString    *roomAvatar;

/**
 *  用户在聊天室内的头像缩略图
 */

@property (nonatomic,copy,readonly)  NSString    *roomAvatarThumbnail;

/**
 *  用户在当前聊天室的拓展信息
 */
@property (nonatomic,strong) NSDictionary *roomExt;

@end


