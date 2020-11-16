//
//  NIMRtcCallRecordCntentConfig.m
//  NIMKit
//
//  Created by Wenchao Ding on 2020/11/7.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import "NIMRtcCallRecordContentConfig.h"
#import "M80AttributedLabel+NIMKit.h"
#import "NIMKit.h"
#import "NIMKitUtil.h"

@implementation NIMRtcCallRecordContentConfig

- (CGSize)contentSize:(CGFloat)cellWidth message:(NIMMessage *)message
{
    NSString *text = [NIMKitUtil messageTipContent:message];
    UIFont *font = [[NIMKit sharedKit].config setting:message].font;;
    CGFloat msgBubbleMaxWidth    = (cellWidth - 130);
    CGFloat bubbleLeftToContent  = 14;
    CGFloat contentRightToBubble = 14;
    CGFloat msgContentMaxWidth = (msgBubbleMaxWidth - contentRightToBubble - bubbleLeftToContent);
    
    CGSize contentSize = [text boundingRectWithSize:CGSizeMake(msgContentMaxWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: font} context:nil].size;
    return contentSize;
}

- (NSString *)cellContent:(NIMMessage *)message
{
    return @"NIMSessionRtcCallRecordContentView";
}

- (UIEdgeInsets)contentViewInsets:(NIMMessage *)message
{
    return [[NIMKit sharedKit].config setting:message].contentInsets;
}

@end
