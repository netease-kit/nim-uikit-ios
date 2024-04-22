// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NERingFile.h"
#import "NERtcCallUIKit.h"

@implementation NERingFile

- (instancetype)initWithBundle:(NSBundle *)bundle language:(NECallUILanguage)language {
  self = [super init];
  if (self) {
    switch (language) {
      case NECallUILanguageEn:
        [self setEnWithBundle:bundle];
        break;
      case NECallUILanguageZhHans:
        [self setZhWithBundle:bundle];
        break;
      case NECallUILanguageAuto: {
        NSString *language = [NSLocale preferredLanguages].firstObject;
        if ([language hasPrefix:@"en"]) {
          [self setEnWithBundle:bundle];
        } else {
          // 非英文情况下全部使用默认中文
          [self setZhWithBundle:bundle];
        }
        break;
      }
      default:
        break;
    }
  }
  return self;
}

- (void)setZhWithBundle:(NSBundle *)bundle {
  self.callerRingFilePath = [bundle pathForResource:@"avchat_connecting" ofType:@"mp3"];
  self.calleeRingFilePath = [bundle pathForResource:@"avchat_ring" ofType:@"mp3"];
  self.busyRingFilePath = [bundle pathForResource:@"avchat_peer_busy" ofType:@"mp3"];
  self.rejectRingFilePath = [bundle pathForResource:@"avchat_peer_reject" ofType:@"mp3"];
  self.noResponseFilePath = [bundle pathForResource:@"avchat_no_response" ofType:@"mp3"];
}

- (void)setEnWithBundle:(NSBundle *)bundle {
  self.callerRingFilePath = [bundle pathForResource:@"avchat_connecting_en" ofType:@"mp3"];
  self.calleeRingFilePath = [bundle pathForResource:@"avchat_ring_en" ofType:@"mp3"];
  self.busyRingFilePath = [bundle pathForResource:@"avchat_peer_busy_en" ofType:@"mp3"];
  self.rejectRingFilePath = [bundle pathForResource:@"avchat_peer_reject_en" ofType:@"mp3"];
  self.noResponseFilePath = [bundle pathForResource:@"avchat_no_response_en" ofType:@"mp3"];
}

@end
