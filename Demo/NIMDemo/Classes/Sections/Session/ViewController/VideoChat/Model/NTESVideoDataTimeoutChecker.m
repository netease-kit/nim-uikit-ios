//
//  NTESVideoDataTimeoutChecker.m
//  NIM
//
//  Created by chris on 2017/5/8.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import "NTESVideoDataTimeoutChecker.h"
#import "NTESTimerHolder.h"

@interface NTESVideoDataTimeoutChecker()<NIMNetCallManagerDelegate,NTESTimerHolderDelegate>

@property (nonatomic,strong) NTESTimerHolder *timer;

@property (nonatomic,strong) NSMutableSet *users;

@property (nonatomic,strong) NSMutableSet *usersMayTimeout;

@end


@implementation NTESVideoDataTimeoutChecker

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [[NIMAVChatSDK sharedSDK].netCallManager addDelegate:self];
        _timer = [[NTESTimerHolder alloc] init];
        [_timer startTimer:2 delegate:self repeats:YES];
        _users = [[NSMutableSet alloc] init];
        _usersMayTimeout = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [[NIMAVChatSDK sharedSDK].netCallManager removeDelegate:self];
}


#pragma mark - NIMNetCallManagerDelegate
- (void)onRemoteYUVReady:(NSData *)yuvData
                   width:(NSUInteger)width
                  height:(NSUInteger)height
                    from:(NSString *)user
{
    [self.usersMayTimeout removeObject:user];
    [self.users addObject:user];
}

#pragma mark - NTESTimerHolderDelegate
- (void)onNTESTimerFired:(NTESTimerHolder *)holder
{
    NSSet *usersTimeOut = [NSSet setWithSet:self.usersMayTimeout];
    if ([self.delegate respondsToSelector:@selector(onUserVideoDataTimeout:)])
    {
        for (NSString *user in usersTimeOut)
        {
            [self.delegate onUserVideoDataTimeout:user];
        }
    }
    self.usersMayTimeout = [NSMutableSet setWithSet:self.users];
    [self.users removeAllObjects];
}

@end
