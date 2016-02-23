//
//  NIMTextContentConfig.m
//  NIMKit
//
//  Created by amao on 9/15/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import "NIMTextContentConfig.h"
#import "NIMAttributedLabel+NIMKit.h"
@interface NIMTextContentConfig()

@property (nonatomic,strong) NIMAttributedLabel *label;

@end


@implementation NIMTextContentConfig

- (CGSize)contentSize:(CGFloat)cellWidth
{
    NSString *text = self.message.text;
    [self.label nim_setText:text];
    
    CGFloat msgBubbleMaxWidth    = (cellWidth - 130);
    CGFloat bubbleLeftToContent  = 14;
    CGFloat contentRightToBubble = 14;
    CGFloat msgContentMaxWidth = (msgBubbleMaxWidth - contentRightToBubble - bubbleLeftToContent);
    return [self.label sizeThatFits:CGSizeMake(msgContentMaxWidth, CGFLOAT_MAX)];
}

- (NSString *)cellContent
{
    return @"NIMSessionTextContentView";
}

- (UIEdgeInsets)contentViewInsets
{
    return self.message.isOutgoingMsg ? UIEdgeInsetsMake(11,11,9,15) : UIEdgeInsetsMake(11,15,9,9);
}


- (NIMAttributedLabel *)label
{
    if (_label) {
        return _label;
    }
    _label = [[NIMAttributedLabel alloc] initWithFrame:CGRectZero];
    _label.font = [UIFont systemFontOfSize:NIMKit_Message_Font_Size];
    return _label;
}

@end
