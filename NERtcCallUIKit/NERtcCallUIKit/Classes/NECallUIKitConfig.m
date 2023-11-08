// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NECallUIKitConfig.h"

@implementation NECallUIConfig

- (instancetype)init {
  self = [super init];
  if (self) {
    self.enableAudioToVideo = YES;
    self.enableVideoToAudio = YES;
  }
  return self;
}

@end

@implementation NECallUIKitConfig

- (NECallUIConfig *)uiConfig {
  if (nil == _uiConfig) {
    _uiConfig = [[NECallUIConfig alloc] init];
  }
  return _uiConfig;
}

@end
