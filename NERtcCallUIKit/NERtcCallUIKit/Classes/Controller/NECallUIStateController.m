// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NECallUIStateController.h"
#import <NECommonKit/NECommonKit-Swift.h>
#import <NERtcCallKit/NERtcCallKit.h>
#import <SDWebImage/SDWebImage.h>
#import "NECallViewController.h"

@interface NECallUIStateController ()

@property(nonatomic, weak) UIView *parentView;

@end

@implementation NECallUIStateController

- (instancetype)init {
  self = [super init];
  if (self) {
    self.factor = 1;
    self.radius = 4.0;
    self.titleFontSize = 20.0;
    self.subTitleFontSize = 14.0;
    self.buttonSize = CGSizeMake(75, 103);
    self.bundle = [NSBundle bundleForClass:self.class];
  }
  return self;
}

//- (void)loadView {
//    NSLog(@"state view load parent view %@",self.parentView);
//    self.view = self.parentView;
//}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  self.view.backgroundColor = [UIColor clearColor];
  if (self.view.frame.size.height < 600) {
    self.factor = 0.5;
  }
  self.statusHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
  [self setupUI];
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

#pragma mark lazy init

- (NEVideoView *)bigVideoView {
  if (!_bigVideoView) {
    _bigVideoView = [[NEVideoView alloc] init];
    _bigVideoView.backgroundColor = [UIColor darkGrayColor];
    _bigVideoView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _bigVideoView;
}

- (NEVideoView *)smallVideoView {
  if (!_smallVideoView) {
    _smallVideoView = [[NEVideoView alloc] init];
    _smallVideoView.backgroundColor = [UIColor darkGrayColor];
    UITapGestureRecognizer *tap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchVideoView:)];
    [_smallVideoView addGestureRecognizer:tap];
    _smallVideoView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _smallVideoView;
}

- (void)switchVideoView:(UITapGestureRecognizer *)tap {
  self.mainController.showMyBigView = !self.mainController.showMyBigView;
  [self refreshVideoView];
  // TODO: 代码整理
  //  [self changeDefaultImage:self.operationView.cameraBtn.selected];
}

- (UIImageView *)remoteAvatorView {
  if (!_remoteAvatorView) {
    _remoteAvatorView = [[UIImageView alloc] init];
    _remoteAvatorView.image = [UIImage imageNamed:@"avator"
                                         inBundle:self.bundle
                    compatibleWithTraitCollection:nil];
    _remoteAvatorView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _remoteAvatorView;
}

- (UILabel *)titleLabel {
  if (!_titleLabel) {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont boldSystemFontOfSize:self.titleFontSize];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.textAlignment = NSTextAlignmentRight;
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _titleLabel;
}

- (UILabel *)subTitleLabel {
  if (!_subTitleLabel) {
    _subTitleLabel = [[UILabel alloc] init];
    _subTitleLabel.font = [UIFont boldSystemFontOfSize:self.subTitleFontSize];
    _subTitleLabel.textColor = [UIColor whiteColor];
    _subTitleLabel.text = [self localizableWithKey:@"waitting_remote_response"];
    _subTitleLabel.textAlignment = NSTextAlignmentRight;
    _subTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _subTitleLabel;
}

- (NECustomButton *)cancelBtn {
  if (!_cancelBtn) {
    _cancelBtn = [[NECustomButton alloc] init];
    _cancelBtn.titleLabel.text = [self localizableWithKey:@"call_cancel"];
    _cancelBtn.imageView.image = [UIImage imageNamed:@"call_cancel"
                                            inBundle:self.bundle
                       compatibleWithTraitCollection:nil];
    _cancelBtn.maskBtn.accessibilityIdentifier = @"cancel_btn";
    [_cancelBtn.maskBtn addTarget:self.mainController
                           action:@selector(cancelEvent:)
                 forControlEvents:UIControlEventTouchUpInside];
  }
  return _cancelBtn;
}

- (NECustomButton *)rejectBtn {
  if (!_rejectBtn) {
    _rejectBtn = [[NECustomButton alloc] init];
    _rejectBtn.titleLabel.text = [self localizableWithKey:@"call_reject"];
    _rejectBtn.imageView.image = [UIImage imageNamed:@"call_cancel"
                                            inBundle:self.bundle
                       compatibleWithTraitCollection:nil];
    _rejectBtn.maskBtn.accessibilityIdentifier = @"reject_btn";
    [_rejectBtn.maskBtn addTarget:self.mainController
                           action:@selector(rejectEvent:)
                 forControlEvents:UIControlEventTouchUpInside];
  }
  return _rejectBtn;
}

- (NECustomButton *)acceptBtn {
  if (!_acceptBtn) {
    _acceptBtn = [[NECustomButton alloc] init];
    _acceptBtn.titleLabel.text = [self localizableWithKey:@"call_accept"];
    _acceptBtn.imageView.image = [UIImage imageNamed:@"call_accept"
                                            inBundle:self.bundle
                       compatibleWithTraitCollection:nil];
    _acceptBtn.imageView.contentMode = UIViewContentModeCenter;
    _acceptBtn.maskBtn.accessibilityIdentifier = @"accept_btn";
    [_acceptBtn.maskBtn addTarget:self.mainController
                           action:@selector(acceptEvent:)
                 forControlEvents:UIControlEventTouchUpInside];
  }
  return _acceptBtn;
}

- (NECustomButton *)microphoneBtn {
  if (nil == _microphoneBtn) {
    _microphoneBtn = [[NECustomButton alloc] init];
    _microphoneBtn.titleLabel.text = [self localizableWithKey:@"call_micro_phone"];
    _microphoneBtn.imageView.image = [UIImage imageNamed:@"micro_phone"
                                                inBundle:self.bundle
                           compatibleWithTraitCollection:nil];
    _microphoneBtn.imageView.highlightedImage = [UIImage imageNamed:@"micro_phone_mute"
                                                           inBundle:self.bundle
                                      compatibleWithTraitCollection:nil];
    _microphoneBtn.imageView.contentMode = UIViewContentModeCenter;
    _microphoneBtn.maskBtn.accessibilityIdentifier = @"micro_phone";
    [_microphoneBtn.maskBtn addTarget:self.mainController
                               action:@selector(microphoneBtnClick:)
                     forControlEvents:UIControlEventTouchUpInside];
  }
  return _microphoneBtn;
}

- (NECustomButton *)speakerBtn {
  if (nil == _speakerBtn) {
    _speakerBtn = [[NECustomButton alloc] init];
    _speakerBtn.titleLabel.text = [self localizableWithKey:@"call_speaker"];
    _speakerBtn.imageView.image = [UIImage imageNamed:@"speaker_off"
                                             inBundle:self.bundle
                        compatibleWithTraitCollection:nil];
    _speakerBtn.imageView.highlightedImage = [UIImage imageNamed:@"speaker_on"
                                                        inBundle:self.bundle
                                   compatibleWithTraitCollection:nil];
    _speakerBtn.imageView.contentMode = UIViewContentModeCenter;
    _speakerBtn.maskBtn.accessibilityIdentifier = @"speaker";
    [_speakerBtn.maskBtn addTarget:self.mainController
                            action:@selector(speakerBtnClick:)
                  forControlEvents:UIControlEventTouchUpInside];
  }
  return _speakerBtn;
}

- (UILabel *)centerSubtitleLabel {
  if (nil == _centerSubtitleLabel) {
    _centerSubtitleLabel = [[UILabel alloc] init];
    _centerSubtitleLabel.textColor = [UIColor whiteColor];
    _centerSubtitleLabel.font = [UIFont systemFontOfSize:self.subTitleFontSize];
    _centerSubtitleLabel.text = [self localizableWithKey:@"waitting_remote_accept"];
    _centerSubtitleLabel.textAlignment = NSTextAlignmentCenter;
    _centerSubtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _centerSubtitleLabel;
}

- (UILabel *)centerTitleLabel {
  if (nil == _centerTitleLabel) {
    _centerTitleLabel = [[UILabel alloc] init];
    _centerTitleLabel.textColor = [UIColor whiteColor];
    _centerTitleLabel.font = [UIFont systemFontOfSize:self.titleFontSize];
    _centerTitleLabel.textAlignment = NSTextAlignmentCenter;
    _centerTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _centerTitleLabel;
}

- (UIImageView *)remoteBigAvatorView {
  if (nil == _remoteBigAvatorView) {
    _remoteBigAvatorView = [[UIImageView alloc] init];
    _remoteBigAvatorView.image = [UIImage imageNamed:@"avator"
                                            inBundle:self.bundle
                       compatibleWithTraitCollection:nil];
    _remoteBigAvatorView.clipsToBounds = YES;
    _remoteBigAvatorView.layer.cornerRadius = self.radius;
    _remoteBigAvatorView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _remoteBigAvatorView;
}

#pragma mark - publick

- (void)setupCenterRemoteAvator {
  [self.view addSubview:self.centerSubtitleLabel];

  [NSLayoutConstraint activateConstraints:@[
    [self.centerSubtitleLabel.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.centerSubtitleLabel.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.centerSubtitleLabel.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor
                                                          constant:-(233 * self.factor + 163)],
    [self.centerSubtitleLabel.heightAnchor constraintEqualToConstant:self.titleFontSize + 2]
  ]];

  [self.view addSubview:self.centerTitleLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.centerTitleLabel.bottomAnchor constraintEqualToAnchor:self.centerSubtitleLabel.topAnchor
                                                       constant:-10 * self.factor],
    [self.centerTitleLabel.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.centerTitleLabel.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.centerTitleLabel.heightAnchor constraintEqualToConstant:self.titleFontSize + 2]

  ]];

  [self.view addSubview:self.remoteBigAvatorView];
  [NSLayoutConstraint activateConstraints:@[
    [self.remoteBigAvatorView.heightAnchor constraintEqualToConstant:90],
    [self.remoteBigAvatorView.widthAnchor constraintEqualToConstant:90],
    [self.remoteBigAvatorView.bottomAnchor constraintEqualToAnchor:self.centerTitleLabel.topAnchor
                                                          constant:-10 * self.factor],
    [self.remoteBigAvatorView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor]
  ]];

  if (self.callParam.remoteAvatar.length <= 0) {
    UIView *cover = [self getDefaultHeaderView:self.callParam.remoteUserAccid
                                          font:[UIFont systemFontOfSize:self.titleFontSize]
                                      showName:self.callParam.remoteShowName];
    [self.remoteBigAvatorView addSubview:cover];
    [NSLayoutConstraint activateConstraints:@[
      [cover.leftAnchor constraintEqualToAnchor:self.remoteBigAvatorView.leftAnchor],
      [cover.rightAnchor constraintEqualToAnchor:self.remoteBigAvatorView.rightAnchor],
      [cover.topAnchor constraintEqualToAnchor:self.remoteBigAvatorView.topAnchor],
      [cover.bottomAnchor constraintEqualToAnchor:self.remoteBigAvatorView.bottomAnchor]
    ]];
  }
}

- (void)setupUI {
}

- (void)refreshUI {
}

- (void)setupVideoCallingUI {
  self.titleLabel.text = [NSString stringWithFormat:@"%@ %@", [self localizableWithKey:@"calling"],
                                                    self.callParam.remoteShowName];
  self.subTitleLabel.text = [self localizableWithKey:@"waitting_remote_accept"];

  if (self.callParam.remoteAvatar.length <= 0) {
    UIView *cover = [self getDefaultHeaderView:self.callParam.remoteUserAccid
                                          font:[UIFont systemFontOfSize:self.titleFontSize]
                                      showName:self.callParam.remoteShowName];
    [self.remoteAvatorView addSubview:cover];
    [NSLayoutConstraint activateConstraints:@[
      [cover.leftAnchor constraintEqualToAnchor:self.remoteAvatorView.leftAnchor],
      [cover.rightAnchor constraintEqualToAnchor:self.remoteAvatorView.rightAnchor],
      [cover.topAnchor constraintEqualToAnchor:self.remoteAvatorView.topAnchor],
      [cover.bottomAnchor constraintEqualToAnchor:self.remoteAvatorView.bottomAnchor]
    ]];
  } else {
    [self.remoteAvatorView sd_setImageWithURL:[NSURL URLWithString:self.callParam.remoteAvatar]
                             placeholderImage:[UIImage imageNamed:@"avator"
                                                                       inBundle:self.bundle
                                                  compatibleWithTraitCollection:nil]];
  }
}

- (void)setupAudioCallingUI {
  self.centerTitleLabel.text =
      [NSString stringWithFormat:@"%@ %@", [self localizableWithKey:@"calling"],
                                 self.callParam.remoteShowName];
  self.centerSubtitleLabel.text = [self localizableWithKey:@"waitting_remote_accept"];
  if (self.callParam.remoteAvatar.length <= 0) {
    UIView *cover = [self getDefaultHeaderView:self.callParam.remoteUserAccid
                                          font:[UIFont systemFontOfSize:self.titleFontSize]
                                      showName:self.callParam.remoteShowName];
    [self.remoteBigAvatorView addSubview:cover];
    [NSLayoutConstraint activateConstraints:@[
      [cover.leftAnchor constraintEqualToAnchor:self.remoteBigAvatorView.leftAnchor],
      [cover.rightAnchor constraintEqualToAnchor:self.remoteBigAvatorView.rightAnchor],
      [cover.topAnchor constraintEqualToAnchor:self.remoteBigAvatorView.topAnchor],
      [cover.bottomAnchor constraintEqualToAnchor:self.remoteBigAvatorView.bottomAnchor]
    ]];
  } else {
    [self.remoteBigAvatorView sd_setImageWithURL:[NSURL URLWithString:self.callParam.remoteAvatar]
                                placeholderImage:[UIImage imageNamed:@"avator"
                                                                          inBundle:self.bundle
                                                     compatibleWithTraitCollection:nil]];
  }
}

- (void)setupAudioInCallUI {
  [self.remoteBigAvatorView sd_setImageWithURL:[NSURL URLWithString:self.callParam.remoteAvatar]
                              placeholderImage:[UIImage imageNamed:@"avator"
                                                                        inBundle:self.bundle
                                                   compatibleWithTraitCollection:nil]];
  self.centerTitleLabel.text = [NSString stringWithFormat:@"%@", self.callParam.remoteShowName];
  self.centerSubtitleLabel.hidden = YES;
}

- (void)setupCalledUI {
  self.centerTitleLabel.text = [NSString stringWithFormat:@"%@", self.callParam.remoteShowName];
}

- (NSString *)getInviteText {
  return (self.callType == NERtcCallTypeAudio ? [self localizableWithKey:@"invite_audio_call"]
                                              : [self localizableWithKey:@"invite_video_call"]);
}

- (void)refreshVideoView {
  if (self.mainController.showMyBigView) {
    [[NERtcCallKit sharedInstance] setupLocalView:self.bigVideoView.videoView];
    [[NERtcCallKit sharedInstance] setupRemoteView:self.smallVideoView.videoView
                                           forUser:self.callParam.remoteUserAccid];
    NSLog(@"show my big view");
    self.smallVideoView.maskView.hidden = self.mainController.remoteCameraAvailable;
    self.bigVideoView.maskView.hidden = !self.operationView.cameraBtn.selected;
    self.bigVideoView.userID = self.callParam.currentUserAccid;
    self.smallVideoView.userID = self.callParam.remoteUserAccid;
  } else {
    [[NERtcCallKit sharedInstance] setupLocalView:self.smallVideoView.videoView];
    [[NERtcCallKit sharedInstance] setupRemoteView:self.bigVideoView.videoView
                                           forUser:self.callParam.remoteUserAccid];
    NSLog(@"show my small view");
    self.bigVideoView.maskView.hidden = self.mainController.remoteCameraAvailable;
    self.smallVideoView.maskView.hidden = !self.operationView.cameraBtn.selected;
    self.bigVideoView.userID = self.callParam.remoteUserAccid;
    self.smallVideoView.userID = self.callParam.currentUserAccid;
  }
}

- (UIView *)getDefaultHeaderView:(NSString *)accid
                            font:(UIFont *)font
                        showName:(NSString *)showName {
  UIView *headerView = [[UIView alloc] init];
  headerView.backgroundColor = [UIColor colorWithStringWithString:accid];
  headerView.translatesAutoresizingMaskIntoConstraints = NO;
  NSString *show = showName.length > 0 ? showName : accid;
  if (show.length >= 2) {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [headerView addSubview:label];
    label.textColor = [UIColor whiteColor];
    label.font = font;
    label.text = [show substringWithRange:NSMakeRange(show.length - 2, 2)];
    [NSLayoutConstraint activateConstraints:@[
      [label.centerYAnchor constraintEqualToAnchor:headerView.centerYAnchor],
      [label.centerXAnchor constraintEqualToAnchor:headerView.centerXAnchor]
    ]];
  }
  return headerView;
}

- (NSString *)localizableWithKey:(NSString *)key {
  return [self.bundle localizedStringForKey:key value:nil table:@"Localizable"];
  ;
}

@end
