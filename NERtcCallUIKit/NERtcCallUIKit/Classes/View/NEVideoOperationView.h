// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEVideoOperationView : UIView
/// 麦克风
@property(strong, nonatomic) UIButton *microPhone;
/// 开启/关闭视频
@property(strong, nonatomic) UIButton *cameraBtn;
/// 挂断
@property(strong, nonatomic) UIButton *hangupBtn;
/// 开启/关闭静音
@property(strong, nonatomic) UIButton *speakerBtn;
/// 通话中音视频通话类型切换
@property(strong, nonatomic) UIButton *mediaBtn;
/// 虚化按钮
@property(strong, nonatomic) UIButton *virtualBtn;
/// 是否支持虚化
@property(assign, nonatomic) BOOL enableVirtualBackground;

- (void)changeAudioStyle;
- (void)changeVideoStyle;
- (void)hideMediaSwitch;

- (void)setGroupStyle;

- (void)removeMediaBtn;

@end

NS_ASSUME_NONNULL_END
