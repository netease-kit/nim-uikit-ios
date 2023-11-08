// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NECallUIStateController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NECalledViewController : NECallUIStateController

@property(nonatomic, strong) UILabel *connectingLabel;

- (void)checkCallePreview;

@end

NS_ASSUME_NONNULL_END
