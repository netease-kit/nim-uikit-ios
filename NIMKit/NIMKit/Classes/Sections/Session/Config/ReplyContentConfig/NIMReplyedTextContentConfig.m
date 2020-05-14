//
//  NIMReplyedTextContentConfig.m
//  NIMKit
//
//  Created by He on 2020/3/25.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import "NIMReplyedTextContentConfig.h"
#import "M80AttributedLabel+NIMKit.h"
#import "NIMKit.h"

@interface NIMReplyedTextContentConfig ()

@property (nonatomic,strong) M80AttributedLabel *label;

@end

@implementation NIMReplyedTextContentConfig


- (CGSize)contentSize:(CGFloat)cellWidth message:(NIMMessage *)message
{
    NSString *text = [[NIMKit sharedKit] replyedContentWithMessage:message];
    self.label.font = [[NIMKit sharedKit].config repliedSetting:message].replyedFont;
    
    [self.label nim_setText:text];
    CGFloat msgBubbleMaxWidth    = (cellWidth - 130);
    CGFloat bubbleLeftToContent  = 14;
    CGFloat contentRightToBubble = 14;
    CGFloat msgContentMaxWidth = (msgBubbleMaxWidth - contentRightToBubble - bubbleLeftToContent);
    
    CGSize sizeToFit = [self.label sizeThatFits:CGSizeMake(msgContentMaxWidth, CGFLOAT_MAX)];
    return CGSizeMake(ceilf(sizeToFit.width)+2, ceilf(sizeToFit.height)+2);
}

- (UIEdgeInsets)contentViewInsets:(NIMMessage *)message
{    
    return [[NIMKit sharedKit].config repliedSetting:message].contentInsets;
}

- (NSString *)cellContent:(NIMMessage *)message
{
    return @"NIMReplyedTextContentView";
}

#pragma mark - Private
- (M80AttributedLabel *)label
{
    if (_label) {
        return _label;
    }
    _label = [[M80AttributedLabel alloc] initWithFrame:CGRectZero];
    return _label;
}


@end
