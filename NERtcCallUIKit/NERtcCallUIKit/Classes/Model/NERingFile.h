//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NERingFile : NSObject

/// 主叫呼叫提示音
@property(nonatomic, strong, nullable) NSString *callerRingFilePath;

/// 被叫收到邀请提示音
@property(nonatomic, strong, nullable) NSString *calleeRingFilePath;

/// 拒绝提示音
@property(nonatomic, strong, nullable) NSString *rejectRingFilePath;

/// 忙线提示音
@property(nonatomic, strong, nullable) NSString *busyRingFilePath;

/// 无响应提示音
@property(nonatomic, strong, nullable) NSString *noResponseFilePath;

/// 初始化
- (instancetype)initWithBundle:(NSBundle *)bundle;

@end

NS_ASSUME_NONNULL_END
