//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEContactLoader.h"
#import <Foundation/Foundation.h>

#if __has_include(<NEContactUIKit/NEContactUIKit-Swift.h>)
#import <NEContactUIKit/NEContactUIKit-Swift.h>
#else
#import "NEContactUIKit-Swift.h"
#endif

@implementation NEContactLoader

static id gShareInstance = nil;

+ (instancetype)shareInstance {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    gShareInstance = [[self alloc] init];
  });
  return gShareInstance;
}

+ (void)load {
  NSLog(@"NEContactUIKit load");
  [NEContactLoaderService.shared setupInit];
}

@end
