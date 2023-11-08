// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NetManager.h"
#import <NECommonKit/YXNetworkReachabilityManager.h>

@implementation NetManager

+ (id)shareInstance {
  static NetManager *shareInstance = nil;
  static dispatch_once_t once_token;
  dispatch_once(&once_token, ^{
    if (!shareInstance) {
      shareInstance = [[self alloc] init];
    }
  });
  return shareInstance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    [self monitorNetworkState];
  }
  return self;
}

#pragma mark - 监测网络状态
- (void)monitorNetworkState {
  YXNetworkReachabilityManager *manager = [YXNetworkReachabilityManager sharedManager];
  [manager startMonitoring];
  self.isClose = [manager isReachable] ? NO : YES;
  NSLog(@"net work close state : %d", self.isClose);
  [manager setReachabilityStatusChangeBlock:^(YXNetworkReachabilityStatus status) {
    switch (status) {
      case YXNetworkReachabilityStatusNotReachable:
        NSLog(@"没有网络");
        self.isClose = YES;
        break;
      case YXNetworkReachabilityStatusUnknown:
        NSLog(@"未知");
        self.isClose = YES;
        break;
      case YXNetworkReachabilityStatusReachableViaWiFi:
        NSLog(@"WiFi");
        self.isClose = NO;
        break;
      case YXNetworkReachabilityStatusReachableViaWWAN:
        NSLog(@"3G|4G");
        self.isClose = NO;
        break;
      default:
        break;
    }
  }];
}

@end
