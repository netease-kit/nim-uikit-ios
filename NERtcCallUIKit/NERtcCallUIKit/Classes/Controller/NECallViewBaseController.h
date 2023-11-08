// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NERingPlayerManager.h"
#import "NEUICallParam.h"

NS_ASSUME_NONNULL_BEGIN

@interface NECallViewBaseController : UIViewController

@property(nonatomic, strong, nullable) NEUICallParam *callParam;

@property(nonatomic, strong) UIPanGestureRecognizer *panGesture;

@property(nonatomic, assign) CGFloat screenWidth;

@property(nonatomic, assign) CGFloat screenHeight;

/// 悬浮窗边距
@property(nonatomic, assign) CGFloat floatMargin;

/// 当前是否是小窗模式
@property(nonatomic, assign) BOOL isSmallWindow;

/// 音频浮窗
@property(nonatomic, strong) UIView *audioSmallView;

/// 音频小窗计时器
@property(nonatomic, strong) UILabel *audioSmallViewTimerLabel;

/// 资源包context
@property(nonatomic, strong) NSBundle *bundle;

/// 小窗模式根视图view。也作为视频通话小窗模式下的远端的预览视图
@property(nonatomic, strong) UIView *recoveryView;

///  远端关闭视频视图
@property(nonatomic, strong) UIView *maskView;

/// 视频小窗模式下，远端关闭摄像头状态下的头像
@property(nonatomic, strong) UIImageView *remoteHeaderImage;

// 远端视频是否是否关闭
@property(nonatomic, assign) BOOL isRemoteMute;

@property(nonatomic, assign) SEL createPipSEL;

@property(nonatomic, assign) SEL stopPipSEL;

/// 只用于跟未接通原因(话单)相关的toast，可根据外部配置是否显示toast
- (void)showToastWithContent:(NSString *)content;

- (void)setupSmallWindown;

- (void)changeToSmall;

- (void)changeToNormal;

/// 播放铃声
- (void)playRingWithType:(CallRingType)ringType;

/// 停止播放量铃声
- (void)stopCurrentPlaying;

// 设置声音设置输出到听筒
- (void)setAudioOutputToReceiver;

// 设置声音输出到扬声器
- (void)setAudioOutputToSpeaker;

// 获取非呼叫组件弹出的默认window
- (UIWindow *)preiousWindow;

@end

NS_ASSUME_NONNULL_END
