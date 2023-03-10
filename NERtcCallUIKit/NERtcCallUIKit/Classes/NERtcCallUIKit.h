// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#ifndef NERtcCallUIKit_h
#define NERtcCallUIKit_h

#import "NECallParam.h"
#import "NECallViewController.h"
#import "NECustomButton.h"
#import "NEExpandButton.h"
#import "NERtcCallUIConfig.h"
#import "NEVideoOperationView.h"
#import "NEVideoView.h"
#import "NetManager.h"
#import "SettingManager.h"

#import "NEAudioCallingController.h"
#import "NEAudioInCallController.h"
#import "NECalledViewController.h"
#import "NEVideoCallingController.h"
#import "NEVideoInCallController.h"

// 音频呼叫中UI状态
extern NSString *_Nonnull kAudioCalling;
// 视频呼叫中UI状态
extern NSString *_Nonnull kVideoCalling;
// 音频通话中UI状态
extern NSString *_Nonnull kAudioInCall;
// 视频通话中UI状态
extern NSString *_Nonnull kVideoInCall;
// 被叫UI状态(音频&视频)
extern NSString *_Nonnull kCalledState;

#endif /* NERtcCallUIKit_h */

NS_ASSUME_NONNULL_BEGIN

@interface NERtcCallUIKit : NSObject

/// UI状态配置类，如果用户需要自定义某个状态的UI，需要继承通话状态类，通过对应key值覆盖对应Class
@property(nonatomic, strong, readonly) NSMutableDictionary<NSString *, Class> *uiConfigDic;

+ (instancetype)sharedInstance;

/// 初始化，所有功能需要先初始化
/// @param config 初始化参数
- (void)setupWithConfig:(NERtcCallUIConfig *)config;

- (void)callWithParam:(NECallParam *)callParam withCallType:(NERtcCallType)callType;

/// 版本号
+ (NSString *)version;

@end

NS_ASSUME_NONNULL_END
