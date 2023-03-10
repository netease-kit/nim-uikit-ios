// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "SettingManager.h"
#import <NERtcCallKit/NERtcCallKit.h>
NSString *const kYXOTOTimeOut = @"kYXOTOTimeOut";

NSString *const kShowCName = @"kShowCName";

@interface SettingManager ()

@property(nonatomic, assign, readwrite) NSInteger timeout;

@property(nonatomic, assign, readwrite) BOOL supportAutoJoinWhenCalled;

@property(nonatomic, assign, readwrite) BOOL rejectBusyCode;

@property(nonatomic, assign, readwrite) BOOL openCustomTokenAndChannelName;

@property(nonatomic, assign, readwrite) bool incallShowCName;

@property(nonatomic, assign, readwrite) BOOL useEnableLocalMute;

@property(nonatomic, assign, readwrite) BOOL isGlobalInit;

@end

@implementation SettingManager

+ (id)shareInstance {
  static SettingManager *shareInstance = nil;
  static dispatch_once_t once_token;
  dispatch_once(&once_token, ^{
    if (!shareInstance) {
      shareInstance = [[self alloc] init];
    }
  });
  return shareInstance;
}

- (void)setCallKitUid:(uint64_t)uid {
  [[NERtcCallKit sharedInstance] setValue:[NSNumber numberWithUnsignedLongLong:uid]
                               forKeyPath:@"context.currentUserUid"];

  //  if ([[NERtcCallKit sharedInstance] respondsToSelector:@selector(changeStatusIdle)]) {
  //    [[NERtcCallKit sharedInstance] changeStatusIdle];
  //  }
}

- (uint64_t)getCallKitUid {
  return [[[NERtcCallKit sharedInstance] valueForKeyPath:@"context.currentUserUid"]
      unsignedLongLongValue];
}

- (void)setAutoJoin:(BOOL)autoJoin {
  [[NERtcCallKit sharedInstance] setValue:[NSNumber numberWithBool:autoJoin]
                               forKeyPath:@"context.supportAutoJoinWhenCalled"];
  self.supportAutoJoinWhenCalled = autoJoin;
}

- (void)setBusyCode:(BOOL)open {
  self.rejectBusyCode = open;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    self.isGroupPush = YES;
    self.supportAutoJoinWhenCalled = [[[NERtcCallKit sharedInstance]
        valueForKeyPath:@"context.supportAutoJoinWhenCalled"] boolValue];
    self.rejectBusyCode = NO;
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSNumber *showCname = [userDefault objectForKey:kShowCName];
    if (showCname != nil) {
      self.incallShowCName = [showCname boolValue];
    }
    NSLog(@"current accid : %@", NIMSDK.sharedSDK.loginManager.currentAccount);
  }
  return self;
}

- (void)setTimeoutWithSecond:(NSInteger)second {
  [[NERtcCallKit sharedInstance] setTimeOutSeconds:second];
}

- (NSInteger)timeout {
  return [[NERtcCallKit sharedInstance] timeOutSeconds];
}

- (BOOL)isGlobalInit {
  return ![[[NERtcCallKit sharedInstance] valueForKeyPath:@"context.globalInit"] boolValue];
}

- (void)setIsGlobalInit:(BOOL)isGlobalInit
            withApnsCer:(NSString *)apnsCer
             withAppkey:(NSString *)appkey {
  [[NERtcCallKit sharedInstance] setValue:[NSNumber numberWithBool:!isGlobalInit]
                               forKeyPath:@"context.globalInit"];
  if (isGlobalInit == NO) {
    NERtcCallOptions *option = [NERtcCallOptions new];
    option.APNSCerName = apnsCer;
    option.disableRecord = NO;
    option.joinRtcWhenCall = [self isJoinRtcWhenCall];
    option.globalInit = YES;
    NERtcCallKit *callkit = [NERtcCallKit sharedInstance];
    option.supportAutoJoinWhenCalled = self.supportAutoJoinWhenCalled;
    [callkit setupAppKey:appkey options:option];
  } else {
    [NERtcEngine destroyEngine];
  }
}

- (BOOL)isJoinRtcWhenCall {
  return [[[NERtcCallKit sharedInstance] valueForKeyPath:@"context.joinRtcWhenCall"] boolValue];
}

- (void)setIsJoinRtcWhenCall:(BOOL)isJoinRtcWhenCall {
  [[NERtcCallKit sharedInstance] setValue:[NSNumber numberWithBool:isJoinRtcWhenCall]
                               forKeyPath:@"context.joinRtcWhenCall"];
}

- (BOOL)isAudioConfirm {
  return [[[NERtcCallKit sharedInstance] valueForKeyPath:@"context.confirmAudio"] boolValue];
}

- (void)setIsAudioConfirm:(BOOL)isAudioConfirm {
  [[NERtcCallKit sharedInstance] setValue:[NSNumber numberWithBool:isAudioConfirm]
                               forKeyPath:@"context.confirmAudio"];
}

- (BOOL)isVideoConfirm {
  return [[[NERtcCallKit sharedInstance] valueForKeyPath:@"context.confirmVideo"] boolValue];
}

- (void)setIsVideoConfirm:(BOOL)isVideoConfirm {
  [[NERtcCallKit sharedInstance] setValue:[NSNumber numberWithBool:isVideoConfirm]
                               forKeyPath:@"context.confirmVideo"];
}

- (NSString *)getRtcCName {
  return [[NERtcCallKit sharedInstance] valueForKeyPath:@"context.channelInfo.channelName"];
}

- (void)setShowCName:(BOOL)show {
  self.incallShowCName = show;
  NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
  [userDefault setObject:[NSNumber numberWithBool:show] forKey:kShowCName];
  [userDefault synchronize];
}

// 1.5.6 add
- (void)setEnableLocal:(BOOL)enable {
  self.useEnableLocalMute = enable;
}

@end
