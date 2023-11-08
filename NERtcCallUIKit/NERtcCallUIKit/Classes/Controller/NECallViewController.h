// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NERtcCallKit/NERtcCallKit.h>
#import <UIKit/UIKit.h>
#import "NECallUIKitConfig.h"
#import "NECallViewBaseController.h"
#import "NECustomButton.h"
#import "NEUICallParam.h"
#import "NEVideoView.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kCallKitDismissNoti;

@interface NECallViewController : NECallViewBaseController <NECallEngineDelegate>

@property(nonatomic, assign) NERtcCallStatus status;

@property(nonatomic, strong) NSMutableDictionary<NSString *, Class> *uiConfigDic;

@property(nonatomic, strong) NECallUIConfig *config;

/// 呼叫前音视频转换按钮
@property(strong, nonatomic) NECustomButton *mediaSwitchBtn;

// 当前用户视频显示位置
@property(nonatomic, assign) BOOL showMyBigView;

- (void)changeDefaultImage:(BOOL)mute;

- (void)changeRemoteMute:(BOOL)mute videoView:(NEVideoView *)remoteVideo;

- (void)destroy;

@end

NS_ASSUME_NONNULL_END
