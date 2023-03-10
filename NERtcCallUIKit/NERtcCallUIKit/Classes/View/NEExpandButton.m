// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEExpandButton.h"

@implementation NEExpandButton

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
  CGRect bounds = self.bounds;
  // 若原热区小于44x44，则放大热区，否则保持原大小不变
  CGFloat widthDelta = MAX(44.0 - bounds.size.width, 0);
  CGFloat heightDelta = MAX(44.0 - bounds.size.height, 0);
  bounds = CGRectInset(bounds, -0.5 * widthDelta, -0.5 * heightDelta);
  return CGRectContainsPoint(bounds, point);
}

@end
