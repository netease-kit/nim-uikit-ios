// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEVideoCallingController.h"

@interface NEVideoCallingController ()

@end

@implementation NEVideoCallingController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
}

- (void)setupUI {
  [super setupUI];

  [self.view addSubview:self.bigVideoView];
  [NSLayoutConstraint activateConstraints:@[
    [self.bigVideoView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.bigVideoView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.bigVideoView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.bigVideoView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
  ]];

  //    [self.view addSubview:self.smallVideoView];
  //    [NSLayoutConstraint activateConstraints:@[
  //      [self.smallVideoView.topAnchor constraintEqualToAnchor:self.view.topAnchor
  //                                                    constant:self.statusHeight + 20],
  //      [self.smallVideoView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor
  //      constant:-20], [self.smallVideoView.heightAnchor constraintEqualToConstant:160],
  //      [self.smallVideoView.widthAnchor constraintEqualToConstant:90]
  //    ]];
  //
  //    self.smallVideoView.clipsToBounds = YES;
  //    self.smallVideoView.layer.cornerRadius = self.radius;
  //    self.smallVideoView.hidden = YES;

  [self.view addSubview:self.remoteAvatorView];
  [NSLayoutConstraint activateConstraints:@[
    [self.remoteAvatorView.topAnchor constraintEqualToAnchor:self.view.topAnchor
                                                    constant:self.statusHeight + 20],
    [self.remoteAvatorView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20],
    [self.remoteAvatorView.heightAnchor constraintEqualToConstant:60],
    [self.remoteAvatorView.widthAnchor constraintEqualToConstant:60]
  ]];

  self.remoteAvatorView.clipsToBounds = YES;
  self.remoteAvatorView.layer.cornerRadius = self.radius;

  [self.view addSubview:self.titleLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.topAnchor constraintEqualToAnchor:self.remoteAvatorView.topAnchor constant:5],
    [self.titleLabel.rightAnchor constraintEqualToAnchor:self.remoteAvatorView.leftAnchor
                                                constant:-8],
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20],
    [self.titleLabel.heightAnchor constraintEqualToConstant:25]
  ]];

  [self.view addSubview:self.subTitleLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.subTitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor],
    [self.subTitleLabel.rightAnchor constraintEqualToAnchor:self.titleLabel.rightAnchor],
    [self.subTitleLabel.leftAnchor constraintEqualToAnchor:self.titleLabel.leftAnchor],
    [self.subTitleLabel.heightAnchor constraintEqualToConstant:20]
  ]];

  /// 取消按钮
  [self.view addSubview:self.cancelBtn];
  [NSLayoutConstraint activateConstraints:@[
    [self.cancelBtn.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.cancelBtn.widthAnchor constraintEqualToConstant:self.buttonSize.width],
    [self.cancelBtn.heightAnchor constraintEqualToConstant:self.buttonSize.height],
    [self.cancelBtn.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor
                                                constant:-80 * self.factor]
  ]];

  [self setupVideoCallingUI];
}

@end
