//
//  NIMTeamListDataManager.m
//  NIMKit
//
//  Created by Netease on 2019/6/17.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "NIMTeamListDataManager.h"
#import "NIMGlobalMacro.h"

NSString *const kNIMTeamListDataTeamInfoUpdate = @"kNIMTeamListDataTeamInfoUpdate";
NSString *const kNIMTeamListDataTeamMembersChanged = @"kNIMTeamListDataTeamMembersChanged";

@interface NIMTeamListDataManager ()<NIMTeamManagerDelegate>

@property (nonatomic, strong) NIMTeam *team;

@property (nonatomic, strong) NIMSession *session;

@property (nonatomic, strong) NSMutableArray <NIMTeamCardMemberItem *> *members;

@property (nonatomic, strong) NIMTeamMember *myTeamInfo;

@property (nonatomic, strong) NIMTeamCardMemberItem *myCard;

@end

@implementation NIMTeamListDataManager

- (void)dealloc {
    if (_team.type == NIMTeamTypeSuper) {
        [[NIMSDK sharedSDK].superTeamManager removeDelegate:self];
    } else {
        [[NIMSDK sharedSDK].teamManager removeDelegate:self];
    }
}

- (instancetype)initWithTeam:(NIMTeam *)team session:(NIMSession *)session {
    if (self = [super init]) {
        _team = team;
        _session = session;
        if (team.type == NIMTeamTypeSuper) {
            [[NIMSDK sharedSDK].superTeamManager addDelegate:self];
        } else {
            [[NIMSDK sharedSDK].teamManager addDelegate:self];
        }
        [self reloadMyTeamInfo];
    }
    return self;
}

- (NSMutableArray *)memberIds {
    NSMutableArray *ret = [NSMutableArray array];
    [_members enumerateObjectsUsingBlock:^(NIMTeamCardMemberItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.userId) {
            [ret addObject:obj.userId];
        }
    }];
    return ret;
}

- (NIMTeamCardMemberItem *)memberWithUserId:(NSString *)userId {
    __block NIMTeamCardMemberItem *ret = nil;
    [_members enumerateObjectsUsingBlock:^(NIMTeamCardMemberItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userId isEqualToString:userId]) {
            ret = obj;
            *stop = YES;
        }
    }];
    return ret;
}

#pragma mark - Function
- (NSString *)myAccount {
    return [[NIMSDK sharedSDK].loginManager currentAccount];
}

- (void)reloadMyTeamInfo {
    NSString *userId = [self myAccount];
    NSString *teamId = _team.teamId;
    if (self.team.type == NIMTeamTypeSuper) {
        self.myTeamInfo = [[NIMSDK sharedSDK].superTeamManager teamMember:userId
                                                                   inTeam:teamId];
    } else {
        self.myTeamInfo = [[NIMSDK sharedSDK].teamManager teamMember:userId
                                                          inTeam:teamId];
    }
}

#pragma mark - Private
- (void)addMemberItem:(NIMTeamCardMemberItem *)item {
    if (!item) {
        return;
    }
    switch (item.userType) {
        case NIMTeamMemberTypeOwner:
        {
            [_members insertObject:item atIndex:0];
            break;
        }
        default:
            [_members addObject:item];
            break;
    }
}

- (void)removeMemberItem:(NSString *)userId {
    for (NIMTeamCardMemberItem *obj in _members) {
        if ([obj.userId isEqualToString:userId]) {
            [_members removeObject:obj];
            break;
        }
    }
}

- (void)addMembers:(NSArray <NIMTeamMember *>*)members {
    if (!_members) {
        _members = [NSMutableArray array];
    }
    
    for (NIMTeamMember *member in members) {
        NIMTeamCardMemberItem *item = [[NIMTeamCardMemberItem alloc] initWithMember:member
                                                                           teamType:_team.type];
        
        [self addMemberItem:item];
    }
}

- (void)removeMembers:(NSArray <NSString *> *)userIds {
    for (NSString *userId in userIds) {
        [self removeMemberItem:userId];
    }
}

- (NIMTeamMember*)teamInfo:(NSString*)uid{
    for (NIMTeamCardMemberItem *member in _members) {
        if ([member.userId isEqualToString:uid]) {
            return member.member;
        }
    }
    return nil;
}

- (void)setMyTeamInfo:(NIMTeamMember *)myTeamInfo {
    _myTeamInfo = myTeamInfo;
    _myCard = [[NIMTeamCardMemberItem alloc] initWithMember:myTeamInfo
                                                   teamType:_team.type];
}


- (void)updateMembersWithOption:(NIMMembersFetchOption *)option
                        members:(NSArray <NIMTeamMember *> *)members {
    if (!_members) {
        _members = [NSMutableArray array];
    }

    if (option.isRefresh) {
        [_members removeAllObjects];

        for (NIMTeamMember *member in members) {
            NSString *currentAccount = [NIMSDK sharedSDK].loginManager.currentAccount;
            if ([member.userId isEqualToString:currentAccount]) {
                self.myTeamInfo = member;
            }
            
            NIMTeamCardMemberItem *item = [[NIMTeamCardMemberItem alloc] initWithMember:member
                                                                               teamType:_team.type];
            [self addMemberItem:item];
        }
    } else {
        NSInteger start = _members.count - option.offset;
        for (NSInteger i = start; i < members.count; i++) {
            NIMTeamMember *member = members[i];
            
            NSString *currentAccount = [NIMSDK sharedSDK].loginManager.currentAccount;
            if ([member.userId isEqualToString:currentAccount]) {
                self.myTeamInfo = member;
            }
            
            NIMTeamCardMemberItem *item = [[NIMTeamCardMemberItem alloc] initWithMember:member
                                                                               teamType:_team.type];
            [self addMemberItem:item];
        }
    }
}

#pragma mark - Handle
- (void)handleUnsupport:(NIMTeamListDataBlock)completion {
    NSError *error = [NSError errorWithDomain:@"nimkit.teamlist.data"
                                         code:0x1000
                                     userInfo:@{NSLocalizedDescriptionKey : @"超大群未开放该功能".nim_localized}];
    if (completion) {
        completion(error, @"超大群未开放该功能".nim_localized);
    }
}


- (void)handleAddUsers:(NSError *)error
              memebers:(NSArray<NIMTeamMember *> *)members
            completion:(NIMTeamListDataBlock)completion {
    NSString *msg = nil;
    if (!error) {
        if (self.team.type == NIMTeamTypeNormal) { //高级群需要验证，普通群直接进
            [self addMembers:members];
            msg = @"邀请成功".nim_localized;
        } else {
            if (self.team.beInviteMode == NIMTeamBeInviteModeNeedAuth) {
                msg = @"邀请成功，等待验证".nim_localized;
            } else {
                [self addMembers:members];
                msg = @"邀请成功".nim_localized;
            }
        }
    } else {
        msg = [NSString stringWithFormat:@"邀请失败 code:%zd".nim_localized,error.code];
    }
    if (completion) {
        completion(error, msg);
    }
}

- (void)handleKickUsers:(NSArray *)userIds
                  error:(NSError *)error
             completion:(NIMTeamListDataBlock)completion {
    NSString *msg = nil;
    if (!error) {
        [self removeMembers:userIds];
    } else {
        msg = [NSString stringWithFormat:@"移除失败 code: %zd".nim_localized, error.code];
    }
    if (completion) {
        completion(error, msg);
    }
}

- (void)handleUpdateTeamAnnouncement:(NSString *)content
                               error:(NSError *)error
                          completion:(NIMTeamListDataBlock)completion {
    NSString *msg = nil;
    if (!error) {
        self.team.announcement = content;
    }
    if (completion) {
        completion(error, msg);
    }
}

- (void)handleUpdateTeamAvatar:(NSString *)urlString
                         error:(NSError *)error
                    completion:(NIMTeamListDataBlock)completion {
    NSString *msg = nil;
    if (error) {
        msg = @"设置头像失败，请重试".nim_localized;
    } else {
        self.team.avatarUrl = urlString;
    }
    if (completion) {
        completion(error, msg);
    }
}

- (void)handleUpdateTeamName:(NSString *)name
                       error:(NSError *)error
                  completion:(NIMTeamListDataBlock)completion {
    NSString *msg = nil;
    if (!error) {
        self.team.teamName = name;
        msg = @"修改成功".nim_localized;
    }else{
        msg = [NSString stringWithFormat:@"修改失败 code:%zd".nim_localized,error.code];
    }
    if (completion) {
        completion(error, msg);
    }
}

- (void)handleUpdateTeamNick:(NSString *)nick
                       error:(NSError *)error
                  completion:(NIMTeamListDataBlock)completion {
    NSString *msg = nil;
    if (!error) {
        self.myTeamInfo.nickname = nick;
        msg = @"修改成功".nim_localized;
    }else{
        msg = [NSString stringWithFormat:@"修改失败 code:%zd".nim_localized,error.code];
    }
    
    if (completion) {
        completion(error, msg);
    }
}

- (void)handleUpdateTeamIntro:(NSString *)intro
                        error:(NSError *)error
                   completion:(NIMTeamListDataBlock)completion {
    NSString *msg = nil;
    if (!error) {
        self.team.intro = intro;
        msg = @"修改成功".nim_localized;
    }else{
        msg = [NSString stringWithFormat:@"修改失败 code:%zd".nim_localized,error.code];
    }
    if (completion) {
        completion(error, msg);
    }
}

- (void)handleUpdateTeamMute:(NSError *)error
                  completion:(NIMTeamListDataBlock)completion {
    NSString *msg = nil;
    if (!error) {
        msg = @"修改成功".nim_localized;
    }else{
        msg = [NSString stringWithFormat:@"修改失败 code:%zd".nim_localized,error.code];
    }
    if (completion) {
        completion(error, msg);
    }
}

- (void)handleUpdateTeamJoinMode:(NIMTeamJoinMode)mode
                           error:(NSError *)error
                      completion:(NIMTeamListDataBlock)completion {
    NSString *msg = nil;
    if (!error) {
        self.team.joinMode = mode;
        msg = @"修改成功".nim_localized;
    }else{
        msg = [NSString stringWithFormat:@"修改失败 code:%zd".nim_localized,error.code];
    }
    
    if (completion) {
        completion(error, msg);
    }
}

- (void)handleUpdateTeamInviteMode:(NIMTeamInviteMode)mode
                             error:(NSError *)error
                        completion:(NIMTeamListDataBlock)completion {
    NSString *msg = nil;
    if (!error) {
        self.team.inviteMode = mode;
        msg = @"修改成功".nim_localized;
    } else {
        msg = [NSString stringWithFormat:@"修改失败 code:%zd".nim_localized,error.code];
    }
    
    if (completion) {
        completion(error, msg);
    }
}

- (void)handleUpdateTeamInfoMode:(NIMTeamUpdateInfoMode)mode
                           error:(NSError *)error
                      completion:(NIMTeamListDataBlock)completion {
    NSString *msg = nil;
    if (!error) {
        self.team.updateInfoMode = mode;
        msg = @"修改成功".nim_localized;
    } else {
        msg = [NSString stringWithFormat:@"修改失败 code:%zd".nim_localized,error.code];
    }
    
    if (completion) {
        completion(error, msg);
    }
}

- (void)handleUpdateTeamBeInviteMode:(NIMTeamBeInviteMode)mode
                               error:(NSError *)error
                          completion:(NIMTeamListDataBlock)completion {
    NSString *msg = nil;
    if (!error) {
        self.team.beInviteMode = mode;
        msg = @"修改成功".nim_localized;
    }else{
        msg = [NSString stringWithFormat:@"修改失败 code:%zd".nim_localized,error.code];
    }
    
    if (completion) {
        completion(error, msg);
    }
}

- (void)handleUpdateTeamNotifyState:(NIMTeamNotifyState)state
                              error:(NSError *)error
                         completion:(NIMTeamListDataBlock)completion {
    __block NSString *msg = nil;
    if (error) {
        msg = [NSString stringWithFormat:@"修改失败 code:%zd".nim_localized,error.code];
    }
    if (completion) {
        completion(error, msg);
    }
}

- (void)handleAddManagers:(NSArray *)userIds
                    error:(NSError *)error
               completion:(NIMTeamListDataBlock)completion {
    NSString *msg = nil;
    __block BOOL isChanged = NO;
    if (!error) {
        for (NSString *userId in userIds) {
            [self.members enumerateObjectsUsingBlock:^(NIMTeamCardMemberItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.userId isEqualToString:userId]) {
                    obj.userType = NIMTeamMemberTypeManager;
                    isChanged = YES;
                    *stop = YES;
                }
            }];
        }

        msg = @"修改成功".nim_localized;
    }else{
        msg = @"修改失败".nim_localized;
    }
    
    if (completion) {
        completion(error, msg);
    }
}


- (void)handleRemoveManagers:(NSArray *)userIds
                       error:(NSError *)error
                  completion:(NIMTeamListDataBlock)completion {
    NSString *msg = nil;
    if (!error) {
        for (NSString *userId in userIds) {
            [self.members enumerateObjectsUsingBlock:^(NIMTeamCardMemberItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.userId isEqualToString:userId]) {
                    obj.userType = NIMTeamMemberTypeNormal;
                    *stop = YES;
                }
            }];
        }
        msg = @"修改成功".nim_localized;
    }else{
        msg = @"修改失败".nim_localized;
    }
    if (completion) {
        completion(error, msg);
    }
}

- (void)handleTransferOwner:(NSString *)userId
                      leave:(BOOL)leave
                      error:(NSError *)error
                 completion:(NIMTeamListDataBlock)completion {
    NSString *msg = nil;
    if (!error) {
        NIMTeamMember *memberInfo = [self teamInfo:userId];
        memberInfo.type = NIMTeamMemberTypeOwner;
        if (leave && userId) {
            [self removeMembers:@[userId]];
        }
        msg = @"转移成功！".nim_localized;
    }else{
        msg = [NSString stringWithFormat:@"转移失败！code:%zd".nim_localized,error.code];
    }
                                                 
    if (completion) {
        completion(error, msg);
    }
}

- (void)handleUpdateUserNick:(NSString *)userId
                        nick:(NSString *)nick
                       error:(NSError *)error
                  completion:(NIMTeamListDataBlock)completion {
    NSString *msg = nil;
    if (!error) {
        [self.members enumerateObjectsUsingBlock:^(NIMTeamCardMemberItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.userId isEqualToString:userId]) {
                obj.member.nickname = nick;
                *stop = YES;
            }
        }];
        msg = @"修改成功".nim_localized;
    }else{
        msg = @"修改失败".nim_localized;
    }
    if (completion) {
        completion(error, msg);
    }
}

- (void)handleUpateUserMuteState:(NSError *)error
                      completion:(NIMTeamListDataBlock)completion {
    NSString *msg = nil;
    if (!error) {
        msg = @"修改成功".nim_localized;
    }else{
        msg = @"修改失败".nim_localized;
    }
    if (completion) {
        completion(error, msg);
    }
}

- (void)handleFetchTeamMembers:(NSArray <NIMTeamMember *> *)members
                        option:(NIMMembersFetchOption *)option
                         error:(NSError *)error
                    completion:(NIMTeamListDataBlock)completion{
    NSString *msg = nil;
    if (!error) {
        [self updateMembersWithOption:option members:members];
    } else if (error.code == NIMRemoteErrorCodeTeamNotMember
               || error.code == NIMRemoteErrorCodeNotInTeam) {
        msg = @"你已经不在群里".nim_localized;
    } else {
        msg = [NSString stringWithFormat:@"获取群成员失败 error: %zd".nim_localized,error.code];
    }
    if (completion) {
        completion(error, msg);
    }
}

- (void)handleFetchMuteTeamMembers:(NSArray <NIMTeamMember *> *)members
                             error:(NSError *)error
                        completion:(NIMTeamMuteListDataBlock)completion {
    NSMutableArray *items = nil;
    if (!error) {
        items = [NSMutableArray array];
        for (NIMTeamMember *member in members) {
            NIMTeamCardMemberItem *item = [[NIMTeamCardMemberItem alloc] initWithMember:member
                                                                               teamType:_team.type];
            [items addObject:item];
        }
    }
    if (completion) {
        completion(error, items);
    }
}

- (void)handleWithError:(NSError *)error
             completion:(NIMTeamListDataBlock)completion {
    NSString *msg = nil;
    if (error) {
        msg = [NSString stringWithFormat:@"操作失败 code:%zd".nim_localized,error.code];
    }
    if (completion) {
        completion(error, msg);
    }
}

#pragma mark - <NIMTeamOperation>
- (void)addUsers:(NSArray *)userIds
            info:(NSDictionary *)info
      completion:(NIMTeamListDataBlock)block {
    NSString *teamId = _team.teamId;
    NSString *postscript = info[@"postscript"];
    NSString *attach = info[@"attach"];
    __weak typeof(self) weakSelf = self;
    if (_team.type == NIMTeamTypeSuper) {
        [[NIMSDK sharedSDK].superTeamManager addUsers:userIds
                                               toTeam:teamId
                                           postscript:postscript
                                               attach:attach
                                           completion:^(NSError * _Nullable error, NSArray<NIMTeamMember *> * _Nullable members) {
            [weakSelf handleAddUsers:error
                            memebers:members
                          completion:block];
        }];
    } else {
        [[NIMSDK sharedSDK].teamManager addUsers:userIds
                                          toTeam:teamId
                                      postscript:postscript
                                          attach:attach
                                      completion:^(NSError * _Nullable error, NSArray<NIMTeamMember *> * _Nullable members) {
            [weakSelf handleAddUsers:error
                            memebers:members
                          completion:block];
        }];
    }
}

- (void)kickUsers:(NSArray *)userIds
       completion:(NIMTeamListDataBlock)block {
    NSString *teamId = _team.teamId;
    __weak typeof(self) wself = self;
    if (_team.type == NIMTeamTypeSuper) {
        [[NIMSDK sharedSDK].superTeamManager kickUsers:userIds
                                              fromTeam:teamId
                                            completion:^(NSError *error) {
            [wself handleKickUsers:userIds
                             error:error
                        completion:block];
        }];
    } else {
        [[NIMSDK sharedSDK].teamManager kickUsers:userIds
                                         fromTeam:teamId
                                       completion:^(NSError *error) {
            [wself handleKickUsers:userIds
                             error:error
                        completion:block];
        }];
    }
}

- (void)updateTeamAnnouncement:(NSString *)content
                    completion:(NIMTeamListDataBlock)block {
    NSString *teamId = _team.teamId;
    NSString *announcement = content ?: @"";
    __weak typeof(self) weakSelf = self;

    if (_team.type == NIMTeamTypeSuper) {
        [[NIMSDK sharedSDK].superTeamManager updateTeamAnnouncement:announcement
                                                             teamId:teamId
                                                         completion:^(NSError * _Nullable error) {
            [weakSelf handleUpdateTeamAnnouncement:announcement
                                             error:error
                                        completion:block];
        }];
    } else {
        [[NIMSDK sharedSDK].teamManager updateTeamAnnouncement:announcement
                                                        teamId:teamId
                                                    completion:^(NSError * _Nullable error) {
            [weakSelf handleUpdateTeamAnnouncement:announcement
                                             error:error
                                        completion:block];
        }];
    }
}

- (void)updateTeamAvatar:(NSString *)filePath
              completion:(NIMTeamListDataBlock)block {
    __weak typeof(self) wself = self;
    [[NIMSDK sharedSDK].resourceManager upload:filePath scene:NIMNOSSceneTypeAvatar progress:nil completion:^(NSString *urlString, NSError *error) {
        if (!error && urlString && wself) {
            
            if (wself.team.type == NIMTeamTypeSuper) {
                    [[NIMSDK sharedSDK].superTeamManager updateTeamAvatar:urlString
                                                                   teamId:wself.team.teamId
                                                               completion:^(NSError * _Nullable error) {
                    [wself handleUpdateTeamAvatar:urlString error:error completion:block];
                }];
            } else {
                [[NIMSDK sharedSDK].teamManager updateTeamAvatar:urlString
                                                          teamId:wself.team.teamId
                                                      completion:^(NSError * _Nullable error) {
                    [wself handleUpdateTeamAvatar:urlString error:error completion:block];
                }];
            }
        } else {
            if (block) {
                block(error, @"图片上传失败，请重试".nim_localized);
            }
        }
    }];
}

- (void)updateTeamName:(NSString *)name
            completion:(NIMTeamListDataBlock)block {
    NSString *teamId = _team.teamId;
    __weak typeof(self) weakSelf = self;
    if (_team.type == NIMTeamTypeSuper) {
        [[NIMSDK sharedSDK].superTeamManager updateTeamName:name
                                                     teamId:teamId
                                                 completion:^(NSError *error) {
            [weakSelf handleUpdateTeamName:name
                                     error:error
                                completion:block];
        }];
    } else {
        [[NIMSDK sharedSDK].teamManager updateTeamName:name
                                                teamId:teamId
                                            completion:^(NSError *error) {
            [weakSelf handleUpdateTeamName:name
                                     error:error
                                completion:block];
        }];
    }
}

- (void)updateTeamNick:(NSString *)nick
            completion:(NIMTeamListDataBlock)block {
    NSString *currentUserId = [NIMSDK sharedSDK].loginManager.currentAccount;
    NSString *teamId = _team.teamId;
    __weak typeof(self) weakSelf = self;
    if (_team.type == NIMTeamTypeSuper) {
        [[NIMSDK sharedSDK].superTeamManager updateUserNick:currentUserId
                                                    newNick:nick
                                                     inTeam:teamId
                                                 completion:^(NSError *error) {
            [weakSelf handleUpdateTeamNick:nick
                                     error:error
                                completion:block];
        }];
    } else {
        [[NIMSDK sharedSDK].teamManager updateUserNick:currentUserId
                                               newNick:nick
                                                inTeam:teamId
                                            completion:^(NSError *error) {
            [weakSelf handleUpdateTeamNick:nick
                                     error:error
                                completion:block];
        }];
    }
}

- (void)updateTeamIntro:(NSString *)intro
             completion:(NIMTeamListDataBlock)block {
    NSString *teamId = _team.teamId;
    __weak typeof(self) weakSelf = self;
    if (_team.type == NIMTeamTypeSuper) {
        [[NIMSDK sharedSDK].superTeamManager updateTeamIntro:intro
                                                      teamId:teamId
                                                  completion:^(NSError *error) {
            [weakSelf handleUpdateTeamIntro:intro
                                      error:error
                                 completion:block];
        }];
    } else {
        [[NIMSDK sharedSDK].teamManager updateTeamIntro:intro
                                                 teamId:teamId
                                             completion:^(NSError *error) {
            [weakSelf handleUpdateTeamIntro:intro
                                      error:error
                                 completion:block];
        }];
    }
}

- (void)updateTeamMute:(BOOL)mute
            completion:(NIMTeamListDataBlock)block {
    NSString *teamId = _team.teamId;
    __weak typeof(self) weakSelf = self;
    if (_team.type == NIMTeamTypeSuper) {
        [[NIMSDK sharedSDK].superTeamManager updateMuteState:mute
                                                      inTeam:teamId
                                                  completion:^(NSError * _Nullable error) {
            [weakSelf handleUpdateTeamMute:error
                                completion:block];
        }];
    } else {
        [[NIMSDK sharedSDK].teamManager updateMuteState:mute
                                                 inTeam:teamId
                                             completion:^(NSError * _Nullable error) {
            [weakSelf handleUpdateTeamMute:error
                                completion:block];
        }];
    }
}

- (void)updateTeamJoinMode:(NIMTeamJoinMode)mode
                completion:(NIMTeamListDataBlock)block {
    NSString *teamId = _team.teamId;
    __weak typeof(self) weakSelf = self;
    
    if (_team.type == NIMTeamTypeSuper) {
        [[NIMSDK sharedSDK].superTeamManager updateTeamJoinMode:mode
                                                         teamId:teamId
                                                     completion:^(NSError *error) {
            [weakSelf handleUpdateTeamJoinMode:mode
                                         error:error
                                    completion:block];
        }];
    } else {
        [[NIMSDK sharedSDK].teamManager updateTeamJoinMode:mode
                                                    teamId:teamId
                                                completion:^(NSError *error) {
            [weakSelf handleUpdateTeamJoinMode:mode
                                         error:error
                                    completion:block];
        }];
    }
}

- (void)updateTeamInviteMode:(NIMTeamInviteMode)mode
                  completion:(NIMTeamListDataBlock)block {
    NSString *teamId = _team.teamId;
    __weak typeof(self) weakSelf = self;
    if (_team.type == NIMTeamTypeSuper) {
        [self handleUnsupport:block];
    } else {
        [[NIMSDK sharedSDK].teamManager updateTeamInviteMode:mode
                                                      teamId:teamId
                                                  completion:^(NSError *error) {
            [weakSelf handleUpdateTeamInviteMode:mode
                                           error:error
                                      completion:block];
        }];
    }
}

- (void)updateTeamInfoMode:(NIMTeamUpdateInfoMode)mode
                completion:(NIMTeamListDataBlock)block {
    NSString *teamId = _team.teamId;
    __weak typeof(self) weakSelf = self;
    if (_team.type == NIMTeamTypeSuper) {
        [self handleUnsupport:block];
    } else {
        [[NIMSDK sharedSDK].teamManager updateTeamUpdateInfoMode:mode
                                                          teamId:teamId
                                                      completion:^(NSError *error) {
            [weakSelf handleUpdateTeamInfoMode:mode
                                         error:error
                                    completion:block];
        }];
    }
}

- (void)updateTeamBeInviteMode:(NIMTeamBeInviteMode)mode
                    completion:(NIMTeamListDataBlock)block {
    NSString *teamId = _team.teamId;
    __weak typeof(self) weakSelf = self;
    if (_team.type == NIMTeamTypeSuper) {
        [[NIMSDK sharedSDK].superTeamManager updateTeamBeInviteMode:mode
                                                             teamId:teamId
                                                         completion:^(NSError *error) {
            [weakSelf handleUpdateTeamBeInviteMode:mode
                                             error:error
                                        completion:block];
        }];
    } else {
        [[NIMSDK sharedSDK].teamManager updateTeamBeInviteMode:mode
                                                        teamId:teamId
                                                    completion:^(NSError *error) {
            [weakSelf handleUpdateTeamBeInviteMode:mode
                                             error:error
                                        completion:block];
        }];
    }
}

- (void)updateTeamNotifyState:(NIMTeamNotifyState)state
                   completion:(NIMTeamListDataBlock)block {
    NSString *teamId = _team.teamId;
    __weak typeof(self) weakSelf = self;
    if (_team.type == NIMTeamTypeSuper) {
        [[NIMSDK sharedSDK].superTeamManager updateNotifyState:state
                                                     inTeam:teamId
                                                 completion:^(NSError *error) {
            [weakSelf handleUpdateTeamNotifyState:state
                                            error:error
                                       completion:block];
         }];
    } else {
        [[[NIMSDK sharedSDK] teamManager] updateNotifyState:state
                                                     inTeam:teamId
                                                 completion:^(NSError *error) {
            [weakSelf handleUpdateTeamNotifyState:state
                                            error:error
                                       completion:block];
         }];
    }
}

- (void)addManagers:(NSArray *)userIds
         completion:(NIMTeamListDataBlock)block {
    NSString *teamId = _team.teamId;
    __weak typeof(self) weakSelf = self;
    if (_team.type == NIMTeamTypeSuper) {
        [[NIMSDK sharedSDK].superTeamManager addManagersToTeam:teamId
                                                         users:userIds
                                                    completion:^(NSError *error) {
            [weakSelf handleAddManagers:userIds
                                  error:error
                             completion:block];
        }];
    } else {
        [[NIMSDK sharedSDK].teamManager addManagersToTeam:teamId
                                                    users:userIds
                                               completion:^(NSError *error) {
            [weakSelf handleAddManagers:userIds
                                  error:error
                             completion:block];
        }];
    }
}

- (void)removeManagers:(NSArray *)userIds
            completion:(NIMTeamListDataBlock)block {
    NSString *teamId = _team.teamId;
    __weak typeof(self) weakSelf = self;
    if (_team.type == NIMTeamTypeSuper) {
        [[NIMSDK sharedSDK].superTeamManager removeManagersFromTeam:teamId
                                                              users:userIds
                                                         completion:^(NSError *error) {
            [weakSelf handleRemoveManagers:userIds
                                     error:error
                                completion:block];
        }];
    } else {
        [[NIMSDK sharedSDK].teamManager removeManagersFromTeam:teamId
                                                         users:userIds
                                                    completion:^(NSError *error) {
            [weakSelf handleRemoveManagers:userIds
                                     error:error
                                completion:block];
        }];
    }
}

- (void)transferOwnerWithUserId:(NSString *)userId
                          leave:(BOOL)leave
                     completion:(NIMTeamListDataBlock)block {
    NSString *teamId = _team.teamId;
    __weak typeof(self) weakSelf = self;
    if (_team.type == NIMTeamTypeSuper) {
        [[NIMSDK sharedSDK].superTeamManager transferManagerWithTeam:teamId
                                                          newOwnerId:userId
                                                             isLeave:leave
                                                          completion:^(NSError *error) {
            [weakSelf handleTransferOwner:userId
                                    leave:leave
                                    error:error
                               completion:block];
        }];
    } else {
        [[NIMSDK sharedSDK].teamManager transferManagerWithTeam:teamId
                                                     newOwnerId:userId
                                                        isLeave:leave
                                                     completion:^(NSError *error) {
            [weakSelf handleTransferOwner:userId
                                    leave:leave
                                    error:error
                               completion:block];
        }];
    }
}



- (void)updateUserNick:(NSString *)userId
                  nick:(NSString *)nick
            completion:(NIMTeamListDataBlock)block {
    NSString *teamId = _team.teamId;
    __weak typeof(self) weakSelf = self;
    if (_team.type == NIMTeamTypeSuper) {
        [[NIMSDK sharedSDK].superTeamManager updateUserNick:userId
                                                    newNick:nick
                                                     inTeam:teamId
                                                 completion:^(NSError *error) {
            [weakSelf handleUpdateUserNick:userId
                                      nick:nick
                                     error:error
                                completion:block];
        }];
    } else {
        [[NIMSDK sharedSDK].teamManager updateUserNick:userId
                                               newNick:nick
                                                inTeam:teamId
                                            completion:^(NSError *error) {
            [weakSelf handleUpdateUserNick:userId
                                      nick:nick
                                     error:error
                                completion:block];
        }];
    }
}

- (void)updateUserMuteState:(NSString *)userId
                       mute:(BOOL)mute
                 completion:(NIMTeamListDataBlock)block {
    NSString *teamId = _team.teamId;
    __weak typeof(self) weakSelf = self;
    if (_team.type == NIMTeamTypeSuper) {
        NSMutableArray *users = [NSMutableArray array];
        if (userId) {
            [users addObject:userId];
        }
        [[NIMSDK sharedSDK].superTeamManager updateMuteState:mute
                                                      userIds:users
                                                       inTeam:teamId
                                                  completion:^(NSError *error) {
            [weakSelf handleUpateUserMuteState:error
                                    completion:block];
        }];
    } else {
        [[NIMSDK sharedSDK].teamManager updateMuteState:mute
                                                 userId:userId
                                                 inTeam:teamId
                                             completion:^(NSError *error) {
            [weakSelf handleUpateUserMuteState:error
                                    completion:block];
         }];
    }
}

- (void)fetchTeamMembersWithOption:(NIMMembersFetchOption *)option
                        completion:(NIMTeamListDataBlock)block {
    NSString *teamId = _team.teamId;
    __weak typeof(self) weakSelf = self;
    if (_team.type == NIMTeamTypeSuper) {
        NIMTeamFetchMemberOption *sdkOption = [[NIMTeamFetchMemberOption alloc] init];
        sdkOption.offset = option.offset;
        sdkOption.count = option.count;
        [[NIMSDK sharedSDK].superTeamManager fetchTeamMembers:teamId
                                                       option:sdkOption
                                                   completion:^(NSError * _Nullable error, NSArray<NIMTeamMember *> * _Nullable members) {
            [weakSelf handleFetchTeamMembers:members
                          option:option
                           error:error
                      completion:block];
        }];
    } else {
        [[NIMSDK sharedSDK].teamManager fetchTeamMembers:teamId
                                              completion:^(NSError * _Nullable error, NSArray<NIMTeamMember *> * _Nullable members) {
            option.isRefresh = YES; //高级群全更新
            [weakSelf handleFetchTeamMembers:members
                                      option:option
                                       error:error
                                  completion:block];
        }];
    }
}

- (void)fetchTeamMutedMembersCompletion:(NIMTeamMuteListDataBlock)block {
    NSString *teamId = _team.teamId;
    __weak typeof(self) weakSelf = self;
    if (_team.type == NIMTeamTypeSuper) {
        [[NIMSDK sharedSDK].superTeamManager fetchTeamMutedMembers:teamId
                                                        completion:^(NSError * _Nullable error, NSArray<NIMTeamMember *> * _Nullable members) {
            [weakSelf handleFetchMuteTeamMembers:members
                                           error:error
                                      completion:block];
        }];
    } else {
        [[NIMSDK sharedSDK].teamManager fetchTeamMutedMembers:teamId
                                                   completion:^(NSError * _Nullable error, NSArray<NIMTeamMember *> * _Nullable members) {
            [weakSelf handleFetchMuteTeamMembers:members
                                           error:error
                                      completion:block];
        }];
    }
}

- (void)quitTeamCompletion:(NIMTeamListDataBlock)block {
    NSString *teamId = _team.teamId;
    __weak typeof(self) weakSelf = self;
    if (_team.type == NIMTeamTypeSuper) {
        [[NIMSDK sharedSDK].superTeamManager quitTeam:teamId
                                           completion:^(NSError *error) {
            [weakSelf handleWithError:error
                           completion:block];
        }];
    } else {
        [[NIMSDK sharedSDK].teamManager quitTeam:teamId
                                      completion:^(NSError *error) {
            [weakSelf handleWithError:error
                           completion:block];
        }];
    }
}

- (void)dismissTeamCompletion:(NIMTeamListDataBlock)block {
    NSString *teamId = _team.teamId;
    __weak typeof(self) weakSelf = self;
    if (_team.type == NIMTeamTypeSuper) {
        [self handleUnsupport:block];
    } else {
        [[NIMSDK sharedSDK].teamManager dismissTeam:teamId
                                         completion:^(NSError *error) {
            [weakSelf handleWithError:error completion:block];
        }];
    }
}

#pragma mark - <NIMTeamMemberListDataSource>
- (NSInteger)memberNumber {
    return [_team memberNumber];
}

#pragma mark - <NIMTeamManagerDelegate>
- (void)onTeamUpdated:(NIMTeam *)team {
    if (![team.teamId isEqualToString:_team.teamId]) {
        return;
    }
    _team = team;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNIMTeamListDataTeamInfoUpdate object:nil];
}

- (void)onTeamMemberChanged:(NIMTeam *)team {
    if (![team.teamId isEqualToString:_team.teamId]) {
        return;
    }
    _team = team;
    NIMMembersFetchOption *option = [[NIMMembersFetchOption alloc] init];
    option.count =  _members.count + 50;
    option.offset = 0;
    [self fetchTeamMembersWithOption:option completion:^(NSError * _Nullable error, NSString * _Nullable msg) {
        if (error) {
            NSLog(@"warning: teamupdate user failed because userid is empty");
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNIMTeamListDataTeamMembersChanged object:nil];
        }
    }];
}

@end
