// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NERtcCallKit/NERtcCallKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NECallParam : NSObject

#pragma mark - 必要参数
// 被叫accid
@property(nonatomic, strong) NSString *remoteUserAccid;
// 主叫accid
@property(nonatomic, strong) NSString *currentUserAccid;
// 通话页面被叫显示名称
@property(nonatomic, strong) NSString *remoteShowName;
// 被叫头像链接
@property(nonatomic, strong) NSString *remoteAvatar;
// 呼叫类型
@property(assign, nonatomic) NERtcCallType callType;

#pragma mark - 可选自定义参数
@property(nonatomic, strong) NSString *token;
@property(nonatomic, strong) NSString *extra;
@property(nonatomic, strong) NSString *channelName;
@property(nonatomic, strong) NSString *attachment;

@end

NS_ASSUME_NONNULL_END
