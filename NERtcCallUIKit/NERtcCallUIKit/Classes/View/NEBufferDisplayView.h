//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <AVKit/AVKit.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEBufferDisplayView : UIView

- (AVSampleBufferDisplayLayer *)getLayer;

@end

NS_ASSUME_NONNULL_END
