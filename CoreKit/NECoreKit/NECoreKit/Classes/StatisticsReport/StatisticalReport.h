// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "BaseReportData.h"
#import "ReportActionInfo.h"
#import "ReportConfig.h"
#import "ReportPVInfo.h"
#import "ReportUVInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface StatisticalReport : NSObject

@property(nonatomic, strong) NSString *defaultKey;

@property(nonatomic, assign) NSInteger requestTimeOut;

+ (instancetype)sharedInstance;

- (void)reportConfig:(ReportConfig *)config;

- (void)registerModule:(NSString *)serviceName
           withVersion:(NSString *)versionName
          moduleAppKey:(NSString *)moduleAppKey;

- (void)reportWithServiceName:(NSString *)serviceName
                   withPVInfo:(ReportPVInfo *)pvInfo
                 withRightNow:(BOOL)rightNow;

- (void)reportWithServiceName:(NSString *)serviceName
                   withUVInfo:(ReportUVInfo *)uvInfo
                 withRightNow:(BOOL)rightNow;

//- (void)reportWithServiceName:(NSString *)serviceName
//               withActionInfo:(ReportActionInfo *)action
//                 withRightNow:(BOOL)rightNow;

//- (void)reportWithServiceName:(NSString *)serviceName withMsg:(NSString *)msg
// withRightNow:(BOOL)rightNow;

- (NSNumber *)beginReport:(NSString *)api params:(NSString *)params;

- (void)endReport:(NSString *)serviceName
        requestId:(NSNumber *)requestId
             code:(NSNumber *)code
         response:(NSString *)response
         rightNow:(BOOL)rightNow;

- (void)reportApiCallbackEvent:(NSString *)serviceName
                          info:(ApiCallbackEventInfo *)info
                      rightNow:(BOOL)rightNow;

- (void)reportCallbackEvent:(NSString *)serviceName
                       info:(CallbackEventInfo *)info
                   rightNow:(BOOL)rightNow;

/// 上报对象
/// @param data 数据对象
- (void)report:(nullable BaseReportData *)data;

/// 手动上传并清空缓存队列
- (void)flushAsync;

@end

NS_ASSUME_NONNULL_END
