//
//  NIMChatroomMemberRequest.h
//  NIMLib
//
//  Created by Netease.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class NIMChatroomMember;

/**
 *  聊天室成员类型
 */
typedef NS_ENUM(NSInteger, NIMChatroomFetchMemberType){
    /**
     *  聊天室固定成员，包括创建者,管理员,普通等级用户,受限用户(禁言+黑名单)，有数量上限
     */
    NIMChatroomFetchMemberTypeRegular,
    /**
     *  聊天室临时成员，只有在线时才能在列表中看到,数量无上限
     */
    NIMChatroomFetchMemberTypeTemp,
    /**
     *  聊天室在线的固定成员
     */
    NIMChatroomFetchMemberTypeRegularOnline,
};


/**
 *  聊天室获取成员请求
 */
@interface NIMChatroomMemberRequest : NSObject

/**
 *  聊天室ID
 */
@property (nonatomic,copy)   NSString *roomId;

/**
 *  聊天室成员类型
 */
@property (nonatomic,assign) NIMChatroomFetchMemberType type;

/**
 *  最后一位成员锚点，不包括此成员。填nil会使用当前服务器最新时间开始查询，即第一页。
 */
@property (nullable,nonatomic,strong) NIMChatroomMember *lastMember;

/**
 *  获取聊天室成员个数
 */
@property (nonatomic,assign) NSUInteger limit;


@end




/**
 *  根据用户ID获取聊天室成员请求
 */
@interface NIMChatroomMembersByIdsRequest : NSObject

/**
 *  聊天室ID
 */
@property (nonatomic,copy)   NSString *roomId;

/**
 *  用户ID列表，最多20个
 */
@property (nonatomic,copy)   NSArray<NSString *>  *userIds;


@end





/**
 *  聊天室成员标记请求
 */
@interface NIMChatroomMemberUpdateRequest : NSObject

/**
 *  聊天室ID
 */
@property (nonatomic,copy) NSString *roomId;

/**
 *  用户ID
 */
@property (nonatomic,copy) NSString *userId;

/**
 *  标记是否有效
 */
@property (nonatomic,assign) BOOL enable;

/**
 *  操作通知事件扩展
 */
@property (nullable,nonatomic,copy) NSString *notifyExt;

@end


/**
 *  聊天室踢人请求
 */
@interface NIMChatroomMemberKickRequest : NSObject
/**
 *  聊天室ID
 */
@property (nonatomic,copy) NSString *roomId;

/**
 *  用户ID，仅管理员可以踢人；如userId是管理员仅创建者可以踢.
 */
@property (nonatomic,copy) NSString *userId;

/**
 *  被踢通知扩展字段
 */
@property (nullable,nonatomic,copy) NSString *notifyExt;

@end

NS_ASSUME_NONNULL_END
