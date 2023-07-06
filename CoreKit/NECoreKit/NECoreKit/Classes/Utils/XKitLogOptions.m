// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "XKitLogOptions.h"

@implementation XKitLogOptions
- (instancetype)init {
  self = [super init];
  if (self) {
    self.level = XKitLogLevelNone;
  }
  return self;
}
@end
