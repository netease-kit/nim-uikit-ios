// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SettingManager : NSObject

@property(nonatomic, assign, readonly) NSInteger timeout;

@property(nonatomic, assign, readonly) BOOL supportAutoJoinWhenCalled;

@property(nonatomic, assign, readonly) BOOL rejectBusyCode;

@property(nonatomic, assign, readonly) BOOL openCustomTokenAndChannelName;

@property(nonatomic, assign) uint64_t customUid;

@property(nonatomic, strong) NSString *customChannelName;

@property(nonatomic, strong) NSString *customToken;

@property(nonatomic, strong) NSString *globalExtra;

@property(nonatomic, assign) BOOL isAudioConfirm;

@property(nonatomic, assign) BOOL isJoinRtcWhenCall;

@property(nonatomic, assign) BOOL isVideoConfirm;

@property(nonatomic, assign, readonly) bool incallShowCName;

@property(nonatomic, strong, nullable) UIImage *muteDefaultImage;

@property(nonatomic, strong, nullable) UIImage *remoteDefaultImage;

@property(nonatomic, assign) BOOL isGroupPush;

@property(nonatomic, strong) NSString *customPushContent;

@property(nonatomic, assign, readonly) BOOL isGlobalInit;

@property(nonatomic, assign, readonly) BOOL useEnableLocalMute;

+ (id)shareInstance;

- (void)setTimeoutWithSecond:(NSInteger)second;

- (void)setAutoJoin:(BOOL)autoJoin;

- (void)setBusyCode:(BOOL)open;

- (void)setCallKitUid:(uint64_t)uid;

- (void)setShowCName:(BOOL)show;

- (NSString *)getRtcCName;

- (uint64_t)getCallKitUid;

- (void)setEnableLocal:(BOOL)enable;

- (void)setIsGlobalInit:(BOOL)isGlobalInit
            withApnsCer:(NSString *)apnsCer
             withAppkey:(NSString *)appkey;

@end

NS_ASSUME_NONNULL_END
