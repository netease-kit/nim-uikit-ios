// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEVideoInCallController.h"

@interface NEVideoInCallController ()

@end

@implementation NEVideoInCallController

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

  [self.view addSubview:self.smallVideoView];
  [NSLayoutConstraint activateConstraints:@[
    [self.smallVideoView.topAnchor constraintEqualToAnchor:self.view.topAnchor
                                                  constant:self.statusHeight + 20],
    [self.smallVideoView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20],
    [self.smallVideoView.heightAnchor constraintEqualToConstant:160],
    [self.smallVideoView.widthAnchor constraintEqualToConstant:90]
  ]];

  self.smallVideoView.clipsToBounds = YES;
  self.smallVideoView.layer.cornerRadius = self.radius;
}

- (void)refreshUI {
  [self refreshVideoView];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before
navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
