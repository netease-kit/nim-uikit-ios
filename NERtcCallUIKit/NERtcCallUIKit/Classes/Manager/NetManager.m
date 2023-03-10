// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NetManager.h"
#import "AFNetworking.h"

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
  AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
  [manager startMonitoring];
  self.isClose = [manager isReachable] ? NO : YES;
  NSLog(@"net work close state : %d", self.isClose);
  [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
    switch (status) {
      case AFNetworkReachabilityStatusNotReachable:
        NSLog(@"没有网络");
        self.isClose = YES;
        break;
      case AFNetworkReachabilityStatusUnknown:
        NSLog(@"未知");
        self.isClose = YES;
        break;
      case AFNetworkReachabilityStatusReachableViaWiFi:
        NSLog(@"WiFi");
        self.isClose = NO;
        break;
      case AFNetworkReachabilityStatusReachableViaWWAN:
        NSLog(@"3G|4G");
        self.isClose = NO;
        break;
      default:
        break;
    }
  }];
}

@end
