// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MarvelWrapper.h"
#import <Marvel/Marvel.h>

@implementation MarvelWrapper

+ (void)initMarvel:(NSString *)appkey {
#if TARGET_OS_SIMULATOR
  // 当前是在模拟器上运行
  NSLog(@"Running on the simulator");
#else
  // 当前不是在模拟器上运行
  MarvelConfig *config = [MarvelConfig new];
  config.sdkVersion = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
  config.sdkName = @"IMUIKit";
  config.appKey = appkey;  // 企业申请服务开通的appkey
  [Marvel startWithMarvelId:@"4d833e5d4c9845bd892d8630175d6e96" config:config];
#endif
}

@end
