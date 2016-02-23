//
//  NIMAudioContentConfig.m
//  NIMKit
//
//  Created by amao on 9/15/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import "NIMAudioContentConfig.h"

@implementation NIMAudioContentConfig
- (CGSize)contentSize:(CGFloat)cellWidth
{
        //使用公式 长度 = (最长－最小)*(2/pi)*artan(时间/10)+最小，在10秒时变化逐渐变缓，随着时间增加 无限趋向于最大值
    NIMAudioObject *audioContent = (NIMAudioObject*)[self.message messageObject];
    CGFloat value  = 2*atan((audioContent.duration/1000.0-1)/10.0)/M_PI;
    NSInteger audioContentMinWidth = (cellWidth - 280);
    NSInteger audioContentMaxWidth = (cellWidth - 170);
    NSInteger audioContentHeight   = 30;
    return CGSizeMake((audioContentMaxWidth - audioContentMinWidth)* value + audioContentMinWidth, audioContentHeight);
}

- (NSString *)cellContent
{
    return @"NIMSessionAudioContentView";
}

- (UIEdgeInsets)contentViewInsets
{
    return self.message.isOutgoingMsg ? UIEdgeInsetsMake(8,12,9,14) : UIEdgeInsetsMake(8,13,9,12);
}
@end
