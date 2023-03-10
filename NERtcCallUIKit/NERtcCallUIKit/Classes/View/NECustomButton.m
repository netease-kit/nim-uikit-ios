// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NECustomButton.h"

@implementation NECustomButton
- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self addSubview:self.imageView];
    [self addSubview:self.titleLabel];
    [self addSubview:self.maskBtn];

    [NSLayoutConstraint activateConstraints:@[
      [self.imageView.topAnchor constraintEqualToAnchor:self.topAnchor],
      [self.imageView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
      [self.imageView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
      [self.imageView.widthAnchor constraintEqualToConstant:75],
      [self.imageView.heightAnchor constraintEqualToConstant:75],
    ]];

    [NSLayoutConstraint activateConstraints:@[
      [self.titleLabel.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:-40],
      [self.titleLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:40],
      [self.titleLabel.topAnchor constraintEqualToAnchor:self.imageView.bottomAnchor constant:8],
      [self.titleLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0]
    ]];

    [NSLayoutConstraint activateConstraints:@[
      [self.maskBtn.leftAnchor constraintEqualToAnchor:self.leftAnchor],
      [self.maskBtn.rightAnchor constraintEqualToAnchor:self.rightAnchor],
      [self.maskBtn.topAnchor constraintEqualToAnchor:self.topAnchor],
      [self.maskBtn.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];

    self.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return self;
}

- (UIImageView *)imageView {
  if (!_imageView) {
    _imageView = [[UIImageView alloc] init];
    _imageView.userInteractionEnabled = NO;
    _imageView.translatesAutoresizingMaskIntoConstraints = NO;
    _imageView.contentMode = UIViewContentModeCenter;
  }
  return _imageView;
}
- (UILabel *)titleLabel {
  if (!_titleLabel) {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:14];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _titleLabel;
}

- (UIButton *)maskBtn {
  if (!_maskBtn) {
    _maskBtn = [[UIButton alloc] init];
    _maskBtn.backgroundColor = [UIColor clearColor];
    _maskBtn.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _maskBtn;
}
@end
