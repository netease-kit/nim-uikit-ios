//
//  NIMSessionNetChatNotifyContentView.m
//  NIMKit
//
//  Created by chris on 15/5/8.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMSessionNetChatNotifyContentView.h"
#import "M80AttributedLabel+NIMKit.h"
#import "NIMMessageModel.h"
#import "NIMKitUtil.h"
#import "UIView+NIM.h"
#import "NIMKit.h"

@implementation NIMSessionNetChatNotifyContentView

-(instancetype)initSessionMessageContentView
{
    if (self = [super initSessionMessageContentView]) {
        _textLabel = [[M80AttributedLabel alloc] initWithFrame:CGRectZero];
        _textLabel.numberOfLines = 0;
        _textLabel.autoDetectLinks = NO;
        _textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _textLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:_textLabel];
    }
    return self;
}

- (void)refresh:(NIMMessageModel *)data
{
    [super refresh:data];
    NSString *text = [NIMKitUtil messageTipContent:data.message];
   
    NIMKitSetting *setting = [[NIMKit sharedKit].config setting:data.message];
    self.textLabel.textColor = setting.textColor;;
    self.textLabel.font      = setting.font;
    
    [self.textLabel nim_setText:text];
    

}

- (void)layoutSubviews{
    [super layoutSubviews];
    UIEdgeInsets contentInsets = self.model.contentViewInsets;
    CGFloat tableViewWidth = self.superview.nim_width;
    CGSize contentsize = [self.model contentSize:tableViewWidth];
    CGRect labelFrame = CGRectMake(contentInsets.left, contentInsets.top, contentsize.width, contentsize.height);
    self.textLabel.frame = labelFrame;
}


@end
