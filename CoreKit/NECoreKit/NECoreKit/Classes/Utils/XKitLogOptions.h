// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 日志级别
typedef enum {
  XKitLogLevelVerbose = 0,
  XKitLogLevelDebug,
  XKitLogLevelInfo,
  XKitLogLevelWarn,
  XKitLogLevelError,
  XKitLogLevelNone,
} XKitLogLevel;

@interface XKitLogOptions : NSObject

@property(nonatomic, assign) XKitLogLevel level;
@property(nonatomic, copy) NSString *moduleName;

/// 敏感词，匹配到之后日志会对其进行脱敏处理
@property(nonatomic, strong) NSArray<NSString *> *sensitives;

@end

NS_ASSUME_NONNULL_END
