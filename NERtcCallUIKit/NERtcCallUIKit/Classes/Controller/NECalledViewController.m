// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NECalledViewController.h"
#import <AVKit/AVKit.h>
#import "NECallKitUtil.h"

@interface NECalledViewController ()

@property(nonatomic, strong) UIView *preView;

@end

@implementation NECalledViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
}

- (void)setupUI {
  [self.view addSubview:self.preView];
  [NSLayoutConstraint activateConstraints:@[
    [self.preView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.preView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.preView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.preView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
  ]];

  [self checkCallePreview];

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

  self.connectingLabel = [[UILabel alloc] init];
  self.connectingLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.connectingLabel.text = [NECallKitUtil localizableWithKey:@"connecting"];
  self.connectingLabel.textColor = [UIColor whiteColor];
  self.connectingLabel.font = [UIFont systemFontOfSize:14];
  self.connectingLabel.hidden = YES;
  [self.view addSubview:self.connectingLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.connectingLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.connectingLabel.bottomAnchor constraintEqualToAnchor:self.acceptBtn.topAnchor
                                                      constant:-20],
  ]];

  [self refreshUI];
}

- (void)refreshUI {
  self.centerTitleLabel.text = self.callParam.remoteShowName.length > 0
                                   ? self.callParam.remoteShowName
                                   : self.callParam.remoteUserAccid;
  self.centerSubtitleLabel.text = [self getInviteText];
}

- (void)checkCallePreview {
  if (self.callParam.isCaller == NO && self.callParam.enableCalleePreview &&
      self.callParam.callType == NECallTypeVideo &&
      [[[NECallEngine sharedInstance] valueForKeyPath:@"context.initRtcMode"] intValue] !=
          InitRtcInNeedDelayToAccept) {
    self.preView.hidden = NO;
    NSLog(@"called preview");

    __weak typeof(self) weakSelf = self;

    AVAuthorizationStatus authorizationStatus =
        [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authorizationStatus == AVAuthorizationStatusNotDetermined) {
      // 请求摄像头权限
      [AVCaptureDevice
          requestAccessForMediaType:AVMediaTypeVideo
                  completionHandler:^(BOOL granted) {
                    if (granted) {
                      if (weakSelf != nil) {
                        [[NECallEngine sharedInstance] setupLocalView:weakSelf.preView];
                      }
                    } else {
                      // 用户未授权
                    }
                  }];
    } else if (authorizationStatus == AVAuthorizationStatusAuthorized) {
      if (weakSelf != nil) {
        [[NECallEngine sharedInstance] setupLocalView:weakSelf.preView];
      }
    } else {
      // 用户未授权
    }
  } else {
    self.preView.isHidden;
  }
}

- (UIView *)preView {
  if (nil == _preView) {
    _preView = [[UIView alloc] init];
    _preView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _preView;
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
