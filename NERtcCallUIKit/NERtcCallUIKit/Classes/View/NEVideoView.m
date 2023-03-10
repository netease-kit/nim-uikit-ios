// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEVideoView.h"

@implementation NEVideoView
- (instancetype)init {
  self = [super init];
  if (self) {
    [self addSubview:self.videoView];
    [NSLayoutConstraint activateConstraints:@[
      [self.videoView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
      [self.videoView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
      [self.videoView.topAnchor constraintEqualToAnchor:self.topAnchor],
      [self.videoView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
    [self addSubview:self.maskView];
    [NSLayoutConstraint activateConstraints:@[
      [self.maskView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
      [self.maskView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
      [self.maskView.topAnchor constraintEqualToAnchor:self.topAnchor],
      [self.maskView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
    [self addSubview:self.titleLabel];
    [NSLayoutConstraint activateConstraints:@[
      [self.titleLabel.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:10],
      [self.titleLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-10],
      [self.titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:10],
      [self.titleLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-10]
    ]];
    [self addSubview:self.imageView];
    [NSLayoutConstraint activateConstraints:@[
      [self.imageView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
      [self.imageView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
      [self.imageView.topAnchor constraintEqualToAnchor:self.topAnchor],
      [self.imageView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
  }
  return self;
}
- (UIView *)videoView {
  if (!_videoView) {
    _videoView = [[UIView alloc] init];
    _videoView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _videoView;
}
- (UIView *)maskView {
  if (!_maskView) {
    _maskView = [[UIView alloc] init];
    _maskView.backgroundColor = [UIColor darkGrayColor];
    _maskView.hidden = YES;
    _maskView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _maskView;
}

- (UILabel *)titleLabel {
  if (!_titleLabel) {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.font = [UIFont systemFontOfSize:20];
    _titleLabel.numberOfLines = 0;
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _titleLabel;
}

- (UIImageView *)imageView {
  if (_imageView == nil) {
    _imageView = [[UIImageView alloc] init];
    _imageView.userInteractionEnabled = YES;
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _imageView;
}
@end
