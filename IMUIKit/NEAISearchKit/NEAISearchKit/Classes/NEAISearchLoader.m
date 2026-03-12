// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAISearchLoader.h"
#import <Foundation/Foundation.h>

#if __has_include(<NEAISearchKit/NEAISearchKit-Swift.h>)
#import <NEAISearchKit/NEAISearchKit-Swift.h>
#else
#import "NEAISearchKit-Swift.h"
#endif

@implementation NEAISearchLoader

+ (void)load {
  [NEAISearchManager.shared setupInit];
}

@end
