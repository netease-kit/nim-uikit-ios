//
//  NIMKit.m
//  NIMKit
//
//  Created by amao on 8/14/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import "NIMKit.h"
#import "NIMKitTimerHolder.h"

NSString *const NIMKitUserInfoHasUpdatedNotification = @"NIMKitUserInfoHasUpdatedNotification";
NSString *const NIMKitTeamInfoHasUpdatedNotification = @"NIMKitTeamInfoHasUpdatedNotification";
NSString *const NIMKitInfoKey                        = @"InfoId";


@interface NIMKitNotificationFirer : NSObject<NIMKitTimerHolderDelegate>

@property (nonatomic,strong) NSMutableDictionary *cachedInfo;

@property (nonatomic,strong) NIMKitTimerHolder *timer;

@property (nonatomic,assign) NSTimeInterval timeInterval;

- (void)addFireInfo:(NIMSession *)info;

@end

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
        [self.firer addFireInfo:session];
    }
}

- (void)notfiyTeamInfoChanged:(NSArray *)teamIds{
    if (!teamIds.count) {
        return;
    }
    for (NSString *teamId in teamIds) {
        NIMSession *session = [NIMSession session:teamId type:NIMSessionTypeTeam];
        [self.firer addFireInfo:session];
    }
}

@end

@implementation NIMKit(Private)

- (NIMKitInfo *)infoByUser:(NSString *)userId
{
    if (![userId isKindOfClass:[NSString class]]) {
        return nil;
    }
    NIMKitInfo *member;
    if (_provider && [_provider respondsToSelector:@selector(infoByUser:)]) {
        member = [_provider infoByUser:userId];
    }
    return member;
}

- (NIMKitInfo *)infoByTeam:(NSString *)teamId;
{
    if (![teamId isKindOfClass:[NSString class]]) {
        return nil;
    }
    NIMKitInfo *member;
    if (_provider && [_provider respondsToSelector:@selector(infoByTeam:)]) {
        member = [_provider infoByTeam:teamId];
    }
    return member;
}

@end



@implementation NIMKitNotificationFirer

- (instancetype)init{
    self = [super init];
    if (self) {
        _timer = [[NIMKitTimerHolder alloc] init];
        _timeInterval = 1.0f;
        _cachedInfo = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)addFireInfo:(NIMSession *)info{
    if (!self.cachedInfo.count) {
        [self.timer startTimer:self.timeInterval delegate:self repeats:NO];
    }
    NSString *identity = [NSString stringWithFormat:@"%@-%zd",info.sessionId,info.sessionType];
    [self.cachedInfo setObject:info forKey:identity];
}

#pragma mark - NIMKitTimerHolderDelegate
- (void)onNIMKitTimerFired:(NIMKitTimerHolder *)holder{
    NSMutableArray *uinfo = [[NSMutableArray alloc] init];
    NSMutableArray *tinfo = [[NSMutableArray alloc] init];
    for (NIMSession *info in self.cachedInfo.allValues) {
        if (info.sessionType == NIMSessionTypeP2P)
        {
            [uinfo addObject:info.sessionId];
        }
        else if(info.sessionType == NIMSessionTypeTeam)
        {
            [tinfo addObject:info.sessionId];
        }
    }
    if (uinfo.count) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NIMKitUserInfoHasUpdatedNotification object:nil userInfo:@{NIMKitInfoKey:uinfo}];
    }
    if (tinfo.count) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NIMKitTeamInfoHasUpdatedNotification object:nil userInfo:@{NIMKitInfoKey:tinfo}];
    }
    [self.cachedInfo removeAllObjects];
}

@end

