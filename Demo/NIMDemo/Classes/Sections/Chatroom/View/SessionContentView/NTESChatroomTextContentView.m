//
//  NTESChatroomTextContentView.m
//  NIM
//
//  Created by chris on 16/1/13.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESChatroomTextContentView.h"
#import "M80AttributedLabel+NIMKit.h"
#import "NIMMessageModel.h"
#import "NIMGlobalMacro.h"
#import "UIView+NTES.h"

@interface NTESChatroomTextContentView()<M80AttributedLabelDelegate>

@end

@implementation NTESChatroomTextContentView

- (instancetype)initSessionMessageContentView
{
    if (self = [super initSessionMessageContentView]) {
        _textLabel = [[M80AttributedLabel alloc] initWithFrame:CGRectZero];
        _textLabel.autoDetectLinks = NO;
        _textLabel.delegate = self;
        _textLabel.numberOfLines = 0;
        _textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _textLabel.font = [UIFont systemFontOfSize:Chatroom_Message_Font_Size];
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.textColor = [UIColor blackColor];
        [self addSubview:_textLabel];
    }
    return self;
}

- (void)refresh:(NIMMessageModel *)model
{
    [super refresh:model];
    NSString *text = self.model.message.text;
    [_textLabel nim_setText:text];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    UIEdgeInsets contentInsets = self.model.contentViewInsets;
    CGFloat tableViewWidth = self.superview.width;
    CGSize contentsize         = [self.model contentSize:tableViewWidth];
    CGRect labelFrame    = CGRectMake(contentInsets.left, contentInsets.top, contentsize.width, contentsize.height);
    self.textLabel.frame = labelFrame;
}


- (UIImage *)chatBubbleImageForState:(UIControlState)state outgoing:(BOOL)outgoing{
    return nil;
}

#pragma mark - M80AttributedLabelDelegate
- (void)m80AttributedLabel:(M80AttributedLabel *)label
             clickedOnLink:(id)linkData{
    NIMKitEvent *event = [[NIMKitEvent alloc] init];
    event.eventName = NIMKitEventNameTapLabelLink;
    event.messageModel = self.model;
    event.data = linkData;
    [self.delegate onCatchEvent:event];
}


@end
