// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAudioInCallController.h"

@interface NEAudioInCallController ()

@end

@implementation NEAudioInCallController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
}

- (void)setupUI {
  [super setupUI];
  [self setupCenterRemoteAvator];
  [self setupAudioInCallUI];
}

@end
