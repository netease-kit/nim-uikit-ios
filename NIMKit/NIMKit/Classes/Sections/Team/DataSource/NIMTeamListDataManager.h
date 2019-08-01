//
//  NIMTeamListDataManager.h
//  NIMKit
//
//  Created by Netease on 2019/6/17.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import "NIMTeamMemberListDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface NIMTeamListDataManager : NSObject<NIMTeamMemberListDataSource>

//当前群
@property (nonatomic, readonly) NIMTeam *team;

//群成员
@property (nonatomic, readonly) NSMutableArray <NIMTeamMember *> *members;

//自己的帐号
@property (nonatomic, readonly) NSString *myAccount;

//自己的群成员信息
@property (nonatomic, readonly) NIMTeamMember *myTeamInfo;

//所有群成员的id
@property (nonatomic, readonly) NSMutableArray <NSString *>*memberIds;

//加入模式显示字符串
@property (nonatomic, readonly) NSString *joinModeText;

//所有加入模式显示信息
@property (nonatomic, readonly) NSArray <NSDictionary *> *allJoinModes;

//邀请模式显示字符串
@property (nonatomic, readonly) NSString *inviteModeText;

//所有邀请模式显示信息
@property (nonatomic, readonly) NSArray <NSDictionary *> *allInviteModes;

//更新模式显示字符串
@property (nonatomic, readonly) NSString *updateInfoModeText;

//所有更新模式显示信息
@property (nonatomic, readonly) NSArray <NSDictionary *> *allUpdateInfoModes;

//被邀请模式显示字符串
@property (nonatomic, readonly) NSString *beInviteModeText;

//所有被邀请模式显示信息
@property (nonatomic, readonly) NSArray <NSDictionary *> *allBeInviteModes;

//消息通知显示字符串
@property (nonatomic, readonly) NSString *notifyStateText;

//所有消息通知显示信息
@property (nonatomic, readonly) NSArray <NSDictionary *> *allNotifyStates;

//初始化
- (instancetype)initWithTeam:(NIMTeam *)team session:(NIMSession *)session;

//加人
- (void)addUsers:(NSArray *)userIds
            info:(NSDictionary *)info
      completion:(NIMTeamListDataBlock)completion;

//更新个人群组信息
- (void)reloadMyTeamInfo;

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

//群主转移
- (void)ontransferWithNewOwnerId:(NSString *)newOwnerId
                           leave:(BOOL)leave
                      completion:(NIMTeamListDataBlock)completion;

//权限更改
- (void)updateTeamJoneMode:(NIMTeamJoinMode)mode
                completion:(NIMTeamListDataBlock)completion;

//邀请模式更改
- (void)updateTeamInviteMode:(NIMTeamInviteMode)mode
                  completion:(NIMTeamListDataBlock)completion;

//群信息修改权限更改
- (void)updateTeamInfoMode:(NIMTeamUpdateInfoMode)mode
                completion:(NIMTeamListDataBlock)completion;

//被邀请模式更改
- (void)updateTeamBeInviteMode:(NIMTeamBeInviteMode)mode
                    completion:(NIMTeamListDataBlock)completion;

//退群
- (void)quitTeamCompletion:(NIMTeamListDataBlock)completion;

//解散群
- (void)dismissTeamCompletion:(NIMTeamListDataBlock)completion;

@end

NS_ASSUME_NONNULL_END
