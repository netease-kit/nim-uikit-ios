//
//  AVAsset+NIMKit.h
//  NIMKit
//
//  Created by Genning on 2020/9/25.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAsset (NIMKit)

- (AVMutableVideoComposition *)nim_videoComposition;

@end

NS_ASSUME_NONNULL_END
