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
#import "NIMKitDataProviderImpl.h"
#import "NIMCellLayoutConfig.h"
#import "NIMKitUIConfig.h"

extern NSString *const NIMKitUserInfoHasUpdatedNotification;
extern NSString *const NIMKitTeamInfoHasUpdatedNotification;


@interface NIMKit()
@property (nonatomic,strong)    NIMKitNotificationFirer *firer;
@property (nonatomic,strong)    id<NIMCellLayoutConfig> layoutConfig;
@end


@implementation NIMKit
- (instancetype)init
{
    if (self = [super init]) {
        _resourceBundleName  = @"NIMKitResource.bundle";
        _emoticonBundleName  = @"NIMKitEmoticon.bundle";
        _settingBundleName   = @"NIMKitSettings.bundle";
        _firer = [[NIMKitNotificationFirer alloc] init];
        _provider = [[NIMKitDataProviderImpl alloc] init];   //默认使用 NIMKit 的实现

        _layoutConfig = [[NIMCellLayoutConfig alloc] init];
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

- (void)registerLayoutConfig:(Class)layoutConfigClass
{
    id instance = [[layoutConfigClass alloc] init];
    if ([instance isKindOfClass:[NIMCellLayoutConfig class]])
    {
        self.layoutConfig = instance;
    }
    else
    {
        NSAssert(0, @"class should be subclass of NIMLayoutConfig");
    }
}

- (id<NIMCellLayoutConfig>)layoutConfig
{
    return _layoutConfig;
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
    extern NSString *NIMKitTeamMembersHasUpdatedNotification;
    info.notificationName = NIMKitTeamMembersHasUpdatedNotification;
    [self.firer addFireInfo:info];
}

- (NIMKitInfo *)infoByUser:(NSString *)userId
{
    return [self infoByUser:userId
                  inSession:nil];
}


- (NIMKitInfo *)infoByUser:(NSString *)userId
                 inSession:(NIMSession *)session
{
    NIMKitInfo *info = nil;
    if (self.provider && [self.provider respondsToSelector:@selector(infoByUser:inSession:)]) {
        info = [self.provider infoByUser:userId inSession:session];
    }
    return info;
}

- (NIMKitInfo *)infoByTeam:(NSString *)teamId
{
    NIMKitInfo *info = nil;
    if (self.provider && [self.provider respondsToSelector:@selector(infoByTeam:)]) {
        info = [self.provider infoByTeam:teamId];
    }
    return info;

}

- (NIMKitInfo *)infoByUser:(NSString *)userId
               withMessage:(NIMMessage *)message
{
    NSAssert([userId isEqualToString:message.from], @"user id should be same with message from");
    
    NIMKitInfo *info = nil;
    if (self.provider && [self.provider respondsToSelector:@selector(infoByUser:withMessage:)]) {
        info = [self.provider infoByUser:userId
                         withMessage:message];
    }
    return info;
}

@end



