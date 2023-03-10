// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAudioCallingController.h"

@interface NEAudioCallingController ()

@end

@implementation NEAudioCallingController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
}

- (void)setupUI {
  [super setupUI];
  [self setupCenterRemoteAvator];

  /// 取消按钮
  [self.view addSubview:self.cancelBtn];
  [NSLayoutConstraint activateConstraints:@[
    [self.cancelBtn.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.cancelBtn.widthAnchor constraintEqualToConstant:self.buttonSize.width],
    [self.cancelBtn.heightAnchor constraintEqualToConstant:self.buttonSize.height],
    [self.cancelBtn.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor
                                                constant:-80 * self.factor]
  ]];

  [self.view addSubview:self.microphoneBtn];
  [NSLayoutConstraint activateConstraints:@[
    [self.microphoneBtn.centerYAnchor constraintEqualToAnchor:self.cancelBtn.centerYAnchor],
    [self.microphoneBtn.centerXAnchor
        constraintEqualToAnchor:self.view.centerXAnchor
                       constant:-self.view.frame.size.width / 4.0 - 20],
    [self.microphoneBtn.widthAnchor constraintEqualToConstant:self.buttonSize.width],
    [self.microphoneBtn.heightAnchor constraintEqualToConstant:self.buttonSize.height]
  ]];

  [self.view addSubview:self.speakerBtn];
  [NSLayoutConstraint activateConstraints:@[
    [self.speakerBtn.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor
                                                  constant:self.view.frame.size.width / 4.0 + 20],
    [self.speakerBtn.centerYAnchor constraintEqualToAnchor:self.cancelBtn.centerYAnchor],
    [self.speakerBtn.heightAnchor constraintEqualToConstant:self.buttonSize.height],
    [self.speakerBtn.widthAnchor constraintEqualToConstant:self.buttonSize.width]
  ]];

  [self setupAudioCallingUI];
}

@end
