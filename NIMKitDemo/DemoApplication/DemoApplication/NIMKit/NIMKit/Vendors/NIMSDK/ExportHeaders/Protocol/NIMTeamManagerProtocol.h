//
//  NIMTeamManagerProtocol.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMTeam.h"
#import "NIMTeamMember.h"

/**
 *  通用的群组操作block
 *
 *  @param error 错误,如果成功则error为nil
 */
typedef void(^NIMTeamHandler)(NSError *error);

/**
 *  创建群组block
 *
 *  @param error   错误,如果成功则error为nil
 *  @param teamId 群组ID
 */
typedef void(^NIMTeamCreateHandler)(NSError *error,NSString *teamId);

/**
 *  群成员block
 *
 *  @param error   错误,如果成功则error为nil
 *  @param members 群成员列表,内部为NIMTeamMember
 */
typedef void(^NIMTeamMemberHandler)(NSError *error,NSArray *members);

/**
 *  拉取群信息Block
 *
 *  @param error 错误,如果成功则error为nil
 *  @param team  群信息
 */
typedef void(^NIMTeamFetchInfoHandler)(NSError *error,NIMTeam *team);

/**
 *  群申请block
 *
 *  @param error       错误,如果成功则error为nil
 *  @param applyStatus 群申请状态
 */
typedef void(^NIMTeamApplyHandler)(NSError *error,NIMTeamApplyStatus applyStatus);


/**
 *  群组委托
 */
@protocol NIMTeamManagerDelegate <NSObject>

@optional
/**
 *  群组增加回调
 *
 *  @param team 添加的群组
 */
- (void)onTeamAdded:(NIMTeam *)team;

/**
 *  群组更新回调
 *
 *  @param team 更新的群组
 */
- (void)onTeamUpdated:(NIMTeam *)team;

/**
 *  群组移除回调
 *
 *  @param team 被移除的群组
 */
- (void)onTeamRemoved:(NIMTeam *)team;

/**
 *  群组成员变动回调,包括数量增减以及成员属性变动
 *
 *  @param team 变动的群组
 */
- (void)onTeamMemberChanged:(NIMTeam *)team;

@end


/**
 *  群组协议
 */
@protocol NIMTeamManager <NSObject>
/**
 *  获取所有群组
 *
 *  @return 返回所有群组
 */
- (NSArray *)allMyTeams;

/**
 *  根据群组ID获取具体的群组信息
 *
 *  @param teamId 群组ID
 *
 *  @return 群组信息
 */
- (NIMTeam *)teamById:(NSString *)teamId;


/**
 *  根据群组ID判断是否是我所在的群
 *
 *  @param teamId 群组ID
 *
 *  @return 是否在此群组
 */
- (BOOL)isMyTeam:(NSString *)teamId;

/**
 *  创建群组
 *
 *  @param option 创建群选项
 *  @param users 用户ID列表
 *  @param block 完成后的block回调
 */
- (void)createTeam:(NIMCreateTeamOption *)option
              users:(NSArray *)users
         completion:(NIMTeamCreateHandler)block;

/**
 *  解散群组
 *
 *  @param teamId 群组ID
 *  @param block  完成后的block回调
 */
- (void)dismissTeam:(NSString *)teamId
         completion:(NIMTeamHandler)block;

/**
 *  退出群组
 *
 *  @param teamId 群组ID
 *  @param block  完成后的block回调
 */
- (void)quitTeam:(NSString *)teamId
       completion:(NIMTeamHandler)block;

/**
 *  邀请用户入群
 *
 *  @param users  用户ID列表
 *  @param teamId 群组ID
 *  @param postscript 邀请附言
 *  @param block  完成后的block回调
 */
- (void)addUsers:(NSArray  *)users
          toTeam:(NSString *)teamId
      postscript:(NSString *)postscript
      completion:(NIMTeamMemberHandler)block;

/**
 *  从群组内移除成员
 *
 *  @param users   需要移除的用户ID列表
 *  @param teamId  群组ID
 *  @param block   完成后的block回调
 */
- (void)kickUsers:(NSArray *)users
         fromTeam:(NSString *)teamId
      completion:(NIMTeamHandler)block;

/**
 *  更新群组名称
 *
 *  @param teamName 群组名称
 *  @param teamId   群组ID
 *  @param block    完成后的block回调
 */
- (void)updateTeamName:(NSString *)teamName
                teamId:(NSString *)teamId
            completion:(NIMTeamHandler)block;


/**
 *  更新群组验证方式
 *
 *  @param joinMode 验证方式
 *  @param teamId   群组ID
 *  @param block    完成后的block回调
 */
- (void)updateTeamJoinMode:(NIMTeamJoinMode)joinMode
                    teamId:(NSString *)teamId
                completion:(NIMTeamHandler)block;

/**
 *  更新群介绍
 *
 *  @param intro  群介绍
 *  @param teamId 群组ID
 *  @param block  完成后的block回调
 */
- (void)updateTeamIntro:(NSString *)intro
                 teamId:(NSString *)teamId
             completion:(NIMTeamHandler)block;


/**
 *  更新群公告
 *
 *  @param announcement 群公告
 *  @param teamId       群组ID
 *  @param block        完成后的block回调
 */
- (void)updateTeamAnnouncement:(NSString *)announcement
                        teamId:(NSString *)teamId
                    completion:(NIMTeamHandler)block;

/**
 *  更新群自定义信息
 *
 *  @param info         群自定义信息
 *  @param teamId       群组ID
 *  @param block        完成后的block回调
 */
- (void)updateTeamCustomInfo:(NSString *)info
                      teamId:(NSString *)teamId
                  completion:(NIMTeamHandler)block;


/**
 *  更新群信息
 *
 *  @param values 需要更新的群信息键值对
 *  @param teamId 群组ID
 *  @param block  完成后的block回调
 *  @discussion   这个接口可以一次性修改群的多个属性,如名称,公告等,传入的数据键值对是 {@(NIMTeamUpdateTag) : NSString},无效数据将被过滤
 */
- (void)updateTeamInfos:(NSDictionary *)values
                 teamId:(NSString *)teamId
             completion:(NIMTeamHandler)block;



/**
 *  群申请
 *
 *  @param teamId  群组ID
 *  @param message 申请消息
 *  @param block   完成后的block回调
 */
- (void)applyToTeam:(NSString *)teamId
            message:(NSString *)message
         completion:(NIMTeamApplyHandler)block;


/**
 *  通过群申请
 *
 *  @param teamId  群组ID
 *  @param userId  申请的用户ID
 *  @param block   完成后的block回调
 */
- (void)passApplyToTeam:(NSString *)teamId
                 userId:(NSString *)userId
         completion:(NIMTeamApplyHandler)block;

/**
 *  拒绝群申请
 *
 *  @param teamId       群组ID
 *  @param userId       申请的用户ID
 *  @param rejectReason 拒绝理由
 *  @param block        完成后的block回调
 */
- (void)rejectApplyToTeam:(NSString *)teamId
                   userId:(NSString *)userId
             rejectReason:(NSString*)rejectReason
               completion:(NIMTeamHandler)block;


/**
 *  更新成员群昵称
 *
 *  @param userId       群成员ID
 *  @param newNick      新的群成员昵称
 *  @param teamId       群主ID
 *  @param block        完成后的block回调
 */
- (void)updateUserNick:(NSString *)userId
               newNick:(NSString *)newNick
                inTeam:(NSString *)teamId
            completion:(NIMTeamHandler)block;

/**
 *  添加管理员
 *
 *  @param teamId 群组ID
 *  @param users  需要添加为管理员的用户ID列表
 *  @param block  完成后的block回调
 */
- (void)addManagersToTeam:(NSString *)teamId
                    users:(NSArray  *)users
               completion:(NIMTeamHandler)block;

/**
 *  移除管理员
 *
 *  @param teamId 群组ID
 *  @param users  需要移除管理员的用户ID列表
 *  @param block  完成后的block回调
 */
- (void)removeManagersFromTeam:(NSString *)teamId
                         users:(NSArray  *)users
                    completion:(NIMTeamHandler)block;


/**
 *  移交群主
 *
 *  @param teamId     群组ID
 *  @param newOwnerId 新群主ID
 *  @param isLeave    是否同时离开群组
 *  @param block      完成后的block回调
 */
- (void)transferManagerWithTeam:(NSString *)teamId
                     newOwnerId:(NSString *)newOwnerId
                        isLeave:(BOOL)isLeave
                     completion:(NIMTeamHandler)block;


/**
 *  接受入群邀请
 *
 *  @param teamId    群组ID
 *  @param invitorId 邀请者ID
 *  @param block     完成后的block回调
 */
- (void)acceptInviteWithTeam:(NSString*)teamId
                   invitorId:(NSString*)invitorId
                  completion:(NIMTeamHandler)block;


/**
 *  拒绝入群邀请
 *
 *  @param teamId       群组ID
 *  @param invitorId    邀请者ID
 *  @param rejectReason 拒绝原因
 *  @param block        完成后的block回调
 */
- (void)rejectInviteWithTeam:(NSString*)teamId
                   invitorId:(NSString*)invitorId
                rejectReason:(NSString*)rejectReason
                  completion:(NIMTeamHandler)block;


/**
 *  修改群通知状态
 *
 *  @param notify       是否通知
 *  @param teamId       群组ID
 *  @param block        完成后的block回调
 */
- (void)updateNotifyState:(BOOL)notify
                   inTeam:(NSString *)teamId
               completion:(NIMTeamHandler)block;

/**
 *  是否需要消息通知
 *
 *  @param teamId 群Id
 *
 *  @return 是否需要消息通知
 */
- (BOOL)notifyForNewMsg:(NSString *)teamId;


/**
 *  获取群组成员
 *
 *  @param teamId 群组ID
 *  @param block  完成后的block回调
 *  @discussion   绝大多数情况这个请求都是从本地读取缓存并同步返回
 *                但考虑到用户网络等问题SDK有可能没有即时缓存群成员信息,那么这个请求将是个网络请求(增量)
 */
- (void)fetchTeamMembers:(NSString *)teamId
              completion:(NIMTeamMemberHandler)block;


/**
 *  获取群信息
 *
 *  @param teamId 群组ID
 *  @param block  完成后的block回调
 */
- (void)fetchTeamInfo:(NSString *)teamId
           completion:(NIMTeamFetchInfoHandler)block;


/**
 *  获取单个群成员信息
 *
 *  @param userId 用户ID
 *  @param teamId 群组ID
 *  @return       返回成员信息
 *  @discussion   这个值永远不会返回nil,如果传入的userId和teamId是无效值或者本地还没有缓存信息,将返回只带有userId和teamId信息的NIMTeamMember
 */
- (NIMTeamMember *)teamMember:(NSString *)userId
                       inTeam:(NSString *)teamId;

/**
 *  添加群组委托
 *
 *  @param delegate 群组委托
 */
- (void)addDelegate:(id<NIMTeamManagerDelegate>)delegate;

/**
 *  移除群组委托
 *
 *  @param delegate 群组委托
 */
- (void)removeDelegate:(id<NIMTeamManagerDelegate>)delegate;
@end
