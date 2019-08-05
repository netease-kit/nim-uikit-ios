//
//  NIMSuperTeamListDataManager.m
//  NIMKit
//
//  Created by Netease on 2019/6/17.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "NIMSuperTeamListDataManager.h"

@interface NIMSuperTeamListDataManager ()

@property (nonatomic, strong) NIMTeam *team;

@property (nonatomic, strong) NIMSession *session;

@property (nonatomic, strong) NIMTeamMember *myTeamInfo;

@property (nonatomic, strong) NSMutableArray <NIMTeamMember *> *members;

@property (nonatomic, strong) NSMutableArray <NIMTeamCardMemberItem *> *datas;

@property (nonatomic, strong) NIMTeamCardMemberItem *myCard;

@end

@implementation NIMSuperTeamListDataManager

- (instancetype)initWithTeam:(NIMTeam *)team session:(NIMSession *)session{
    if (self = [super init]) {
        _team = team;
        _session = session;
    }
    return self;
}

- (void)reloadMyTeamInfo {
    if (!_myTeamInfo) {
        return;
    }
    NSString *userId = _myTeamInfo.userId;
    NSString *teamId = _myTeamInfo.teamId;
    _myTeamInfo = [[NIMSDK sharedSDK].superTeamManager teamMember:userId
                                                           inTeam:teamId];
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

#pragma mark - Public
- (NSString *)notifyStateText {
    NIMKitTeamNotifyState state = [NIMSuperTeamListDataManager kitTeamNotifyStateWithState:_team.notifyStateForNewMsg];
    return [NIMSuperTeamListDataManager notifyStateText:state];
}

- (NSArray *)allNotifyStates {
    NSArray *ret = @[
                     @{
                         @"value" : @(NIMKitTeamNotifyStateAll),
                         @"title" : [NIMSuperTeamListDataManager notifyStateText:NIMKitTeamNotifyStateAll]
                         },
                     @{
                         @"value" : @(NIMKitTeamNotifyStateNone),
                         @"title" : [NIMSuperTeamListDataManager notifyStateText:NIMKitTeamNotifyStateNone]
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

- (void)inviteUsers:(NSArray<NSString *> *)userIds completion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    [[NIMSDK sharedSDK].superTeamManager addUsers:userIds
                                           toTeam:teamId
                                       completion:^(NSError * _Nullable error, NSArray<NIMTeamMember *> * _Nullable members) {
        NSString *msg = nil;
        if (error) {
            msg = [NSString stringWithFormat:@"邀请失败。error_code:%zd", error.code];
        }
        if (completion) {
            completion(error, msg);
        }
    }];
}

- (void)updateTeamAvatar:(NSString *)filePath completion:(NIMTeamListDataBlock)completion {
    __weak typeof(self) wself = self;
    __block NSString *msg = nil;
    NSString *teamId = wself.team.teamId;
    [[NIMSDK sharedSDK].resourceManager upload:filePath scene:NIMNOSSceneTypeAvatar progress:nil completion:^(NSString *urlString, NSError *error) {
        if (!error && wself) {
            NSDictionary *update = @{@(NIMSuperTeamUpdateTagAvatar) : urlString ?: @""};
            [[NIMSDK sharedSDK].superTeamManager updateTeamInfos:update teamId:teamId completion:^(NSError * _Nullable error) {
                if (!error) {
                    wself.team.avatarUrl = urlString;
                }else{
                    msg = [NSString stringWithFormat:@"设置头像失败，请重试.code:%zd", error.code];
                }
                if (completion) {
                    completion(error, msg);
                }
            }];
        }else{
            msg = [NSString stringWithFormat:@"图片上传失败，请重试.code:%zd", error.code];
            if (completion) {
                completion(error, msg);
            }
        }
    }];
}

- (void)updateTeamName:(NSString *)name
            completion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    NSDictionary *update = @{@(NIMSuperTeamUpdateTagName) : name ?: @""};
    __block NSString *msg = nil;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].superTeamManager updateTeamInfos:update teamId:teamId completion:^(NSError * _Nullable error) {
        if (!error) {
            weakSelf.team.teamName = name;
            msg = @"修改成功";
        } else {
            msg = [NSString stringWithFormat:@"修改失败 code:%zd",error.code];
        }
        if (completion) {
            completion(error, msg);
        }
    }];
}

- (void)updateTeamNick:(NSString *)nick
            completion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    NSString *nickName = nick ?: @"";
    __block NSString *msg = nil;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].superTeamManager updateMyNick:nickName inTeam:teamId completion:^(NSError * _Nullable error) {
        if (!error) {
            weakSelf.myTeamInfo.nickname = nickName;
            msg = @"修改成功";
        } else {
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
    NSDictionary *update = @{@(NIMSuperTeamUpdateTagIntro) : intro ?: @""};
    __block NSString *msg = nil;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].superTeamManager updateTeamInfos:update teamId:teamId completion:^(NSError * _Nullable error) {
        if (!error) {
            weakSelf.team.intro = intro;
            msg = @"修改成功";
        } else {
            msg = [NSString stringWithFormat:@"修改失败 code:%zd",error.code];
        }
        
        if (completion) {
            completion(error, msg);
        }
    }];
    
}

- (void)updateTeamAnnouncement:(NSString *)content
                    completion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    NSDictionary *update = @{@(NIMSuperTeamUpdateTagAnouncement) : content ?: @""};
    __block NSString *msg = nil;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].superTeamManager updateTeamInfos:update teamId:teamId completion:^(NSError * _Nullable error) {
        if (!error) {
            weakSelf.team.announcement = content;
        }
        if (completion) {
            completion(error, msg);
        }
    }];
}

- (void)quitTeamCompletion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    __block NSString *msg = nil;
    [[NIMSDK sharedSDK].superTeamManager quitTeam:teamId completion:^(NSError * _Nullable error) {
        if (error) {
            msg = [NSString stringWithFormat:@"退出失败 code:%zd",error.code];
        }
        if (completion) {
            completion(error, msg);
        }
    }];
}

#pragma mark - <NIMTeamMemberListDataSource>
- (NSInteger)memberNumber {
    return [_team memberNumber];
}

- (void)fetchTeamMembersWithOption:(NIMMembersFetchOption *)option
                        completion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    __weak typeof(self) weakSelf = self;
    NIMTeamFetchMemberOption *sdkOption = [[NIMTeamFetchMemberOption alloc] init];
    sdkOption.offset = option.offset;
    sdkOption.count = option.count;
    [[NIMSDK sharedSDK].superTeamManager fetchTeamMembers:teamId option:sdkOption completion:^(NSError * _Nullable error, NSArray<NIMTeamMember *> * _Nullable members) {
        NSString *msg = nil;
        
        if (!error) {
            
            //update my team info
            [weakSelf updateMyTeamInfo:members];
            
            //update members
            [weakSelf updateMembersWithOption:option members:members];
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
    [[NIMSDK sharedSDK].superTeamManager kickUsers:userIds
                                          fromTeam:teamId
                                        completion:^(NSError * _Nullable error) {
        NSString *msg = nil;
        if (error) {
            msg = [NSString stringWithFormat:@"踢人失败。error_code:%zd", error.code];
        }
        if (completion) {
            completion(error, msg);
        }
    }];
}

//修改用户昵称
- (void)updateUserNick:(NSString *)userId
                  nick:(NSString *)nick
            completion:(NIMTeamListDataBlock)completion {
    [self doExecuteUnsupportBlock:completion];
}

//修改用户禁言状态
- (void)updateUserMuteState:(NSString *)userId
                       mute:(BOOL)mute
                 completion:(NIMTeamListDataBlock)completion {
    [self doExecuteUnsupportBlock:completion];
}

//增加管理员
- (void)addManagers:(NSArray *)userIds
         completion:(NIMTeamListDataBlock)completion {
    [self doExecuteUnsupportBlock:completion];
}

//移除管理员
- (void)removeManagers:(NSArray *)userIds
            completion:(NIMTeamListDataBlock)completion {
    [self doExecuteUnsupportBlock:completion];
}

//群通知状态修改
- (void)updateTeamNotifyState:(NIMKitTeamNotifyState)state
                   completion:(NIMTeamListDataBlock)completion {
    NSString *teamId = _team.teamId;
    __block NSString *msg = nil;
    NIMTeamNotifyState notifyState = [NIMSuperTeamListDataManager sdkTeamNotifyStateWithState:state];
    [[[NIMSDK sharedSDK] superTeamManager] updateNotifyState:notifyState
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
    NIMTeamNotifyState ret = [[NIMSDK sharedSDK].superTeamManager notifyStateForNewMsg:teamId];
    return [NIMSuperTeamListDataManager kitTeamNotifyStateWithState:ret];
}

#pragma mark - Private
- (void)doExecuteUnsupportBlock:(NIMTeamListDataBlock)block {
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"超大群不支持该功能"};
    NSError *error = [NSError errorWithDomain:@"nimkit.teamlist.data" code:0x1000 userInfo:userInfo];
    if (block) {
        block(error, nil);
    }
}

- (void)updateMyTeamInfo:(NSArray <NIMTeamMember *> *)members {
    NSString *currentAccount = [NIMSDK sharedSDK].loginManager.currentAccount;
    for (NIMTeamMember *member in members) {
        if ([member.userId isEqualToString:currentAccount]) {
            self.myTeamInfo = member;
            break;
        }
    }
}

- (void)updateMembersWithOption:(NIMMembersFetchOption *)option
                        members:(NSArray <NIMTeamMember *> *)members {
    if (!_members) {
        _members = [NSMutableArray array];
    }
    if (!_datas) {
        _datas = [NSMutableArray array];
    }
    if (option.isRefresh) {
        [_members removeAllObjects];
        [_members addObjectsFromArray:members];
        
        [_datas removeAllObjects];
        for (NIMTeamMember *member in members) {
            NIMTeamCardMemberItem *item = [[NIMTeamCardMemberItem alloc] initWithSuperTeamId:_team.teamId
                                                                                      member:member];
            [_datas addObject:item];
        }
    } else {
        NSInteger start = _members.count - option.offset;
        for (NSInteger i = start; i < members.count; i++) {
            NIMTeamMember *member = members[i];
            [_members addObject:member];
            NIMTeamCardMemberItem *item = [[NIMTeamCardMemberItem alloc] initWithSuperTeamId:_team.teamId
                                                                                      member:member];
            [_datas addObject:item];
        }
    }
}

- (void)setMyTeamInfo:(NIMTeamMember *)myTeamInfo {
    _myTeamInfo = myTeamInfo;
    _myCard = [[NIMTeamCardMemberItem alloc] initWithSuperTeamId:_team.teamId
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
        NIMTeamCardMemberItem *item = [[NIMTeamCardMemberItem alloc] initWithSuperTeamId:_team.teamId
                                                                                  member:member];
        [_datas addObject:item];
    }
}

#pragma mark - Helper
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
            return NIMTeamNotifyStateAll;
        default:
            return NIMTeamNotifyStateAll;
    }
}

@end
