//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CallRingType) {
  CRTCallerRing = 1,      // 主叫呼叫铃声
  CRTCalleeRing = 2,      // 被叫收到邀请铃声
  CRTRejectRing = 3,      // 拒绝接听铃声
  CRTBusyRing = 4,        // 拒绝接听铃声
  CRTNoResponseRing = 5,  // 无响应铃声
};

NS_ASSUME_NONNULL_BEGIN

@interface NERingPlayerManager : NSObject

+ (id)shareInstance;

- (void)playRingWithRingType:(CallRingType)ringType isRtcPlay:(Boolean)isRtc;

- (void)stopCurrentPlaying;

@end

NS_ASSUME_NONNULL_END
