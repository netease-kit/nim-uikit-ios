//
//  NIMTextContentConfig.m
//  NIMKit
//
//  Created by amao on 9/15/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import "NIMTextContentConfig.h"
#import "NIMAttributedLabel+NIMKit.h"

@implementation NIMTextContentConfig
- (CGSize)contentSize:(CGFloat)cellWidth
{
    NIMAttributedLabel *label = [[NIMAttributedLabel alloc] initWithFrame:CGRectZero];
    label.font = [UIFont systemFontOfSize:NIMKit_Message_Font_Size];
    NSString *text = self.message.text;
    [label nim_setText:text];
    
    CGFloat msgBubbleMaxWidth    = (cellWidth - 130);
    CGFloat bubbleLeftToContent  = 14;
    CGFloat contentRightToBubble = 14;
    CGFloat msgContentMaxWidth = (msgBubbleMaxWidth - contentRightToBubble - bubbleLeftToContent);
    return [label sizeThatFits:CGSizeMake(msgContentMaxWidth, CGFLOAT_MAX)];
}

- (NSString *)cellContent
{
    return @"NIMSessionTextContentView";
}

- (UIEdgeInsets)contentViewInsets
{
    return self.message.isOutgoingMsg ? UIEdgeInsetsMake(11,11,9,15) : UIEdgeInsetsMake(11,15,9,9);
}
@end
