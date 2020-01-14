//
//  NIMTeamMemberListDataSource.h
//  NIMKit
//
//  Created by Netease on 2019/6/17.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMTeamCardMemberItem.h"
#import "NIMMembersFetchOption.h"

typedef void(^NIMTeamListDataBlock)(NSError * _Nullable error, NSString * _Nullable msg);
typedef void(^NIMTeamMuteListDataBlock)(NSError * _Nullable error, NSMutableArray<NIMTeamCardMemberItem *> * _Nullable members);
NS_ASSUME_NONNULL_BEGIN


@protocol NIMTeamOperation <NSObject>

//加人
- (void)addUsers:(NSArray *)userIds
            info:(NSDictionary *)info
      completion:(NIMTeamListDataBlock)completion;

//踢人
- (void)kickUsers:(NSArray *)userIds
       completion:(NIMTeamListDataBlock)completion;

//更新群公告
- (void)updateTeamAnnouncement:(NSString *)content
                    completion:(NIMTeamListDataBlock)completion;

//更新群头像
- (void)updateTeamAvatar:(NSString *)filePath
              completion:(NIMTeamListDataBlock)completion;

//更新群名称
- (void)updateTeamName:(NSString *)name
            completion:(NIMTeamListDataBlock)completion;

//更新群昵称
- (void)updateTeamNick:(NSString *)nick
            completion:(NIMTeamListDataBlock)completion;

//更新群简介
- (void)updateTeamIntro:(NSString *)intro
             completion:(NIMTeamListDataBlock)completion;

//更新群禁言
- (void)updateTeamMute:(BOOL)mute
            completion:(NIMTeamListDataBlock)completion;

//权限更改
- (void)updateTeamJoinMode:(NIMTeamJoinMode)mode
                completion:(NIMTeamListDataBlock)completion;

//邀请模式更改
- (void)updateTeamInviteMode:(NIMTeamInviteMode)mode
                  completion:(NIMTeamListDataBlock)completion;

//群信息修改权限更改
- (void)updateTeamInfoMode:(NIMTeamUpdateInfoMode)mode
                completion:(NIMTeamListDataBlock)completion;

//群通知状态修改
- (void)updateTeamNotifyState:(NIMTeamNotifyState)state
                   completion:(NIMTeamListDataBlock)completion;

//被邀请模式更改
- (void)updateTeamBeInviteMode:(NIMTeamBeInviteMode)mode
                    completion:(NIMTeamListDataBlock)completion;

//增加管理员
- (void)addManagers:(NSArray *)userIds
         completion:(NIMTeamListDataBlock)completion;

//移除管理员
- (void)removeManagers:(NSArray *)userIds
            completion:(NIMTeamListDataBlock)completion;

//群主转移
- (void)transferOwnerWithUserId:(NSString *)newOwnerId
                           leave:(BOOL)leave
                      completion:(NIMTeamListDataBlock)completion;

//修改用户昵称
- (void)updateUserNick:(NSString *)userId
                  nick:(NSString *)nick
            completion:(NIMTeamListDataBlock)completion;

//修改用户禁言状态
- (void)updateUserMuteState:(NSString *)userId
                       mute:(BOOL)mute
                 completion:(NIMTeamListDataBlock)completion;

//查询群成员
- (void)fetchTeamMembersWithOption:(NIMMembersFetchOption * _Nullable )option
                        completion:(NIMTeamListDataBlock)completion;

//查询群禁言列表
- (void)fetchTeamMutedMembersCompletion:(NIMTeamMuteListDataBlock)completion;

//退群
- (void)quitTeamCompletion:(NIMTeamListDataBlock)completion;

//解散群
- (void)dismissTeamCompletion:(NIMTeamListDataBlock)completion;

@end



@protocol NIMTeamMemberListDataSource <NIMTeamOperation>

- (NIMSession *)session;

- (NSInteger)memberNumber;

- (NSMutableArray <NIMTeamCardMemberItem *> *)members;

- (NIMTeamCardMemberItem *)myCard;

- (NIMTeamCardMemberItem *)memberWithUserId:(NSString *)userId;

@end

NS_ASSUME_NONNULL_END
