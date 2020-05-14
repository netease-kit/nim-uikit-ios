//
//  NIMReplyedTextContentView.h
//  NIMKit
//
//  Created by He on 2020/3/25.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import "NIMSessionMessageContentView.h"

@class M80AttributedLabel;
NS_ASSUME_NONNULL_BEGIN

@interface NIMReplyedTextContentView : NIMSessionMessageContentView

@property (nonatomic, strong) M80AttributedLabel *textLabel;

@end

NS_ASSUME_NONNULL_END
