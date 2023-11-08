// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEUICallParam.h"

@implementation NEUICallParam

- (instancetype)init {
  self = [super init];
  if (self) {
    self.enableShowRecorderToast = YES;
  }
  return self;
}

@end
