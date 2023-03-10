// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NECallParam.h"
#import "NECustomButton.h"
#import "NERtcCallUIConfig.h"
#import "NEVideoOperationView.h"
#import "NEVideoView.h"
@class NECallViewController;
NS_ASSUME_NONNULL_BEGIN

@interface NECallUIStateController : UIViewController

@property(strong, nonatomic) NEVideoView *smallVideoView;
@property(strong, nonatomic) NEVideoView *bigVideoView;
@property(strong, nonatomic) UIImageView *remoteAvatorView;
@property(strong, nonatomic) UIImageView *remoteBigAvatorView;
@property(strong, nonatomic) UILabel *titleLabel;
@property(strong, nonatomic) UILabel *centerTitleLabel;
@property(strong, nonatomic) UILabel *subTitleLabel;
@property(strong, nonatomic) UILabel *centerSubtitleLabel;

/// 取消呼叫
@property(strong, nonatomic) NECustomButton *cancelBtn;
/// 拒绝接听
@property(strong, nonatomic) NECustomButton *rejectBtn;
/// 接听
@property(strong, nonatomic) NECustomButton *acceptBtn;
/// 麦克风
@property(strong, nonatomic) NECustomButton *microphoneBtn;
/// 扬声器
@property(strong, nonatomic) NECustomButton *speakerBtn;

@property(strong, nonatomic) NEVideoOperationView *operationView;

// YES 主叫  NO 被叫
@property(nonatomic, assign) BOOL isCaller;

@property(nonatomic, weak) NECallParam *callParam;

@property(nonatomic, weak) NECallUIConfig *config;

@property(nonatomic, assign) CGFloat statusHeight;

@property(assign, nonatomic) CGFloat radius;

@property(assign, nonatomic) CGFloat titleFontSize;

@property(assign, nonatomic) CGFloat subTitleFontSize;

@property(assign, nonatomic) CGFloat factor;

@property(assign, nonatomic) CGSize buttonSize;

@property(nonatomic, assign) NERtcCallType callType;

@property(nonatomic, weak) NECallViewController *mainController;

@property(nonatomic, strong) NSBundle *bundle;

- (void)setupUI;

- (void)setupCenterRemoteAvator;

- (void)setupVideoCallingUI;

- (void)setupAudioCallingUI;

- (void)setupCalledUI;

- (void)setupAudioInCallUI;

- (NSString *)getInviteText;

- (void)refreshUI;

- (void)refreshVideoView;

@end

NS_ASSUME_NONNULL_END
