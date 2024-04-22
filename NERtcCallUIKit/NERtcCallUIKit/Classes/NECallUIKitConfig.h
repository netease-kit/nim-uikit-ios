// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NERtcCallKit/NERtcCallKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 国际化类型
typedef NS_ENUM(NSInteger, NECallUILanguage) {
  /// 根据系统设置切换
  NECallUILanguageAuto = 0,
  /// 简体中文
  NECallUILanguageZhHans,
  /// 英文
  NECallUILanguageEn,
};

@interface NECallUIConfig : NSObject

/// 是否禁止音频通话转视频通话，默认YES，支持转换
@property(nonatomic, assign) BOOL enableAudioToVideo;

/// 是否禁止音频通话转视频通话，默认YES，支持转换
@property(nonatomic, assign) BOOL enableVideoToAudio;

/// 收到呼叫时是否禁止弹出被叫页面，默认NO，弹出被叫页面，用户可以通过此配置禁止组件弹出，自己通过继承以及监听被叫回调实现相关功能
@property(nonatomic, assign) BOOL disableShowCalleeView;

/// 通话前音视频切换按钮是否显示，默认NO，不显示，开启此配置前需要开启 NERtcCallOptions 中
/// supportAutoJoinWhenCalled 属性
@property(nonatomic, assign) BOOL showCallingSwitchCallType;

/// 被叫显示昵称字段还是手机号字段，默认显示昵称
@property(nonatomic, assign) BOOL calleeShowPhone;

/// 默认NO，关闭视频画面的时候使用 muteLocalVideo ，设置为YES时候，UI组件关闭视频时调用
/// enableLocalVideo 设置NO来停止本端视频流
@property(nonatomic, assign) BOOL useEnableLocalMute;

/// 是否开启小窗功能，默认不开启
@property(nonatomic, assign) BOOL enableFloatingWindow;

/// 是否开启应用外小窗功能，默认不开启，开启后内部会使用 NECallEngine engineDelegate
/// 属性监听Rtc回调，如果已经使用，存在影响，请在外部根据画中画方案实现应用外小窗
@property(nonatomic, assign) BOOL enableFloatingWindowOutOfApp;

/// 是否开启虚化功能，默认NO， 不开启
@property(nonatomic, assign) BOOL enableVirtualBackground;

/// 是否开启被叫预览，默认NO，不开启
@property(nonatomic, assign) BOOL enableCalleePreview;

/// 国际化配置
@property(nonatomic, assign) NECallUILanguage language;

@end

@interface NECallUIKitConfig : NSObject

/// 透传 NECallEngine 初始化配置，如果不需要UI组件内部初始化 NECallEngine 则不传此参数即可
@property(nonatomic, strong, nullable) NESetupConfig *config;

/// appkey
@property(nonatomic, strong) NSString *appKey;

/// UI 配置
@property(nonatomic, strong) NECallUIConfig *uiConfig;

@end

NS_ASSUME_NONNULL_END
