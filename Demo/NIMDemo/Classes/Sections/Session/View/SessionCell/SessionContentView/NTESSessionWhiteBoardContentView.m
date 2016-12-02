//
//  NTESSessionWhiteBoardContentView.m
//  NIM
//
//  Created by chris on 15/8/3.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESSessionWhiteBoardContentView.h"
#import "NTESSessionUtil.h"
#import "UIView+NTES.h"
#import "M80AttributedLabel.h"
#import "NIMKitUtil.h"
#import "NTESWhiteboardAttachment.h"

@interface NTESSessionWhiteBoardContentView()

@property (nonatomic,strong) UIImageView *imageView;

@end

@implementation NTESSessionWhiteBoardContentView

-(instancetype)initSessionMessageContentView
{
    if (self = [super initSessionMessageContentView]) {
        //
        _textLabel = [[M80AttributedLabel alloc] initWithFrame:CGRectZero];
        _textLabel.numberOfLines = 0;
        _textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _textLabel.font = [UIFont systemFontOfSize:14.f];
        _textLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:_textLabel];
        
        _imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_whiteboard_session_msg"]];
        [self addSubview:_imageView];
    }
    return self;
}

- (void)refresh:(NIMMessageModel *)data{
    [super refresh:data];
    NIMCustomObject *object = (NIMCustomObject *)data.message.messageObject;
    NTESWhiteboardAttachment *attach = (NTESWhiteboardAttachment *)object.attachment;
    NSString *text = attach.formatedMessage;
    
    [_textLabel setText:text];
    if (!data.message.isOutgoingMsg) {
        _textLabel.textColor = [UIColor blackColor];
    }else{
        _textLabel.textColor = [UIColor whiteColor];
    }
}

- (void)layoutSubviews{
    [super layoutSubviews];
    UIEdgeInsets contentInsets = self.model.contentViewInsets;
    CGSize contentSize = self.model.contentSize;
    self.imageView.left = contentInsets.left;
    self.imageView.centerY = self.height * .5f;
    CGFloat customWhiteBorardMessageImageRightToText = 5.f;
    CGRect labelFrame = CGRectMake(self.imageView.right + customWhiteBorardMessageImageRightToText, contentInsets.top, contentSize.width, contentSize.height);
    self.textLabel.frame = labelFrame;
}
@end
