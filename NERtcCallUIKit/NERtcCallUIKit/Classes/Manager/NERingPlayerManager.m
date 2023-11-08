//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NERingPlayerManager.h"
#import <AVFoundation/AVFoundation.h>
#import "NERtcCallUIKit.h"

@interface NERingPlayerManager () <AVAudioPlayerDelegate>

/// 播放伴音的id
@property(nonatomic, strong) NSMutableArray<NSString *> *ids;

/// 播放器
@property(nonatomic, strong) AVAudioPlayer *player;

@end

@implementation NERingPlayerManager

+ (id)shareInstance {
  static NERingPlayerManager *shareInstance = nil;
  static dispatch_once_t once_token;
  dispatch_once(&once_token, ^{
    if (!shareInstance) {
      shareInstance = [[self alloc] init];
    }
  });
  return shareInstance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    self.ids = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)stopCurrentPlaying {
  if ([self.player isPlaying]) {
    NSLog(@"stopCurrentPlaying");
    [self.player stop];
    self.player = nil;
  }
}

- (void)playRingWithRingType:(CallRingType)ringType isRtcPlay:(Boolean)isRtc {
  switch (ringType) {
    case CRTCallerRing:
      [self playerWithPath:[NERtcCallUIKit sharedInstance].ringFile.callerRingFilePath
                 isRtcPlay:isRtc
                  isRepeat:YES];
      break;
    case CRTCalleeRing:
      [self playerWithPath:[NERtcCallUIKit sharedInstance].ringFile.calleeRingFilePath
                 isRtcPlay:isRtc
                  isRepeat:YES];
      break;

    case CRTRejectRing:
      [self playerWithPath:[NERtcCallUIKit sharedInstance].ringFile.rejectRingFilePath
                 isRtcPlay:isRtc
                  isRepeat:NO];
      break;

    case CRTBusyRing:
      [self playerWithPath:[NERtcCallUIKit sharedInstance].ringFile.busyRingFilePath
                 isRtcPlay:isRtc
                  isRepeat:NO];
      break;

    case CRTNoResponseRing:
      [self playerWithPath:[NERtcCallUIKit sharedInstance].ringFile.noResponseFilePath
                 isRtcPlay:isRtc
                  isRepeat:NO];
      break;
    default:
      break;
  }
}

- (void)playerWithPath:(NSString *)path isRtcPlay:(BOOL)isRtc isRepeat:(BOOL)repeat {
  NSURL *url = nil;
  if ([path hasPrefix:@"http"]) {
    url = [NSURL URLWithString:path];
  } else if (path.length > 0) {
    url = [NSURL fileURLWithPath:path];
  }

  if (url != nil) {
    [self stopCurrentPlaying];
    [self resetAuidoSessionCategory];
    dispatch_async(dispatch_get_main_queue(), ^{
      NSError *error = nil;
      self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
      self.player.delegate = self;
      if (repeat == YES) {
        self.player.numberOfLoops = -1;
      } else {
        self.player.numberOfLoops = 1;
      }

      if (error == nil) {
        BOOL isPlay = [self.player play];
        NSLog(@"player play result : %d", isPlay);
      } else {
        NSLog(@"callkit audio player init error : %@", error.localizedDescription);
      }
    });
  }
}

- (void)resetAuidoSessionCategory {
  AVAudioSession *session = [AVAudioSession sharedInstance];
  [session setActive:YES error:nil];
  [session setCategory:AVAudioSessionCategoryPlayback error:nil];
}

#pragma mark - delegate

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
}

@end
