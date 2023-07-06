// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "XKit.h"
#import "StatisticalReport.h"
#import "XKitLog.h"
#import "XKitServiceManager.h"

static NSString *tag = @"XKitCore";

static id instance;

@implementation XKit

+ (instancetype)instance {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = self.new;
  });
  return instance;
}

- (void)registerService:(id<XKitService>)service {
  if ([service respondsToSelector:@selector(serviceName)] &&
      [service respondsToSelector:@selector(versionName)] &&
      [service respondsToSelector:@selector(appKey)]) {
    [[XKitServiceManager getInstance] registerService:service.serviceName service:service];
    [[StatisticalReport sharedInstance] registerModule:service.serviceName
                                           withVersion:service.versionName
                                          moduleAppKey:service.appKey];
  }
}

@end
