// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NECalledViewController.h"

@interface NECalledViewController ()

@end

@implementation NECalledViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
}

- (void)setupUI {
  [super setupUI];
  /// 接听和拒接按钮
  [self.view addSubview:self.rejectBtn];
  [NSLayoutConstraint activateConstraints:@[
    [self.rejectBtn.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor
                                                 constant:-self.view.frame.size.width / 4.0],
    [self.rejectBtn.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor
                                                constant:-80 * self.factor],
    [self.rejectBtn.widthAnchor constraintEqualToConstant:self.buttonSize.width],
    [self.rejectBtn.heightAnchor constraintEqualToConstant:self.buttonSize.height]
  ]];

  [self.view addSubview:self.acceptBtn];
  [NSLayoutConstraint activateConstraints:@[
    [self.acceptBtn.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor
                                                 constant:self.view.frame.size.width / 4.0],
    [self.acceptBtn.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor
                                                constant:-80 * self.factor],
    [self.acceptBtn.widthAnchor constraintEqualToConstant:self.buttonSize.width],
    [self.acceptBtn.heightAnchor constraintEqualToConstant:self.buttonSize.height]
  ]];

  [self setupCenterRemoteAvator];

  [self refreshUI];
}

- (void)refreshUI {
  self.centerTitleLabel.text = self.callParam.remoteShowName.length > 0
                                   ? self.callParam.remoteShowName
                                   : self.callParam.remoteUserAccid;
  self.centerSubtitleLabel.text = [self getInviteText];
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
