//
//  NIMTeamListDataManager.m
//  NIMKit
//
//  Created by Netease on 2019/6/17.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "NIMTeamListDataManager.h"

@interface NIMTeamListDataManager ()

@property (nonatomic, strong) NIMTeam *team;

@property (nonatomic, strong) NIMSession *session;

@property (nonatomic, strong) NSMutableArray <NIMTeamMember *> *members;

@property (nonatomic, strong) NIMTeamMember *myTeamInfo;

@property (nonatomic, strong) NSMutableArray <NIMTeamCardMemberItem *> *datas;

@property (nonatomic, strong) NIMTeamCardMemberItem *myCard;

@end

@implementation NIMTeamListDataManager

- (instancetype)initWithTeam:(NIMTeam *)team session:(NIMSession *)session {
    if (self = [super init]) {
        _team = team;
        _session = session;
    }
    return self;
}

- (NSMutableArray *)memberIds {
    NSMutableArray *ret = [NSMutableArray array];
    [_members enumerateObjectsUsingBlock:^(NIMTeamMember * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.userId) {
            [ret addObject:obj.userId];
        }
    }];
    return ret;
}

- (NSString *)joinModeText {
    return [NIMTeamListDataManager JoinModeText:_team.joinMode];
}

- (NSArray<NSDictionary *> *)allJoinModes {
    NSArray *ret = @[
                     @{
                         @"value" : @(NIMTeamJoinModeNoAuth),
                         @"title" : [NIMTeamListDataManager JoinModeText:NIMTeamJoinModeNoAuth]
                         },
                     @{
                         @"value" : @(NIMTeamJoinModeNeedAuth),
                         @"title" : [NIMTeamListDataManager JoinModeText:NIMTeamJoinModeNeedAuth]
                         },
                     @{
                         @"value" : @(NIMTeamJoinModeRejectAll),
                         @"title" : [NIMTeamListDataManager JoinModeText:NIMTeamJoinModeRejectAll]
                         },
                     ];
    return ret;
}

- (NSString *)inviteModeText {
    return [NIMTeamListDataManager InviteModeText:_team.inviteMode];
}

- (NSArray<NSDictionary *> *)allInviteModes {
    NSArray *ret = @[
                     @{
                         @"value" : @(NIMTeamInviteModeManager),
                         @"title" : [NIMTeamListDataManager InviteModeText:NIMTeamInviteModeManager]
                         },
                     @{
                         @"value" : @(NIMTeamInviteModeAll),
                         @"title" : [NIMTeamListDataManager InviteModeText:NIMTeamInviteModeAll]
                         },
                     ];
    return ret;
}

- (NSString *)beInviteModeText {
    return [NIMTeamListDataManager BeInviteModeText:_team.beInviteMode];
}
- (NSArray<NSDictionary *> *)allBeInviteModes {
    NSArray *ret = @[
                     @{
                         @"value" : @(NIMTeamBeInviteModeNeedAuth),
                         @"title" : [NIMTeamListDataManager BeInviteModeText:NIMTeamBeInviteModeNeedAuth]
                         },
                     @{
                         @"value" : @(NIMTeamBeInviteModeNoAuth),
                         @"title" : [NIMTeamListDataManager BeInviteModeText:NIMTeamBeInviteModeNoAuth]
                         },
                     ];
    return ret;
}


- (NSString *)updateInfoModeText {
    return [NIMTeamListDataManager UpdateInfoModeText:_team.updateInfoMode];
}

- (NSArray<NSDictionary *> *)allUpdateInfoModes {
    NSArray *ret = @[
                     @{
                         @"value" : @(NIMTeamUpdateInfoModeManager),
                         @"title" : [NIMTeamListDataManager UpdateInfoModeText:NIMTeamUpdateInfoModeManager]
                         },
                     @{
                         @"value" : @(NIMTeamUpdateInfoModeAll),
                         @"title" : [NIMTeamListDataManager UpdateInfoModeText:NIMTeamUpdateInfoModeAll]
                         },
                     ];
    return ret;
}

- (NSString *)notifyStateText {
    NIMKitTeamNotifyState state = [NIMTeamListDataManager kitTeamNotifyStateWithState:_team.notifyStateForNewMsg];
    return [NIMTeamListDataManager notifyStateText:state];
}

- (NSArray *)allNotifyStates {
    NSArray *ret = @[
                       @{
                           @"value" : @(NIMKitTeamNotifyStateAll),
                           @"title" : [NIMTeamListDataManager notifyStateText:NIMKitTeamNotifyStateAll]
                         },
                       @{
                           @"value" : @(NIMKitTeamNotifyStateNone),
                           @"title" : [NIMTeamListDataManager notifyStateText:NIMKitTeamNotifyStateNone]
                        },
                       @{
                           @"value" : @(NIMKitTeamNotifyStateOnlyManager),
                           @"title" : [NIMTeamListDataManager notifyStateText:NIMKitTeamNotifyStateOnlyManager]
                        },
                    ];
    return ret;
}

- (NSString *)memberTypeString:(NIMKitTeamMemberType)type {
    switch (type) {
        case NIMKitTeamMemberTypeNormal:
            return @"普通成员";
        case NIMKitTeamMemberTypeOwner:
            return @"群主";
        case NIMKitTeamMemberTypeManager:
            return @"管理员";
        default:
            return @"未知";
    }
}

#pragma mark - Function
- (NSString *)myAccount {
    return [[NIMSDK sharedSDK].loginManager currentAccount];
}

- (void)addUsers:(NSArray *)userIds
            info:(NSDictionary *)info
      completion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    NSString *postscript = info[@"postscript"];
    NSString *attach = info[@"attach"];
    __block NSString *msg = nil;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].teamManager addUsers:userIds
                                      toTeam:teamId
                                  postscript:postscript
                                      attach:attach
                                  completion:^(NSError * _Nullable error, NSArray<NIMTeamMember *> * _Nullable members) {
        if (!error) {
            if (weakSelf.team.type == NIMTeamTypeNormal) { //高级群需要验证，普通群直接进
                [weakSelf addMembers:members];
                msg = @"邀请成功";
            } else {
                if (weakSelf.team.beInviteMode == NIMTeamBeInviteModeNeedAuth) {
                    msg = @"邀请成功，等待验证";
                } else {
                    [weakSelf addMembers:members];
                    msg = @"邀请成功";
                }
            }
        } else {
            msg = [NSString stringWithFormat:@"邀请失败 code:%zd",error.code];
        }
        
        if (completion) {
            completion(error, msg);
        }
    }];
}



- (void)reloadMyTeamInfo {
    if (!_myTeamInfo) {
        return;
    }
    NSString *userId = _myTeamInfo.userId;
    NSString *teamId = _myTeamInfo.teamId;
    _myTeamInfo = [[NIMSDK sharedSDK].teamManager teamMember:userId
                                                      inTeam:teamId];
}

- (void)updateTeamAnnouncement:(NSString *)content
                    completion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    NSString *announcement = content ?: @"";
    __block NSString *msg = nil;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].teamManager updateTeamAnnouncement:announcement
                                                    teamId:teamId
                                                completion:^(NSError * _Nullable error) {
        if (!error) {
            weakSelf.team.announcement = content;
        }
        if (completion) {
            completion(error, msg);
        }
    }];
}

- (void)updateTeamAvatar:(NSString *)filePath
              completion:(NIMTeamListDataBlock)completion {
    __block NSString *msg = nil;
    __weak typeof(self) wself = self;
    [[NIMSDK sharedSDK].resourceManager upload:filePath scene:NIMNOSSceneTypeAvatar progress:nil completion:^(NSString *urlString, NSError *error) {
        if (!error && urlString && wself) {
            NSDictionary *dic =@{
                                    @(NIMUserInfoUpdateTagAvatar) : urlString
                                 };
            [[NIMSDK sharedSDK].userManager updateMyUserInfo:dic completion:^(NSError *error) {
                if (error) {
                    msg = @"设置头像失败，请重试";
                } else {
                    wself.team.avatarUrl = urlString;
                }
                if (completion) {
                    completion(error, msg);
                }
            }];
        } else {
            msg = @"图片上传失败，请重试";
            if (completion) {
                completion(error, msg);
            }
        }
    }];
}

- (void)updateTeamName:(NSString *)name
            completion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    __block NSString *msg = nil;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].teamManager updateTeamName:name teamId:teamId completion:^(NSError *error) {
        if (!error) {
            weakSelf.team.teamName = name;
            msg = @"修改成功";
        }else{
            msg = [NSString stringWithFormat:@"修改失败 code:%zd",error.code];
        }
        if (completion) {
            completion(error, msg);
        }
    }];
}

- (void)updateTeamNick:(NSString *)nick
            completion:(NIMTeamListDataBlock)completion {
    NSString *currentUserId = [NIMSDK sharedSDK].loginManager.currentAccount;
    NSString *teamId = _team.teamId;
    __block NSString *msg = nil;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].teamManager updateUserNick:currentUserId newNick:nick inTeam:teamId completion:^(NSError *error) {
        if (!error) {
            weakSelf.myTeamInfo.nickname = nick;
            msg = @"修改成功";
        }else{
            msg = [NSString stringWithFormat:@"修改失败 code:%zd",error.code];
        }
        
        if (completion) {
            completion(error, msg);
        }
    }];
}

- (void)updateTeamIntro:(NSString *)intro
             completion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    __block NSString *msg = nil;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].teamManager updateTeamIntro:intro teamId:teamId completion:^(NSError *error) {
        if (!error) {
            weakSelf.team.intro = intro;
            msg = @"修改成功";
        }else{
            msg = [NSString stringWithFormat:@"修改失败 code:%zd",error.code];
        }
        if (completion) {
            completion(error, msg);
        }
    }];
}

- (void)ontransferWithNewOwnerId:(NSString *)newOwnerId
                           leave:(BOOL)leave
                      completion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    __block NSString *msg = nil;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].teamManager transferManagerWithTeam:teamId
                                                 newOwnerId:newOwnerId
                                                    isLeave:leave
                                                 completion:^(NSError *error) {
        if (!error) {
            NIMTeamMember *memberInfo = [weakSelf teamInfo:newOwnerId];
            memberInfo.type = NIMTeamMemberTypeOwner;
            msg = @"转移成功！";
        }else{
            msg = [NSString stringWithFormat:@"转移失败！code:%zd",error.code];
        }
                                                     
        if (completion) {
            completion(error, msg);
        }
    }];
}

- (void)updateTeamJoneMode:(NIMTeamJoinMode)mode
                completion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    __block NSString *msg = nil;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].teamManager updateTeamJoinMode:mode teamId:teamId completion:^(NSError *error) {
        if (!error) {
            weakSelf.team.joinMode = mode;
            msg = @"修改成功";
        }else{
            msg = [NSString stringWithFormat:@"修改失败 code:%zd",error.code];
        }
        
        if (completion) {
            completion(error, msg);
        }
    }];
}

- (void)updateTeamInviteMode:(NIMTeamInviteMode)mode
                  completion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    __block NSString *msg = nil;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].teamManager updateTeamInviteMode:mode teamId:teamId completion:^(NSError *error) {
        if (!error) {
            weakSelf.team.inviteMode = mode;
            msg = @"修改成功";
        } else {
            msg = [NSString stringWithFormat:@"修改失败 code:%zd",error.code];
        }
        
        if (completion) {
            completion(error, msg);
        }
    }];
}

- (void)updateTeamInfoMode:(NIMTeamUpdateInfoMode)mode
                completion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    __block NSString *msg = nil;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].teamManager updateTeamUpdateInfoMode:mode teamId:teamId completion:^(NSError *error) {
        if (!error) {
            weakSelf.team.updateInfoMode = mode;
            msg = @"修改成功";
        } else {
            msg = [NSString stringWithFormat:@"修改失败 code:%zd",error.code];
        }
        
        if (completion) {
            completion(error, msg);
        }
    }];
}

- (void)updateTeamBeInviteMode:(NIMTeamBeInviteMode)mode
                    completion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    __block NSString *msg = nil;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].teamManager updateTeamBeInviteMode:mode teamId:teamId completion:^(NSError *error) {
        if (!error) {
            weakSelf.team.beInviteMode = mode;
            msg = @"修改成功";
        }else{
            msg = [NSString stringWithFormat:@"修改失败 code:%zd",error.code];
        }
        
        if (completion) {
            completion(error, msg);
        }
    }];
}

- (void)quitTeamCompletion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    __block NSString *msg = nil;
    [[NIMSDK sharedSDK].teamManager quitTeam:teamId completion:^(NSError *error) {
        if (error) {
            msg = [NSString stringWithFormat:@"退出失败 code:%zd",error.code];
        }
        if (completion) {
            completion(error, msg);
        }
    }];
}

- (void)dismissTeamCompletion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    __block NSString *msg = nil;
    [[NIMSDK sharedSDK].teamManager dismissTeam:teamId completion:^(NSError *error) {
        if (error) {
            msg = [NSString stringWithFormat:@"解散失败 code:%zd",error.code];
        }
        if (completion) {
            completion(error, msg);
        }
    }];
}

#pragma mark - Private
- (void)addMembers:(NSArray <NIMTeamMember *>*)members {
    if (!_datas) {
        _datas = [NSMutableArray array];
    }
    
    for (NIMTeamMember *member in members) {
        NIMTeamCardMemberItem *item = [[NIMTeamCardMemberItem alloc] initWithTeamId:_team.teamId
                                                                             member:member];;
        [_datas addObject:item];
        [_members addObject:member];
    }
}

- (void)removeMembers:(NSArray <NSString *> *)userIds {
    for (NSString *userId in userIds) {
        [self removeUserInDatas:userId];
        [self removeUserInMembers:userId];
    }
}

- (void)removeUserInDatas:(NSString *)userId {
    for (NIMTeamCardMemberItem *obj in _datas) {
        if ([obj.userId isEqualToString:userId]) {
            [_datas removeObject:obj];
            break;
        }
    }
}

- (void)removeUserInMembers:(NSString *)userId {
    for (NIMTeamMember *obj in _members) {
        if ([obj.userId isEqualToString:userId]) {
            [_members removeObject:obj];
            break;
        }
    }
}

- (NIMTeamMember*)teamInfo:(NSString*)uid{
    for (NIMTeamMember *member in self.members) {
        if ([member.userId isEqualToString:uid]) {
            return member;
        }
    }
    return nil;
}

- (void)setMyTeamInfo:(NIMTeamMember *)myTeamInfo {
    _myTeamInfo = myTeamInfo;
    _myCard = [[NIMTeamCardMemberItem alloc] initWithTeamId:_team.teamId
                                                     member:myTeamInfo];
}

- (void)setMembers:(NSMutableArray<NIMTeamMember *> *)members {
    _members = members;
    
    if (!_datas) {
        _datas = [NSMutableArray array];
    } else {
        [_datas removeAllObjects];
    }
    
    for (NIMTeamMember *member in members) {
        NIMTeamCardMemberItem *item = [[NIMTeamCardMemberItem alloc] initWithTeamId:_team.teamId
                                                                             member:member];
        [_datas addObject:item];
    }
}

#pragma mark - <NIMTeamMemberListDataSource>
- (NSInteger)memberNumber {
    return [_team memberNumber];
}

- (void)fetchTeamMembersWithOption:(NIMMembersFetchOption *)option
                        completion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    __weak typeof(self) weakSelf = self;
    if (option && !option.isRefresh) {
        if (completion) {
            completion(nil, nil);
        }
        return;
    }
    [[NIMSDK sharedSDK].teamManager fetchTeamMembers:teamId completion:^(NSError * _Nullable error, NSArray<NIMTeamMember *> * _Nullable members) {
        NSString *msg = nil;
        if (!error) {
            
            //my team info
            NSString *currentAccount = [NIMSDK sharedSDK].loginManager.currentAccount;
            for (NIMTeamMember *member in members) {
                if ([member.userId isEqualToString:currentAccount]) {
                    weakSelf.myTeamInfo = member;
                    break;
                }
            }
            
            //members
            weakSelf.members = [NSMutableArray arrayWithArray:members];
        } else if (error.code == NIMRemoteErrorCodeTeamNotMember) {
            msg = @"你已经不在群里";
        } else {
            msg = [NSString stringWithFormat:@"拉好友失败 error: %zd",error.code];
        }
        if (completion) {
            completion(error, msg);
        }
    }];
}

- (void)kickUsers:(NSArray *)userIds
       completion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    __weak typeof(self) wself = self;
    __block NSString *msg = nil;
    [[NIMSDK sharedSDK].teamManager kickUsers:userIds fromTeam:teamId completion:^(NSError *error) {
        if (!error) {
            [wself removeMembers:userIds];
        } else {
            msg = [NSString stringWithFormat:@"移除失败 code: %zd", error.code];
        }
        if (completion) {
            completion(error, msg);
        }
    }];
}

- (void)updateUserNick:(NSString *)userId
                  nick:(NSString *)nick
            completion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    __block NSString *msg = nil;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].teamManager updateUserNick:userId newNick:nick inTeam:teamId completion:^(NSError *error) {
        if (!error) {
            [weakSelf.members enumerateObjectsUsingBlock:^(NIMTeamMember * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.userId isEqualToString:userId]) {
                    obj.nickname = nick;
                    *stop = YES;
                }
            }];
            msg = @"修改成功";
        }else{
            msg = @"修改失败";
        }
        if (completion) {
            completion(error, msg);
        }
    }];
}

- (void)updateUserMuteState:(NSString *)userId
                       mute:(BOOL)mute
                 completion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    __block NSString *msg = nil;
    [[NIMSDK sharedSDK].teamManager updateMuteState:mute
                                             userId:userId
                                             inTeam:teamId
                                         completion:^(NSError *error) {
                                             if (!error) {
                                                 msg = @"修改成功";
                                             }else{
                                                 msg = @"修改失败";
                                             }
                                             if (completion) {
                                                 completion(error, msg);
                                             }
                                         }];
}

- (void)addManagers:(NSArray *)userIds
         completion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    __block NSString *msg = nil;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].teamManager addManagersToTeam:teamId users:userIds completion:^(NSError *error) {
        if (!error) {
            for (NSString *userId in userIds) {
                [weakSelf.members enumerateObjectsUsingBlock:^(NIMTeamMember * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj.userId isEqualToString:userId]) {
                        obj.type = NIMTeamMemberTypeManager;
                        *stop = YES;
                    }
                }];
                
                [weakSelf.datas enumerateObjectsUsingBlock:^(NIMTeamCardMemberItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj.userId isEqualToString:userId]) {
                        obj.userType = NIMKitTeamMemberTypeManager;
                        *stop = YES;
                    }
                }];
            }
            msg = @"修改成功";
        }else{
            msg = @"修改失败";
        }
        if (completion) {
            completion(error, msg);
        }
    }];
}

- (void)removeManagers:(NSArray *)userIds
            completion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    __block NSString *msg = nil;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].teamManager removeManagersFromTeam:teamId users:userIds completion:^(NSError *error) {
        if (!error) {
            for (NSString *userId in userIds) {
                [weakSelf.members enumerateObjectsUsingBlock:^(NIMTeamMember * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj.userId isEqualToString:userId]) {
                        obj.type = NIMTeamMemberTypeNormal;
                        *stop = YES;
                    }
                }];
                
                [weakSelf.datas enumerateObjectsUsingBlock:^(NIMTeamCardMemberItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj.userId isEqualToString:userId]) {
                        obj.userType = NIMKitTeamMemberTypeNormal;
                        *stop = YES;
                    }
                }];
            }
            msg = @"修改成功";
        }else{
            msg = @"修改失败";
        }
        
        if (completion) {
            completion(error, msg);
        }
    }];
}

//群通知状态修改
- (void)updateTeamNotifyState:(NIMKitTeamNotifyState)state
                   completion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    __block NSString *msg = nil;
    NIMTeamNotifyState notifyState = [NIMTeamListDataManager sdkTeamNotifyStateWithState:state];
    [[[NIMSDK sharedSDK] teamManager] updateNotifyState:notifyState
                                                 inTeam:teamId
                                             completion:^(NSError *error) {
         if (error) {
             msg = [NSString stringWithFormat:@"修改失败 code:%zd",error.code];
         }
         if (completion) {
             completion(error, msg);
         }
     }];
}

//查询群通知状态
- (NIMKitTeamNotifyState)notifyState {
    NSString *teamId = _team.teamId;
    NIMTeamNotifyState ret = [[NIMSDK sharedSDK].teamManager notifyStateForNewMsg:teamId];
    return [NIMTeamListDataManager kitTeamNotifyStateWithState:ret];
}

#pragma mark - Helper
+ (NSString *)BeInviteModeText:(NIMTeamBeInviteMode)mode {
    switch (mode) {
        case NIMTeamBeInviteModeNeedAuth:
            return @"需要验证";
        case NIMTeamBeInviteModeNoAuth:
            return @"不需要验证";
        default:
            return @"未知";
    }
}

+ (NSString *)UpdateInfoModeText:(NIMTeamUpdateInfoMode)mode {
    switch (mode) {
        case NIMTeamUpdateInfoModeManager:
            return @"管理员";
        case NIMTeamUpdateInfoModeAll:
            return @"所有人";
        default:
            return @"未知权限";
    }
}

+ (NSString *)InviteModeText:(NIMTeamInviteMode)mode {
    switch (mode) {
        case NIMTeamInviteModeManager:
            return @"管理员";
        case NIMTeamInviteModeAll:
            return @"所有人";
        default:
            return @"未知权限";
    }
}

+ (NSString *)JoinModeText:(NIMTeamJoinMode)mode {
    switch (mode) {
        case NIMTeamJoinModeNoAuth:
            return @"允许任何人";
        case NIMTeamJoinModeNeedAuth:
            return @"需要验证";
        case NIMTeamJoinModeRejectAll:
            return @"拒绝任何人";
        default:
            return @"";
    }
}

+ (NSString *)notifyStateText:(NIMKitTeamNotifyState)state {
    switch (state) {
        case NIMKitTeamNotifyStateAll:
            return @"提醒所有消息";
        case NIMKitTeamNotifyStateNone:
            return @"不提醒任何消息";
        case NIMKitTeamNotifyStateOnlyManager:
            return @"只提醒管理员消息";
        default:
            return @"未知模式";
    }
}

+ (NIMKitTeamNotifyState)kitTeamNotifyStateWithState:(NIMTeamNotifyState)state {
    switch (state) {
        case NIMTeamNotifyStateAll:
            return NIMKitTeamNotifyStateAll;
        case NIMTeamNotifyStateNone:
            return NIMKitTeamNotifyStateNone;
        case NIMTeamNotifyStateOnlyManager:
            return NIMKitTeamNotifyStateOnlyManager;
        default:
            return NIMKitTeamNotifyStateAll;
    }
}

+ (NIMTeamNotifyState)sdkTeamNotifyStateWithState:(NIMKitTeamNotifyState)state {
    switch (state) {
        case NIMKitTeamNotifyStateAll:
            return NIMTeamNotifyStateAll;
        case NIMKitTeamNotifyStateNone:
            return NIMTeamNotifyStateNone;
        case NIMKitTeamNotifyStateOnlyManager:
            return NIMTeamNotifyStateOnlyManager;
        default:
            return NIMTeamNotifyStateAll;
    }
}

@end
