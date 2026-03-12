//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEConversationLoader.h"
#import <Foundation/Foundation.h>

#if __has_include(<NEConversationUIKit/NEConversationUIKit-Swift.h>)
#import <NEConversationUIKit/NEConversationUIKit-Swift.h>
#else
#import "NEConversationUIKit-Swift.h"
#endif

@implementation NEConversationLoader

static id gShareInstance = nil;

+ (instancetype)shareInstance {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    gShareInstance = [[self alloc] init];
  });
  return gShareInstance;
}

+ (void)load {
  NSLog(@"NEConversationLoader load");
  [NEConversationLoaderService.shared setupInit];
}

@end
