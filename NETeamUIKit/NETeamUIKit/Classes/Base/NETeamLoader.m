//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETeamLoader.h"
#import <Foundation/Foundation.h>

#if __has_include(<NETeamUIKit/NETeamUIKit-Swift.h>)
#import <NETeamUIKit/NETeamUIKit-Swift.h>
#else
#import "NETeamUIKit-Swift.h"
#endif

@implementation NETeamLoader

static id gShareInstance = nil;

+ (instancetype)shareInstance {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    gShareInstance = [[self alloc] init];
  });
  return gShareInstance;
}

+ (void)load {
  NSLog(@"NETeamUIKit load");
  [NETeamLoaderService.shared setupInit];
}

@end
