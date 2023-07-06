// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "ReportConfig.h"
NS_ASSUME_NONNULL_BEGIN

@interface BaseReportData : NSObject

@property(nonatomic, strong) NSString *appKey;
// 用户版本号
@property(nonatomic, strong) NSString *version;
// 组件名称，如 QChatKit, ContactKit, CallKit
@property(nonatomic, strong) NSString *component;
// 应用平台 iOS、MAC 等
@property(nonatomic, strong) NSString *platform;
// 系统时间戳
@property(nonatomic, assign) NSInteger timeStamp;
// Rtc SDK 版本
@property(nonatomic, strong) NSString *nertcVersion;
// IM SDK 版本
@property(nonatomic, strong) NSString *imVersion;
// 上报类型，可根据需要统计的特性填写，便于统计检索
@property(nonatomic, strong) NSString *reportType;
//// 上报的内容
@property(nonatomic, strong) id data;

- (instancetype)initWithConfig:(ReportConfig *)config;

@end

NS_ASSUME_NONNULL_END
