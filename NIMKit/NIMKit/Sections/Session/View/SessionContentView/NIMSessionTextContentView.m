//
//  NIMSessionTextContentView.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMSessionTextContentView.h"
#import "M80AttributedLabel+NIMKit.h"
#import "NIMMessageModel.h"
#import "NIMGlobalMacro.h"
#import "NIMKitUIConfig.h"

NSString *const NIMTextMessageLabelLinkData = @"NIMTextMessageLabelLinkData";

@interface NIMSessionTextContentView()<M80AttributedLabelDelegate>

@end

@implementation NIMSessionTextContentView

- (instancetype)initSessionMessageContentView
{
    if (self = [super initSessionMessageContentView]) {
        _textLabel = [[M80AttributedLabel alloc] initWithFrame:CGRectZero];
        _textLabel.delegate = self;
        _textLabel.numberOfLines = 0;
        _textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _textLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:_textLabel];
    }
    return self;
}

- (void)refresh:(NIMMessageModel *)data{
    [super refresh:data];
    NSString *text = self.model.message.text;
    
    NIMKitBubbleConfig *config = [[NIMKitUIConfig sharedConfig] bubbleConfig:data.message];

    self.textLabel.textColor = config.contentTextColor;
    self.textLabel.font = config.contentTextFont;
    [self.textLabel nim_setText:text];
    
    
}

- (void)layoutSubviews{
    [super layoutSubviews];
    UIEdgeInsets contentInsets = self.model.contentViewInsets;
    CGSize contentsize         = self.model.contentSize;
    CGRect labelFrame = CGRectMake(contentInsets.left, contentInsets.top, contentsize.width, contentsize.height);
    self.textLabel.frame = labelFrame;
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
