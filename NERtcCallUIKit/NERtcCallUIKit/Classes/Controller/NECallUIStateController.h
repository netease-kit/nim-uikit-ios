// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NECallUIKitConfig.h"
#import "NECustomButton.h"
#import "NEUICallParam.h"
#import "NEVideoOperationView.h"
#import "NEVideoView.h"
@class NECallViewController;
NS_ASSUME_NONNULL_BEGIN

@interface NECallUIStateController : UIViewController

/// 视频窗口(小)
@property(strong, nonatomic) NEVideoView *smallVideoView;
/// 视频窗口(大)
@property(strong, nonatomic) NEVideoView *bigVideoView;
/// 远端用户头像(主叫状态)
@property(strong, nonatomic) UIImageView *remoteAvatorView;
/// 远端用户头像(被叫&音频通话模式下使用)
@property(strong, nonatomic) UIImageView *remoteBigAvatorView;
/// 主叫远端用户显示(正在呼叫xxxxx...)
@property(strong, nonatomic) UILabel *titleLabel;
/// 远端用户名显示(被叫状态)
@property(strong, nonatomic) UILabel *centerTitleLabel;
/// 远端操作状态标签(主叫状态)
@property(strong, nonatomic) UILabel *subTitleLabel;
/// 邀请通话类型&远端状态
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
/// 通话中音视频操作工具栏
@property(strong, nonatomic) NEVideoOperationView *operationView;

/// 呼叫参数
@property(nonatomic, weak) NEUICallParam *callParam;
/// 配置参数
@property(nonatomic, weak) NECallUIConfig *config;

/// 状态栏高度
@property(nonatomic, assign, readonly) CGFloat statusHeight;
/// 内部圆角
@property(nonatomic, assign, readonly) CGFloat radius;
/// 标题字号
@property(nonatomic, assign, readonly) CGFloat titleFontSize;
/// 子标题字号
@property(nonatomic, assign, readonly) CGFloat subTitleFontSize;
/// 小屏幕适配系数
@property(nonatomic, assign, readonly) CGFloat factor;
/// 通话前按钮大小(挂断 接听 取消)
@property(nonatomic, assign, readonly) CGSize buttonSize;

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

- (NSString *)localizableWithKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
