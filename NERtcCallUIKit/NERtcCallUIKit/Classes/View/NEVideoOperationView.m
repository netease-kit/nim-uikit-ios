// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEVideoOperationView.h"

@interface NEVideoOperationView ()

@property(nonatomic, strong) UIStackView *stack;

@property(nonatomic, strong) NSBundle *bundle;

@end

@implementation NEVideoOperationView
- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.bundle = [NSBundle bundleForClass:NEVideoOperationView.class];
    [self setupUI];
  }
  return self;
}
- (void)setupUI {
  self.backgroundColor = [UIColor colorWithRed:39 / 255.0
                                         green:48 / 255.0
                                          blue:48 / 255.0
                                         alpha:1.0];
  UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[
    self.microPhone, self.cameraBtn, self.speakerBtn, self.mediaBtn, self.hangupBtn
  ]];
  stackView.distribution =
      UIStackViewDistributionEqualCentering;  // UIStackViewDistributionFillEqually;

  [self addSubview:stackView];
  stackView.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [stackView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:20],
    [stackView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-20],
    [stackView.topAnchor constraintEqualToAnchor:self.topAnchor constant:0],
    [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0],

  ]];
  //  [stackView mas_makeConstraints:^(MASConstraintMaker *make) {
  //    make.edges.mas_equalTo(UIEdgeInsetsMake(0, 20, 0, 20));
  //  }];
  self.stack = stackView;
}
- (UIButton *)microPhone {
  if (!_microPhone) {
    _microPhone = [UIButton buttonWithType:UIButtonTypeCustom];
    [_microPhone setImage:[UIImage imageNamed:@"call_voice_on"
                                                   inBundle:self.bundle
                              compatibleWithTraitCollection:nil]
                 forState:UIControlStateNormal];
    [_microPhone setImage:[UIImage imageNamed:@"call_voice_off"
                                                   inBundle:self.bundle
                              compatibleWithTraitCollection:nil]
                 forState:UIControlStateSelected];
    _microPhone.accessibilityIdentifier = @"op_micro_phone";
  }
  return _microPhone;
}
- (UIButton *)cameraBtn {
  if (!_cameraBtn) {
    _cameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_cameraBtn setImage:[UIImage imageNamed:@"call_camera_on"
                                                  inBundle:self.bundle
                             compatibleWithTraitCollection:nil]
                forState:UIControlStateNormal];
    [_cameraBtn setImage:[UIImage imageNamed:@"call_camera_off"
                                                  inBundle:self.bundle
                             compatibleWithTraitCollection:nil]
                forState:UIControlStateSelected];
    _cameraBtn.accessibilityIdentifier = @"op_video_mute";
  }
  return _cameraBtn;
}
- (UIButton *)hangupBtn {
  if (!_hangupBtn) {
    _hangupBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_hangupBtn setImage:[UIImage imageNamed:@"hangup"
                                                  inBundle:self.bundle
                             compatibleWithTraitCollection:nil]
                forState:UIControlStateNormal];
    _hangupBtn.accessibilityIdentifier = @"op_hangup";
  }
  return _hangupBtn;
}
- (UIButton *)speakerBtn {
  if (nil == _speakerBtn) {
    _speakerBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_speakerBtn setImage:[UIImage imageNamed:@"call_speaker_off"
                                                   inBundle:self.bundle
                              compatibleWithTraitCollection:nil]
                 forState:UIControlStateSelected];
    [_speakerBtn setImage:[UIImage imageNamed:@"call_speaker_on"
                                                   inBundle:self.bundle
                              compatibleWithTraitCollection:nil]
                 forState:UIControlStateNormal];
    _speakerBtn.accessibilityIdentifier = @"op_speaker";
  }
  return _speakerBtn;
}
- (UIButton *)mediaBtn {
  if (nil == _mediaBtn) {
    _mediaBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_mediaBtn setImage:[UIImage imageNamed:@"call_switch_audio"
                                                 inBundle:self.bundle
                            compatibleWithTraitCollection:nil]
               forState:UIControlStateNormal];
    [_mediaBtn setImage:[UIImage imageNamed:@"call_switch_video"
                                                 inBundle:self.bundle
                            compatibleWithTraitCollection:nil]
               forState:UIControlStateSelected];
    _mediaBtn.accessibilityIdentifier = @"switch_media_btn";
  }
  return _mediaBtn;
}

- (UIButton *)virtualBtn {
  if (nil == _virtualBtn) {
    _virtualBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_virtualBtn setImage:[UIImage imageNamed:@"virtual_background_off"
                                                   inBundle:self.bundle
                              compatibleWithTraitCollection:nil]
                 forState:UIControlStateNormal];
    [_virtualBtn setImage:[UIImage imageNamed:@"virtual_background_on"
                                                   inBundle:self.bundle
                              compatibleWithTraitCollection:nil]
                 forState:UIControlStateSelected];
    _virtualBtn.accessibilityIdentifier = @"virtual_btn";
  }
  return _virtualBtn;
}

- (void)changeAudioStyle {
  [self.stack removeArrangedSubview:self.cameraBtn];
  [self.cameraBtn removeFromSuperview];
  self.mediaBtn.selected = YES;
  if (self.enableVirtualBackground == YES) {
    [self.stack removeArrangedSubview:self.virtualBtn];
  }
  self.virtualBtn.hidden = YES;
}

- (void)changeVideoStyle {
  [self.stack insertArrangedSubview:self.cameraBtn atIndex:1];
  self.mediaBtn.selected = NO;
  if (self.enableVirtualBackground == YES) {
    [self.stack insertArrangedSubview:self.virtualBtn atIndex:4];
    self.virtualBtn.selected = NO;
    self.virtualBtn.hidden = NO;
  }
}

- (void)hideMediaSwitch {
  [self.stack removeArrangedSubview:self.mediaBtn];
  [self.mediaBtn removeFromSuperview];
  [self.stack removeArrangedSubview:self.cameraBtn];
  [self.cameraBtn removeFromSuperview];
}

- (void)setGroupStyle {
  [self.stack removeArrangedSubview:self.mediaBtn];
  [self.stack removeArrangedSubview:self.speakerBtn];
  [self.mediaBtn removeFromSuperview];
  [self.speakerBtn removeFromSuperview];
}

- (void)removeMediaBtn {
  [self.stack removeArrangedSubview:self.mediaBtn];
  [self.mediaBtn removeFromSuperview];
}

- (void)setEnableVirtualBackground:(BOOL)enableVirtualBackground {
  _enableVirtualBackground = enableVirtualBackground;
  if (enableVirtualBackground == YES) {
    [self.stack insertArrangedSubview:self.virtualBtn atIndex:4];
  }
}

@end
