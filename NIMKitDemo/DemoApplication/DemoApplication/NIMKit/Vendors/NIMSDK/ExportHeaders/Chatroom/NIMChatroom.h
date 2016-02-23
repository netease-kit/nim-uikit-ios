//
//  NIMChatroom.h
//  NIMLib
//
//  Created by Netease.
//  Copyright © 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  聊天室
 */
@interface NIMChatroom : NSObject

/**
 *  聊天室Id
 */
@property (nonatomic,copy)     NSString    *roomId;

/**
 *  聊天室名
 */
@property (nonatomic,copy)     NSString    *name;

/**
 *  公告
 */
@property (nonatomic,copy)     NSString    *announcement;


/**
 *  创建者
 */
@property (nonatomic,copy)     NSString    *creator;


/**
 *  第三方扩展字段，长度限制4K
 */
@property (nonatomic,copy)     NSDictionary *ext;

/**
 *  当前在线用户数量
 */
@property (nonatomic,assign)   NSInteger onlineUserCount;

@end



