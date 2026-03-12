//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NELocalConversationLoader.h"
#import <Foundation/Foundation.h>

#if __has_include(<NELocalConversationUIKit/NELocalConversationUIKit-Swift.h>)
#import <NELocalConversationUIKit/NELocalConversationUIKit-Swift.h>
#else
#import "NELocalConversationUIKit-Swift.h"
#endif

@implementation NELocalConversationLoader

static id gShareInstance = nil;

+ (instancetype)shareInstance {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    gShareInstance = [[self alloc] init];
  });
  return gShareInstance;
}

+ (void)load {
  NSLog(@"NELocalConversationLoader load");
  [NELocalConversationLoaderService.shared setupInit];
}

@end
