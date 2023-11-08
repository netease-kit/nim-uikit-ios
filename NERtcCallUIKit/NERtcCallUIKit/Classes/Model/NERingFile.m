//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NERingFile.h"

@implementation NERingFile

- (instancetype)initWithBundle:(NSBundle *)bundle {
  self = [super init];
  if (self) {
    self.callerRingFilePath = [bundle pathForResource:@"avchat_connecting" ofType:@"mp3"];
    self.calleeRingFilePath = [bundle pathForResource:@"avchat_ring" ofType:@"mp3"];
    self.busyRingFilePath = [bundle pathForResource:@"avchat_peer_busy" ofType:@"mp3"];
    self.rejectRingFilePath = [bundle pathForResource:@"avchat_peer_reject" ofType:@"mp3"];
    self.noResponseFilePath = [bundle pathForResource:@"avchat_no_response" ofType:@"mp3"];
  }
  return self;
}

@end
