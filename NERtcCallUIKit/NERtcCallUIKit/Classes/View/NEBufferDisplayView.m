//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBufferDisplayView.h"

@implementation NEBufferDisplayView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+ (Class)layerClass {
  return AVSampleBufferDisplayLayer.class;
}

- (AVSampleBufferDisplayLayer *)getLayer {
  return (AVSampleBufferDisplayLayer *)self.layer;
}

@end
