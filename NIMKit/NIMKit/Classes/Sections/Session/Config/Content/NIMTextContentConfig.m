//
//  NIMTextContentConfig.m
//  NIMKit
//
//  Created by amao on 9/15/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import "NIMTextContentConfig.h"
#import "M80AttributedLabel+NIMKit.h"
#import "NIMKit.h"

@interface NIMTextContentConfig()

@property (nonatomic,strong) M80AttributedLabel *label;

@end


@implementation NIMTextContentConfig

- (CGSize)contentSize:(CGFloat)cellWidth message:(NIMMessage *)message
{
    NSString *text = message.text;
    self.label.font = [[NIMKit sharedKit].config setting:message].font;
    
    [self.label nim_setText:text];    
    CGFloat msgBubbleMaxWidth    = (cellWidth - 130);
    CGFloat bubbleLeftToContent  = 14;
    CGFloat contentRightToBubble = 14;
    CGFloat msgContentMaxWidth = (msgBubbleMaxWidth - contentRightToBubble - bubbleLeftToContent);
    
    return [self.label sizeThatFits:CGSizeMake(msgContentMaxWidth, CGFLOAT_MAX)];
}

- (NSString *)cellContent:(NIMMessage *)message
{
    return @"NIMSessionTextContentView";
}

- (UIEdgeInsets)contentViewInsets:(NIMMessage *)message
{
    return [[NIMKit sharedKit].config setting:message].contentInsets;
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
