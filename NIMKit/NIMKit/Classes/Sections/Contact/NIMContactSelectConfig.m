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
#import "NIMGroupedUsrInfo.h"
#import "NIMKit.h"

@implementation NIMContactFriendSelectConfig : NSObject

- (BOOL)isMutiSelected{
    return self.needMutiSelected;
}

- (NSString *)title{
    return @"选择联系人";
}


- (NSInteger)maxSelectedNum{
    if (self.needMutiSelected) {
        return self.maxSelectMemberCount? self.maxSelectMemberCount : NSIntegerMax;
    }else{
        return 1;
    }
}

- (NSString *)selectedOverFlowTip{
    return @"选择超限";
}

- (void)getContactData:(NIMContactDataProviderHandler)handler {
    NIMGroupedData *groupedData = [[NIMGroupedData alloc] init];
    NSMutableArray *myFriendArray = @[].mutableCopy;
    NSMutableArray *data = [NIMSDK sharedSDK].userManager.myFriends.mutableCopy;
    NSArray *robot_uids = @[].mutableCopy;
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
    if (self.enableRobot) {
        NSMutableArray *robotsArr = @[].mutableCopy;
        NSMutableArray *robot_data = [NIMSDK sharedSDK].robotManager.allRobots.mutableCopy;
        for (NIMRobot *robot in robot_data) {
            [robotsArr addObject:robot.userId];
        }
        robot_uids = [self filterData:robotsArr];
        for (NSString *uid in robot_uids) {
            NIMGroupUser *user = [[NIMGroupUser alloc] initWithUserId:uid];
            [members addObject:user];
        }
        groupedData.specialMembers = members;
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

@implementation NIMContactRobotSelectConfig


- (BOOL)isMutiSelected{
    return self.needMutiSelected;
}

- (NSString *)title{
    return @"选择机器人";
}


- (NSInteger)maxSelectedNum{
    if (self.needMutiSelected) {
        return self.maxSelectMemberCount? self.maxSelectMemberCount : NSIntegerMax;
    }else{
        return 1;
    }
}

- (NSString *)selectedOverFlowTip{
    return @"选择超限";
}

- (void)getContactData:(NIMContactDataProviderHandler)handler {
    NIMGroupedData *groupedData = [[NIMGroupedData alloc] init];
    NSMutableArray *robotsArray = @[].mutableCopy;
    NSMutableArray *robot_data = [NIMSDK sharedSDK].robotManager.allRobots.mutableCopy;
    NSMutableArray *members = @[].mutableCopy;
    
    for (NIMRobot *robot in robot_data) {
        [robotsArray addObject:robot.userId];
    }
    NSArray *robot_uids = [self filterData:robotsArray];
    if (members) {
        [members removeAllObjects];
    }
    for (NSString *uid in robot_uids) {
        NIMGroupUser *user = [[NIMGroupUser alloc] initWithUserId:uid];
        [members addObject:user];
    }
    groupedData.specialMembers = members;
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
    return @"选择联系人";
}


- (NSString *)selectedOverFlowTip{
    return @"选择超限";
}

- (void)getContactData:(NIMContactDataProviderHandler)handler {
    NIMGroupedData *groupedData = [[NIMGroupedData alloc] init];
    NSString *teamID = self.teamId;
    __block NSMutableArray *membersArr = @[].mutableCopy;
    NIMKit_WEAK_SELF(weakSelf);
    [[NIMSDK sharedSDK].teamManager fetchTeamMembers:teamID completion:^(NSError * _Nullable error, NSArray<NIMTeamMember *> * _Nullable members) {
        if (!error) {
            NSMutableArray *teamMember_data = @[].mutableCopy;
            NSArray *robot_uids = @[].mutableCopy;
            for (NIMTeamMember *member in members) {
                [teamMember_data addObject:member.userId];
            }
            NSArray *member_uids = [weakSelf filterData:teamMember_data];
            for (NSString *uid in member_uids) {
                NIMGroupTeamMember *user = [[NIMGroupTeamMember alloc] initWithUserId:uid teamId:teamID];
                [membersArr addObject:user];
            }
            groupedData.members = membersArr;
            if (membersArr) {
                [membersArr removeAllObjects];
            }
            if (weakSelf.enableRobot) {
                NSMutableArray *robotsArray = @[].mutableCopy;
                NSMutableArray *robot_data = [NIMSDK sharedSDK].robotManager.allRobots.mutableCopy;
                for (NIMRobot *robot in robot_data) {
                    [robotsArray addObject:robot.userId];
                }
                robot_uids = [weakSelf filterData:robotsArray];
                for (NSString *uid in robot_uids) {
                    NIMGroupUser *user = [[NIMGroupUser alloc] initWithUserId:uid];
                    [membersArr addObject:user];
                }
                groupedData.specialMembers = membersArr;
            }
            
            if (handler) {
                handler(groupedData.contentDic, groupedData.sectionTitles);
            }
        }
    }];
    
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

@implementation NIMContactTeamSelectConfig : NSObject

- (NSString *)title{
    return @"选择群组";
}

- (NSInteger)maxSelectedNum{
    if (self.needMutiSelected) {
        return self.maxSelectMemberCount? self.maxSelectMemberCount : NSIntegerMax;
    }else{
        return 1;
    }
}

- (NSString *)selectedOverFlowTip{
    return @"选择超限";
}

- (void)getContactData:(NIMContactDataProviderHandler)handler {
    NIMGroupedData *groupedData = [[NIMGroupedData alloc] init];
    NSMutableArray *teams = @[].mutableCopy;
    NSArray *robot_uids = @[].mutableCopy;
    NSMutableArray *members = @[].mutableCopy;
    NSMutableArray *team_data = [[NIMSDK sharedSDK].teamManager.allMyTeams mutableCopy];
    
    for (NIMTeam *team in team_data) {
        [teams addObject:team.teamId];
    }
    NSArray *team_uids = [self filterData:teams];
    for (NSString *teamId in team_uids) {
        NIMGroupTeam *team = [[NIMGroupTeam alloc] initWithTeam:teamId];
        [members addObject:team];
    }
    groupedData.members = members;
    if (members) {
        [members removeAllObjects];
    }
    if (self.enableRobot) {
        NSMutableArray *robotsArray = @[].mutableCopy;
        NSMutableArray *robot_data = [NIMSDK sharedSDK].robotManager.allRobots.mutableCopy;
        for (NIMRobot *robot in robot_data) {
            [robotsArray addObject:robot.userId];
        }
        robot_uids = [self filterData:robotsArray];
        
        for (NSString *uid in robot_uids) {
            NIMGroupUser *user = [[NIMGroupUser alloc] initWithUserId:uid];
            [members addObject:user];
        }
        groupedData.specialMembers = members;
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
    info = [[NIMKit sharedKit] infoByTeam:selectedId option:nil];
    return info;
}

@end
