//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEChatLoader.h"
#import <Foundation/Foundation.h>

#if __has_include(<NEChatUIKit/NEChatUIKit-Swift.h>)
#import <NEChatUIKit/NEChatUIKit-Swift.h>
#else
#import "NEChatUIKit-Swift.h"
#endif

@interface NEChatLoader ()

@end

@implementation NEChatLoader

static id gShareInstance = nil;

+ (instancetype)shareInstance {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    gShareInstance = [[self alloc] init];
  });
  return gShareInstance;
}

+ (void)load {
  NSLog(@"NEChatLoader load");
  [NEChatLoaderService.shared setupInit];
}

@end
