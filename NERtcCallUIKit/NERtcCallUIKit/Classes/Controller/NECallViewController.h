// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NERtcCallKit/NERtcCallKit.h>
#import <UIKit/UIKit.h>
#import "NECallParam.h"
#import "NERtcCallUIConfig.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kCallKitDismissNoti;

@interface NECallViewController : UIViewController <NERtcCallKitDelegate>

@property(nonatomic, assign) NERtcCallStatus status;

@property(nonatomic, assign) NERtcCallType callType;

@property(nonatomic, strong) NECallParam *callParam;

@property(nonatomic, strong) NSMutableDictionary<NSString *, Class> *uiConfigDic;

@property(nonatomic, strong) NECallUIConfig *config;

// 当前用户视频显示位置
@property(nonatomic, assign) BOOL showMyBigView;

@property(nonatomic, assign) BOOL remoteCameraAvailable;

// 主叫
@property(nonatomic, assign) BOOL isCaller;

@end

NS_ASSUME_NONNULL_END
