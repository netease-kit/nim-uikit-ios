// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEVideoOperationView : UIView
@property(strong, nonatomic) UIButton *microPhone;
@property(strong, nonatomic) UIButton *cameraBtn;
@property(strong, nonatomic) UIButton *hangupBtn;
@property(strong, nonatomic) UIButton *speakerBtn;
@property(strong, nonatomic) UIButton *mediaBtn;

- (void)changeAudioStyle;
- (void)changeVideoStyle;
- (void)hideMediaSwitch;

- (void)setGroupStyle;

@end

NS_ASSUME_NONNULL_END
