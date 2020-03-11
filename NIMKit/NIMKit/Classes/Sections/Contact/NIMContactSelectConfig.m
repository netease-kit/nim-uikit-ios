//
//  NIMContactSelectConfig.m
//  NIMKit
//
//  Created by chris on 15/9/14.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMContactSelectConfig.h"
#import <NIMSDK/NIMSDK.h>
#import "NIMGlobalMacro.h"
#import "NIMGroupedData.h"
#import "NIMKit.h"
#import "NIMKitInfoFetchOption.h"
#import "NIMKitInfo.h"

@implementation NIMContactFriendSelectConfig : NSObject

- (BOOL)isMutiSelected{
    return self.needMutiSelected;
}

- (NSString *)title{
    return @"选择联系人".nim_localized;
}

- (NSInteger)maxSelectedNum{
    if (self.needMutiSelected) {
        return self.maxSelectMemberCount? self.maxSelectMemberCount : NSIntegerMax;
    }else{
        return 1;
    }
}

- (NSString *)selectedOverFlowTip{
    return @"选择超限".nim_localized;
}

- (void)getContactData:(NIMContactDataProviderHandler)handler {
    NIMGroupedData *groupedData = [[NIMGroupedData alloc] init];
    NSMutableArray *myFriendArray = @[].mutableCopy;
    NSMutableArray *data = [NIMSDK sharedSDK].userManager.myFriends.mutableCopy;
    NSMutableArray *members = @[].mutableCopy;
    
    for (NIMUser *user in data) {
        [myFriendArray addObject:user.userId];
    }
    NSArray *friend_uids = [self filterData:myFriendArray];
    for (NSString *uid in friend_uids) {
        NIMGroupUser *user = [[NIMGroupUser alloc] initWithUserId:uid];
        [members addObject:user];
    }
    groupedData.members = members;
    if (members) {
        [members removeAllObjects];
    }
    if (handler) {
        handler(groupedData.contentDic, groupedData.sectionTitles);
    }
}

- (NSArray *)filterData:(NSMutableArray *)data{
    if (data) {
        if ([self respondsToSelector:@selector(filterIds)]) {
            NSArray *ids = [self filterIds];
            [data removeObjectsInArray:ids];
        }
        return data;
    }
    return nil;
}

- (NIMKitInfo *)getInfoById:(NSString *)selectedId {
    NIMKitInfo *info = nil;
    info = [[NIMKit sharedKit] infoByUser:selectedId option:nil];
    return info;
}

@end

@implementation NIMContactTeamMemberSelectConfig : NSObject

- (NSInteger)maxSelectedNum{
    if (self.needMutiSelected) {
        return self.maxSelectMemberCount? self.maxSelectMemberCount : NSIntegerMax;
    }else{
        return 1;
    }
}

- (NSString *)title{
    return @"选择联系人".nim_localized;
}

- (NSString *)selectedOverFlowTip{
    return @"选择超限".nim_localized;
}

- (void)getTeamContactDataWithTeamId:(NSString *)teamID
                            teamType:(NIMKitTeamType)teamType
                            handler:(NIMContactDataProviderHandler)handler {
    NIMKit_WEAK_SELF(weakSelf);
    NSMutableArray <NSString *>*uids = [NSMutableArray array];
    if (teamType == NIMKitTeamTypeNomal) { //普通群组
        [[NIMSDK sharedSDK].teamManager fetchTeamMembers:teamID
                                              completion:^(NSError * _Nullable error, NSArray<NIMTeamMember *> * _Nullable members) {
            if (!error) {
                for (NIMTeamMember *member in members) {
                    if (member.userId) {
                        [uids addObject:member.userId];
                    }
                }
                [weakSelf didProcessTeamId:teamID
                                      uids:uids
                                   handler:handler];
            }
        }];
    } else if (teamType == NIMKitTeamTypeSuper) { //超大群组
        NIMTeamFetchMemberOption *option = [[NIMTeamFetchMemberOption alloc] init];
        [[NIMSDK sharedSDK].superTeamManager fetchTeamMembers:teamID option:option completion:^(NSError * _Nullable error, NSArray<NIMTeamMember *> * _Nullable members) {
            if (!error) {
                for (NIMTeamMember *member in members) {
                    if (member.userId) {
                        [uids addObject:member.userId];
                    }
                }
                [weakSelf didProcessTeamId:teamID
                                      uids:uids
                                   handler:handler];
            }
        }];
    } else {
        if (handler) {
            handler(nil, nil);
        }
    }
}

- (void)didProcessTeamId:(NSString *)teamId
                    uids:(NSMutableArray *)uids
                 handler:(NIMContactDataProviderHandler)handler {
    NIMGroupedData *groupedData = [[NIMGroupedData alloc] init];
    NSMutableArray *membersArr = @[].mutableCopy;
    NSArray *member_uids = [self filterData:uids];
    for (NSString *uid in member_uids) {
        NIMGroupTeamMember *user = [[NIMGroupTeamMember alloc] initWithUserId:uid
                                                                       session:_session];
        [membersArr addObject:user];
    }
    groupedData.members = membersArr;
    if (membersArr) {
        [membersArr removeAllObjects];
    }
    if (handler) {
        handler(groupedData.contentDic, groupedData.sectionTitles);
    }
}

- (void)getContactData:(NIMContactDataProviderHandler)handler {
    [self getTeamContactDataWithTeamId:_teamId
                              teamType:_teamType
                               handler:handler];
}

- (NSArray *)filterData:(NSMutableArray *)data{
    if (data) {
        if ([self respondsToSelector:@selector(filterIds)]) {
            NSArray *ids = [self filterIds];
            [data removeObjectsInArray:ids];
        }
        return data;
    }
    return nil;
}

- (NIMKitInfo *)getInfoById:(NSString *)selectedId {
    NIMKitInfo *info = nil;
    NIMKitInfoFetchOption *option = [[NIMKitInfoFetchOption alloc] init];
    option.session = _session;
    info = [[NIMKit sharedKit] infoByUser:selectedId option:option];
    return info;
}

@end

@implementation NIMContactTeamSelectConfig : NSObject

- (NSString *)title{
    return @"选择群组".nim_localized;
}

- (NSInteger)maxSelectedNum{
    if (self.needMutiSelected) {
        return self.maxSelectMemberCount? self.maxSelectMemberCount : NSIntegerMax;
    }else{
        return 1;
    }
}

- (NSString *)selectedOverFlowTip{
    return @"选择超限".nim_localized;
}

- (NSArray *)getTeamIdsWithTeamType:(NIMKitTeamType)teamType {
    NSMutableArray *uids = [NSMutableArray array];
    NSMutableArray *team_data = nil;
    if (teamType == NIMKitTeamTypeNomal) {
        team_data = [[NIMSDK sharedSDK].teamManager.allMyTeams mutableCopy];
    } else if (teamType == NIMKitTeamTypeSuper) {
        team_data = [[NIMSDK sharedSDK].superTeamManager.allMyTeams mutableCopy];
    }
    
    for (NIMTeam *team in team_data) {
        if (team.teamId) {
            [uids addObject:team.teamId];
        }
    }
    return [self filterData:uids];
}

- (void)getContactData:(NIMContactDataProviderHandler)handler {
    NSArray *tids = [self getTeamIdsWithTeamType:_teamType];
    if (tids.count == 0) {
        return;
    }
    
    NIMGroupedData *groupedData = [[NIMGroupedData alloc] init];
    NSMutableArray <id <NIMGroupMemberProtocol>>*members = @[].mutableCopy;
    for (NSString *tid in tids) {
        NIMGroupTeam *team = [[NIMGroupTeam alloc] initWithTeamId:tid teamType:_teamType];
        [members addObject:team];
    }
    groupedData.members = members;
    if (members) {
        [members removeAllObjects];
    }
    if (handler) {
        handler(groupedData.contentDic, groupedData.sectionTitles);
    }
}

- (NSArray *)filterData:(NSMutableArray *)data{
    if (data) {
        if ([self respondsToSelector:@selector(filterIds)]) {
            NSArray *ids = [self filterIds];
            [data removeObjectsInArray:ids];
        }
        return data;
    }
    return nil;
}

- (NIMKitInfo *)getInfoById:(NSString *)selectedId {
    NIMKitInfo *info = nil;
    if (_teamType == NIMKitTeamTypeNomal) {
        info = [[NIMKit sharedKit] infoByTeam:selectedId option:nil];
    } else if (_teamType == NIMKitTeamTypeSuper) {
        info = [[NIMKit sharedKit] infoBySuperTeam:selectedId option:nil];
    }
    return info;
}

@end
