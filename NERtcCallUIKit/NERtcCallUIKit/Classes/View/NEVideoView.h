// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEVideoView : UIView
@property(strong, nonatomic) NSString *userID;
@property(strong, nonatomic) UIView *videoView;
@property(strong, nonatomic) UILabel *titleLabel;
@property(strong, nonatomic) UIView *maskView;
@property(strong, nonatomic) UIImageView *imageView;

@end

NS_ASSUME_NONNULL_END
