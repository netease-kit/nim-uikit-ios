//
//  NIMReplyedTextContentView.m
//  NIMKit
//
//  Created by He on 2020/3/25.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import "NIMReplyedTextContentView.h"
#import "M80AttributedLabel+NIMKit.h"
#import "UIView+NIM.h"
#import "NIMKit.h"

@interface NIMReplyedTextContentView ()<M80AttributedLabelDelegate>
@end

@implementation NIMReplyedTextContentView

- (instancetype)initSessionMessageContentView {
    self = [super initSessionMessageContentView];
    return self;
}

- (void)refresh:(NIMMessageModel *)data {
    [super refresh:data];
    NSString *text = [[NIMKit sharedKit] replyedContentWithMessage:data.repliedMessage];
    [self.textLabel nim_setText:text];
    
    NIMKitSetting *setting = [[NIMKit sharedKit].config repliedSetting:data.message];
    self.textLabel.textColor = setting.replyedTextColor;
    self.textLabel.font = setting.replyedFont;
    [self setNeedsLayout];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    UIEdgeInsets contentInsets = self.model.replyContentViewInsets;
    
    CGFloat tableViewWidth = self.superview.nim_width;
    CGSize contentsize = [self.model replyContentSize:tableViewWidth];
    CGRect labelFrame = CGRectMake(contentInsets.left, contentInsets.top, contentsize.width, contentsize.height);
    self.textLabel.frame = labelFrame;
}

- (M80AttributedLabel *)textLabel
{
    if (!_textLabel)
    {
        _textLabel = [[M80AttributedLabel alloc] initWithFrame:CGRectZero];
        _textLabel.delegate = self;
        _textLabel.numberOfLines = 0;
        _textLabel.autoDetectLinks = NO;
        _textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.textColor = [UIColor grayColor];
        [self addSubview:_textLabel];
    }
    
    return _textLabel;
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


- (void)onTouchUpInside:(id)sender
{
    NIMKitEvent *event = [[NIMKitEvent alloc] init];
    event.eventName = NIMKitEventNameTapRepliedContent;
    event.messageModel = self.model;
    [self.delegate onCatchEvent:event];
}

@end
