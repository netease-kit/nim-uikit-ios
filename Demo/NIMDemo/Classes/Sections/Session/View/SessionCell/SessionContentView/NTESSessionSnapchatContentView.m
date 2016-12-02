//
//  NTESSessionSnapchatContentView.m
//  NIM
//
//  Created by amao on 7/2/15.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import "NTESSessionSnapchatContentView.h"
#import "NTESSnapchatAttachment.h"
#import "NTESSessionUtil.h"
#import "UIView+NTES.h"

NSString *const NIMDemoEventNameOpenSnapPicture  = @"NIMDemoEventNameOpenSnapPicture";
NSString *const NIMDemoEventNameCloseSnapPicture = @"NIMDemoEventNameCloseSnapPicture";


@interface NTESSessionSnapchatContentView()

@property (nonatomic,strong) UIImageView *imageView;

@property (nonatomic,strong) UILabel *label;

@property (nonatomic,strong) UILongPressGestureRecognizer *longpressGesture;

@end

@implementation NTESSessionSnapchatContentView


- (instancetype)initSessionMessageContentView{
    self = [super initSessionMessageContentView];
    if (self) {
        _longpressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressDown:)];
        [self addGestureRecognizer:_longpressGesture];
        _imageView  = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self addSubview:_imageView];
        self.bubbleImageView.hidden = YES;//图片背景自带气泡。。
        
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.font = [UIFont systemFontOfSize:13.f];
        _label.textColor = [UIColor grayColor];
        _label.text = @"按住查看";
        [_label sizeToFit];
        [self addSubview:_label];
    }
    return self;
}

- (void)refresh:(NIMMessageModel *)model{
    [super refresh:model];
    NIMCustomObject * customObject     = (NIMCustomObject*)model.message.messageObject;
    NTESSnapchatAttachment *attachment = (NTESSnapchatAttachment *)customObject.attachment;
    self.imageView.image               = attachment.showCoverImage;
    self.label.hidden                  = attachment.isFired;
    self.longpressGesture.enabled      = !attachment.isFired;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    NIMCustomObject * customObject = (NIMCustomObject*)self.model.message.messageObject;
    NTESSnapchatAttachment *attachment = (NTESSnapchatAttachment *)customObject.attachment;
    UIEdgeInsets contentInsets = self.model.contentViewInsets;
    UIImage *showCoverImage = attachment.showCoverImage;
    CGRect imageViewFrame = CGRectMake(contentInsets.left, contentInsets.top, showCoverImage.size.width, showCoverImage.size.height);
    self.imageView.frame  = imageViewFrame;

    CGFloat customSnapMessageImageRightToText = 5.f;
    CGFloat customSnapMessageTextBottom       = 20.f;
    self.label.left = self.model.message.isOutgoingMsg ? self.imageView.left - customSnapMessageImageRightToText - self.label.width : self.imageView.right + customSnapMessageImageRightToText;
    self.label.bottom = self.imageView.bottom - customSnapMessageTextBottom ;
    
}



- (void)onLongPressDown:(UILongPressGestureRecognizer *)recognizer
{
    NIMMessage *message = self.model.message;
    if (!message.isReceivedMsg && message.deliveryState != NIMMessageDeliveryStateDeliveried) {
        return;
    }
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    recognizer.enabled = NO;
    [self goOpen];
}


- (void)onTouchUpInside:(id)sender{
    if (self.presentedView) {
        [self goClose];
    }
}

- (void)onTouchUpOutside:(id)sender{
    if (self.presentedView) {
        [self goClose];
    }
}

- (void)goOpen{
    if ([self.delegate respondsToSelector:@selector(onCatchEvent:)]) {
        NIMKitEvent *event = [[NIMKitEvent alloc] init];
        event.eventName = NIMDemoEventNameOpenSnapPicture;
        event.messageModel = self.model;
        event.data = self;
        [self.delegate onCatchEvent:event];
    }
}

- (void)goClose{
    if ([self.delegate respondsToSelector:@selector(onCatchEvent:)]) {
        NIMKitEvent *event = [[NIMKitEvent alloc] init];
        event.eventName = NIMDemoEventNameCloseSnapPicture;
        event.messageModel = self.model;
        event.data = self;
        [self.delegate onCatchEvent:event];
    }
}


@end
