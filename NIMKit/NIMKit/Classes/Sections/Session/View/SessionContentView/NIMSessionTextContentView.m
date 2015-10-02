//
//  NIMSessionTextContentView.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMSessionTextContentView.h"
#import "NIMAttributedLabel+NIMKit.h"
#import "NIMMessageModel.h"

NSString *const NIMTextMessageLabelLinkData = @"NIMTextMessageLabelLinkData";

@interface NIMSessionTextContentView()<NIMAttributedLabelDelegate>

@end

@implementation NIMSessionTextContentView

-(instancetype)initSessionMessageContentView
{
    if (self = [super initSessionMessageContentView]) {
        _textLabel = [[NIMAttributedLabel alloc] initWithFrame:CGRectZero];
        _textLabel.delegate = self;
        _textLabel.numberOfLines = 0;
        _textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _textLabel.font = [UIFont systemFontOfSize:14.f];
        _textLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:_textLabel];
    }
    return self;
}

- (void)refresh:(NIMMessageModel *)data{
    [super refresh:data];
    NSString *text = self.model.message.text;
    [_textLabel nim_setText:text];
    if (!self.model.message.isOutgoingMsg) {
        self.textLabel.textColor = [UIColor blackColor];
    }else{
        self.textLabel.textColor = [UIColor whiteColor];
    }
}

- (void)layoutSubviews{
    [super layoutSubviews];
    UIEdgeInsets contentInsets = self.model.contentViewInsets;
    CGSize contentsize         = self.model.contentSize;
    CGRect labelFrame = CGRectMake(contentInsets.left, contentInsets.top, contentsize.width, contentsize.height);
    self.textLabel.frame = labelFrame;
}


#pragma mark - NIMAttributedLabelDelegate
- (void)nimAttributedLabel:(NIMAttributedLabel *)label
             clickedOnLink:(id)linkData{
    NIMKitEvent *event = [[NIMKitEvent alloc] init];
    event.eventName = NIMKitEventNameTapLabelLink;
    event.message = self.model.message;
    event.data = linkData;
    [self.delegate onCatchEvent:event];

}

@end
