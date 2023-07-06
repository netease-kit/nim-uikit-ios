
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NELog.h"
#import <NECoreKit/XKitLog.h>
static XKitLog *_log = nil;
@implementation NELog
+ (void)setUp {
  //  YXAlogOptions *opt = [[YXAlogOptions alloc] init];
  //  opt.path = [self getDirectoryForDocuments:@"IMDemo"];
  //  opt.level = YXAlogLevelInfo;
  //  opt.filePrefix = @"qchatLog";
  //  opt.moduleName = @"IMDemo";
  //  [[YXAlog shared] setupWithOptions:opt];

  XKitLogOptions *options = [[XKitLogOptions alloc] init];
  options.level = XKitLogLevelInfo;
  options.moduleName = @"IMDemo";
  //    options.sensitives = @[ appkey ];
  _log = [XKitLog setUp:options];
}

+ (void)apiLog:(NSString *)className desc:(NSString *)desc {
  [_log apiLog:className desc:[NSString stringWithFormat:@"🚰 %@", desc]];
}
+ (void)infoLog:(NSString *)className desc:(NSString *)desc {
  [_log infoLog:className desc:[NSString stringWithFormat:@"⚠️ %@", desc]];
}
/// warn类型 log
+ (void)warnLog:(NSString *)className desc:(NSString *)desc {
  [_log warnLog:className desc:[NSString stringWithFormat:@"❗️ %@", desc]];
}
+ (void)successLog:(NSString *)className desc:(NSString *)desc {
  [_log infoLog:className desc:[NSString stringWithFormat:@"✅ %@", desc]];
}
/// error类型 log
+ (void)errorLog:(NSString *)className desc:(NSString *)desc {
  [_log errorLog:className desc:[NSString stringWithFormat:@"❌ %@", desc]];
}
+ (void)messageLog:(NSString *)className desc:(NSString *)desc {
  [_log infoLog:className desc:[NSString stringWithFormat:@"✉️ %@", desc]];
}
+ (void)networkLog:(NSString *)className desc:(NSString *)desc {
  [_log infoLog:className desc:[NSString stringWithFormat:@"📶 %@", desc]];
}
@end
