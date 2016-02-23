//
//  NIMChatroomManagerProtocol.h
//  NIMLib
//
//  Created by amao on 12/14/15.
//  Copyright © 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NIMChatroom;
@class NIMChatroomEnterRequest;
@class NIMChatroomMember;
@class NIMChatroomMemberRequest;
@class NIMChatroomMemberUpdateRequest;
@class NIMChatroomMemberKickRequest;
@class NIMChatroomMembersByIdsRequest;
@class NIMHistoryMessageSearchOption;

/**
 *  聊天室网络请求回调
 *
 *  @param error 错误信息
 */
typedef void(^NIMChatroomHandler)(NSError *error);

/**
 *  聊天室成员请求回调
 *
 *  @param error  错误信息
 *  @param member 更新后的聊天室成员信息
 */
typedef void(^NIMChatroomMemberHandler)(NSError *error,NIMChatroomMember *member);

/**
 *  进入聊天室请求回调
 *
 *  @param error    错误信息
 *  @param chatroom 聊天室信息
 *  @param me       自己在聊天室内的信息
 */
typedef void(^NIMChatroomEnterHandler)(NSError *error,NIMChatroom *chatroom,NIMChatroomMember *me);


/**
 *  聊天室信息请求回调
 *
 *  @param error    错误信息
 *  @param chatroom 聊天室信息
 */
typedef void(^NIMChatroomInfoHandler)(NSError *error,NIMChatroom *chatroom);

/**
 *  聊天室成员组网络数据回调
 *
 *  @param error 错误信息
 */
typedef void(^NIMChatroomMembersHandler)(NSError *error, NSArray *members);


/**
 *  拉取服务器聊天消息记录block
 *
 *  @param error  错误,如果成功则error为nil
 *  @param messages 读取的消息列表
 */
typedef void(^NIMFetchChatroomHistoryBlock)(NSError *error,NSArray *messages);



/**
 *  聊天室连接状态
 */
typedef NS_ENUM(NSInteger, NIMChatroomConnectionState) {
    /**
     *  正在进入
     */
    NIMChatroomConnectionStateEntering        = 0,
    /**
     *  进入聊天室成功
     */
    NIMChatroomConnectionStateEnterOK         = 1,
    /**
     *  进入聊天室失败
     */
    NIMChatroomConnectionStateEnterFailed      = 2,
    /**
     *  和聊天室失去连接
     */
    NIMChatroomConnectionStateLoseConnection   = 3,
};

/**
 *  聊天室被踢原因
 */
typedef NS_ENUM(NSInteger, NIMChatroomKickReason) {
    /**
     *  未知原因
     */
    NIMChatroomKickReasonUnknow          = -1,
    /**
     *  聊天室已经解散
     */
    NIMChatroomKickReasonInvalidRoom     = 1,
    /**
     *  被聊天室管理员踢出
     */
    NIMChatroomKickReasonByManager       = 2,
    /**
     *  多端被踢
     */
    NIMChatroomKickReasonByConflictLogin = 3,
};


/**
 *  聊天室管理器回调
 */
@protocol NIMChatroomManagerDelegate <NSObject>

@optional
/**
 *  被踢回调
 *
 *  @param roomId   被踢的聊天室Id
 *  @param resson   被踢原因
 */
- (void)chatroom:(NSString *)roomId beKicked:(NIMChatroomKickReason)reason;


/**
 *  聊天室连接状态变化
 *
 *  @param roomId 聊天室Id
 *  @param step   当前步骤
 */
- (void)chatroom:(NSString *)roomId connectionStateChanged:(NIMChatroomConnectionState)state;

@end

/**
 *  聊天室管理器
 */
@protocol NIMChatroomManager <NSObject>

/**
 *  进入聊天室
 *
 *  @param request    进入聊天室请求
 *  @param completion 进入完成后的回调
 */
- (void)enterChatroom:(NIMChatroomEnterRequest *)request
           completion:(NIMChatroomEnterHandler)completion;

/**
 *  离开聊天室
 *
 *  @param roomId     聊天室ID
 *  @param completion 离开聊天室的回调
 */
- (void)exitChatroom:(NSString *)roomId
          completion:(NIMChatroomHandler)completion;


/**
 *  查询服务器保存的聊天室消息记录
 *
 *  @param session 聊天会话
 *  @param option  查询选项
 *  @param block   消息回调
 */
- (void)fetchMessageHistory:(NSString *)roomId
                     option:(NIMHistoryMessageSearchOption *)option
                     result:(NIMFetchChatroomHistoryBlock)completion;


/**
 *  获取聊天室信息
 *
 *  @param roomId     聊天室ID
 *  @param completion 获取聊天室信息的回调
 *  @discussion 只有已进入聊天室才能够获取对应的聊天室信息
 */
- (void)fetchChatroomInfo:(NSString *)roomId
               completion:(NIMChatroomInfoHandler)completion;



/**
 *  获取聊天室成员
 *
 *  @param request    获取成员请求
 *  @param completion 请求完成回调
 */
- (void)fetchChatroomMembers:(NIMChatroomMemberRequest *)request
                  completion:(NIMChatroomMembersHandler)completion;


/**
 *  根据用户ID获取聊天室成员信息
 *
 *  @param request    获取成员请求
 *  @param completion 请求完成回调
 */
- (void)fetchChatroomMembersByIds:(NIMChatroomMembersByIdsRequest *)request
                       completion:(NIMChatroomMembersHandler)completion;


/**
 *  标记为聊天室管理员
 *
 *  @param request    更新请求
 *  @param completion 请求回调
 */
- (void)markMemberManager:(NIMChatroomMemberUpdateRequest *)request
               completion:(NIMChatroomHandler)completion;

/**
 *  标记为聊天室普通成员
 *
 *  @param request    更新请求
 *  @param completion 请求回调
 */
- (void)markNormalMember:(NIMChatroomMemberUpdateRequest *)request
              completion:(NIMChatroomHandler)completion;

/**
 *  更新用户聊天室黑名单状态
 *
 *  @param request    更新请求
 *  @param completion 请求回调
 */
- (void)updateMemberBlack:(NIMChatroomMemberUpdateRequest *)request
               completion:(NIMChatroomHandler)completion;


/**
 *  更新用户聊天室静言状态
 *
 *  @param request    更新请求
 *  @param completion 请求回调
 */
- (void)updateMemberMute:(NIMChatroomMemberUpdateRequest *)request
              completion:(NIMChatroomHandler)completion;


/**
 *  将特定成员踢出聊天室
 *
 *  @param request    踢出请求
 *  @param completion 请求回调
 */
- (void)kickMember:(NIMChatroomMemberKickRequest *)request
        completion:(NIMChatroomHandler)completion;

/**
 *  添加通知对象
 *
 *  @param delegate 通知对象
 */
- (void)addDelegate:(id<NIMChatroomManagerDelegate>)delegate;

/**
 *  移除通知对象
 *
 *  @param delegate 通知对象
 */
- (void)removeDelegate:(id<NIMChatroomManagerDelegate>)delegate;

@end

