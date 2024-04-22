// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NERtcCallKit/NERtcCallKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEUICallParam : NSObject

#pragma mark - 必要参数

/// 被叫accid
@property(nonatomic, strong) NSString *remoteUserAccid;

/// 通话页面被叫显示名称
@property(nonatomic, strong) NSString *remoteShowName;

/// 被叫头像链接
@property(nonatomic, strong) NSString *remoteAvatar;

/// 呼叫类型
@property(assign, nonatomic) NECallType callType;

/// 是否是主叫 YES 表示主叫
@property(nonatomic, assign) BOOL isCaller;

#pragma mark - 可选自定义参数

/// 推送自定义配置
@property(nonatomic, strong, nullable) NECallPushConfig *pushConfig;

/// 全局抄送
@property(nonatomic, strong) NSString *extra;

/// 自定义channel name
@property(nonatomic, strong) NSString *channelName;

/// 呼叫扩展参数
@property(nonatomic, strong) NSString *attachment;

/// 自定义参数扩展
@property(nonatomic, strong) id customObject;

#pragma mark - UI配置参数

/// 本端关闭头像默认显示头像
@property(nonatomic, strong) UIImage *muteDefaultImage;

/// 远端关闭视频默认显示头像
@property(nonatomic, strong) UIImage *remoteDefaultImage;

/// 是否禁止音频通话转视频通话，默认YES，支持转换
@property(nonatomic, assign) BOOL enableAudioToVideo;

/// 是否禁止音频通话转视频通话，默认YES，支持转换
@property(nonatomic, assign) BOOL enableVideoToAudio;

/// 默认NO，关闭视频画面的时候使用 muteLocalVideo ，设置为YES时候，UI组件关闭视频时调用
/// enableLocalVideo 设置NO来停止本端视频流
@property(nonatomic, assign) BOOL useEnableLocalMute;

/// 是否开启内部话单弹框话单toast
@property(nonatomic, assign) BOOL enableShowRecorderToast;

/// 是否开启虚化功能，默认NO， 不开启
@property(nonatomic, assign) BOOL enableVirtualBackground;

/// 是否开启被叫预览，默认NO，不开启
@property(nonatomic, assign) BOOL enableCalleePreview;

/// 是否开启小窗功能，默认不开启
@property(nonatomic, assign) BOOL enableFloatingWindow;

/// 是否开启应用外小窗功能，默认不开启，开启后内部会使用 NECallEngine engineDelegate
/// 属性监听Rtc回调，如果已经使用，存在影响，请在外部根据画中画方案实现应用外小窗
@property(nonatomic, assign) BOOL enableFloatingWindowOutOfApp;

@end

NS_ASSUME_NONNULL_END
