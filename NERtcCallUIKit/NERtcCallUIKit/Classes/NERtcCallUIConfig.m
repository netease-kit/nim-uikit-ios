// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NERtcCallUIConfig.h"

@implementation NECallUIConfig

@end

@implementation NERtcCallUIConfig

- (NECallUIConfig *)uiConfig {
  if (nil == _uiConfig) {
    _uiConfig = [[NECallUIConfig alloc] init];
  }
  return _uiConfig;
}

@end
