// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NERtcCallKit/NERtcCallKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NECallUIConfig : NSObject

/// 是否禁止音频通话转视频通话，默认NO，支持转换
@property(nonatomic, assign) BOOL audioToVideoDisable;

/// 是否禁止音频通话转视频通话，默认NO，支持转换
@property(nonatomic, assign) BOOL videoToAudioDisable;

/// 收到呼叫时是否禁止弹出被叫页面，默认NO，弹出被叫页面，用户可以通过此配置禁止组件弹出，自己通过继承以及监听被叫回调实现相关功能
@property(nonatomic, assign) BOOL disableShowCalleeView;

/// 是否初始化路由配置，默认NO，不进行路由初始化配置
@property(nonatomic, assign) BOOL isInitRouter;

/// 通话前音视频切换按钮是否显示，默认NO，不显示，开启此配置前需要开启 NERtcCallOptions 中
/// supportAutoJoinWhenCalled 属性
@property(nonatomic, assign) BOOL showCallingSwitchCallType;

/// 被叫显示昵称字段还是手机号字段，默认显示昵称
@property(nonatomic, assign) BOOL calleeShowPhone;

@end

@interface NERtcCallUIConfig : NSObject

/// 透传 NERtcCallKit 初始化配置，如果不需要UI组件内部初始化 NERtcCallKit 则不传此参数即可
@property(nonatomic, strong) NERtcCallOptions *option;

/// appkey
@property(nonatomic, strong) NSString *appKey;

/// UI 配置
@property(nonatomic, strong) NECallUIConfig *uiConfig;

@end

NS_ASSUME_NONNULL_END
