//
//  NIMKit.m
//  NIMKit
//
//  Created by amao on 8/14/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import "NIMKit.h"
#import "NIMKitTimerHolder.h"
#import "NIMKitNotificationFirer.h"

NSString *const NIMKitChatroomMemberInfoHasUpdatedNotification = @"NIMKitChatroomMemberInfoHasUpdatedNotification";
NSString *const NIMKitChatroomMembersKey  = @"NIMKitChatroomMembersKey";

extern NSString *const NIMKitUserInfoHasUpdatedNotification;
extern NSString *const NIMKitTeamInfoHasUpdatedNotification;
extern NSString *const NIMKitUserBlackListHasUpdatedNotification;
extern NSString *const NIMKitUserMuteListHasUpdatedNotification;

@implementation NIMKitInfo

@end

@interface NIMKit()

@property (nonatomic,strong) NIMKitNotificationFirer *firer;

@end

@implementation NIMKit
- (instancetype)init
{
    if (self = [super init]) {
        _bundleName = @"NIMKitResouce.bundle";
        _firer = [[NIMKitNotificationFirer alloc] init];
    }
    return self;
}

+ (instancetype)sharedKit
{
    static NIMKit *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NIMKit alloc] init];
    });
    return instance;
}

- (void)notfiyUserInfoChanged:(NSArray *)userIds{
    if (!userIds.count) {
        return;
    }
    for (NSString *userId in userIds) {
        NIMSession *session = [NIMSession session:userId type:NIMSessionTypeP2P];
        NIMKitFirerInfo *info = [[NIMKitFirerInfo alloc] init];
        info.session = session;
        info.notificationName = NIMKitUserInfoHasUpdatedNotification;
        [self.firer addFireInfo:info];
    }
}

- (void)notifyTeamInfoChanged:(NSArray *)teamIds{
    if (teamIds.count) {
        for (NSString *teamId in teamIds) {
            [self notifyTeam:teamId];
        }
    }else{
        [self notifyTeam:nil];
    }
}

- (void)notifyUserBlackListChanged
{
    NIMKitFirerInfo *info = [[NIMKitFirerInfo alloc] init];
    info.notificationName = NIMKitUserBlackListHasUpdatedNotification;
    [self.firer addFireInfo:info];
}

- (void)notifyUserMuteListChanged
{
    NIMKitFirerInfo *info = [[NIMKitFirerInfo alloc] init];
    info.notificationName = NIMKitUserMuteListHasUpdatedNotification;
    [self.firer addFireInfo:info];
}

- (void)notifyTeamMemebersChanged:(NSArray *)teamIds
{
    if (teamIds.count) {
        for (NSString *teamId in teamIds) {
            [self notifyTeamMemebers:teamId];
        }
    }else{
        [self notifyTeamMemebers:nil];
    }
}


- (void)notifyTeam:(NSString *)teamId
{
    NIMKitFirerInfo *info = [[NIMKitFirerInfo alloc] init];
    if (teamId.length) {
        NIMSession *session = [NIMSession session:teamId type:NIMSessionTypeTeam];
        info.session = session;
    }
    info.notificationName = NIMKitTeamInfoHasUpdatedNotification;
    [self.firer addFireInfo:info];
}

- (void)notifyTeamMemebers:(NSString *)teamId
{
    NIMKitFirerInfo *info = [[NIMKitFirerInfo alloc] init];
    if (teamId.length) {
        NIMSession *session = [NIMSession session:teamId type:NIMSessionTypeTeam];
        info.session = session;
    }
    info.notificationName = NIMKitTeamMembersHasUpdatedNotification;
    [self.firer addFireInfo:info];
}

@end

@implementation NIMKit(Private)

- (NIMKitInfo *)infoByUser:(NSString *)userId
{
    return [self infoByUser:userId
                  inSession:nil];
}


- (NIMKitInfo *)infoByUser:(NSString *)userId
                 inSession:(NIMSession *)session
{
    NIMKitInfo *info = nil;
    if (_provider && [_provider respondsToSelector:@selector(infoByUser:inSession:)]) {
        info = [_provider infoByUser:userId inSession:session];
    }
    return info;
}

- (NIMKitInfo *)infoByTeam:(NSString *)teamId
{
    NIMKitInfo *info = nil;
    if (_provider && [_provider respondsToSelector:@selector(infoByTeam:)]) {
        info = [_provider infoByTeam:teamId];
    }
    return info;

}

- (NIMKitInfo *)infoByUser:(NSString *)userId
               withMessage:(NIMMessage *)message
{
    NSAssert([userId isEqualToString:message.from], @"user id should be same with message from");
    
    NIMKitInfo *info = nil;
    if (_provider && [_provider respondsToSelector:@selector(infoByUser:withMessage:)]) {
        info = [_provider infoByUser:userId
                         withMessage:message];
    }
    return info;
}

@end



