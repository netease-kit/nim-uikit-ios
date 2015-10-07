//
//  NIMSessionMessageContentView.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMSessionMessageContentView.h"
#import "NIMMessageModel.h"
#import "UIImage+NIM.h"

@implementation NIMSessionMessageContentView

- (instancetype)initSessionMessageContentView
{
    CGSize defaultBubbleSize = CGSizeMake(60, 35);
    if (self = [self initWithFrame:CGRectMake(0, 0, defaultBubbleSize.width, defaultBubbleSize.height)]) {
        [self addTarget:self action:@selector(onTouchDown:) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(onTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [self addTarget:self action:@selector(onTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
        _bubbleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,defaultBubbleSize.width,defaultBubbleSize.height)];
        _bubbleImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:_bubbleImageView];
    }
    return self;
}

- (void)refresh:(NIMMessageModel*)data{
    _model = data;
    CGSize size = [self bubbleViewSize:data];
    self.bounds = CGRectMake(0, 0, size.width, size.height);
    switch (self.bubbleType) {
        case NIMKitBubbleTypeChat:
            [_bubbleImageView setImage:[self chatBubbleImageForState:UIControlStateNormal]];
            [_bubbleImageView setHighlightedImage:[self chatBubbleImageForState:UIControlStateHighlighted]];
            break;
        case NIMKitBubbleTypeNotify:
            [_bubbleImageView setImage:[self notifyBubbleImageForState:UIControlStateNormal]];
        default:
            break;
    }
    _bubbleImageView.frame = self.bounds;
    [self setNeedsLayout];
}


- (void)layoutSubviews{
    [super layoutSubviews];
}


- (void)updateProgress:(float)progress
{
    
}

- (void)onTouchDown:(id)sender
{
    
}

- (void)onTouchUpInside:(id)sender
{
    
}

- (void)onTouchUpOutside:(id)sender{
    
}


#pragma mark - Private
- (UIImage *)chatBubbleImageForState:(UIControlState)state{
    
    if (self.model.message.isOutgoingMsg) {
        if (state == UIControlStateNormal)
        {
            UIImage *image = [UIImage nim_imageInKit:@"icon_sender_text_node_normal.png"];
            
            return [image resizableImageWithCapInsets:UIEdgeInsetsMake(18,25,17,25) resizingMode:UIImageResizingModeStretch];
            
        }else if (state == UIControlStateHighlighted)
        {
            UIImage *image = [UIImage nim_imageInKit:@"icon_sender_text_node_pressed.png"] ;
            return [image resizableImageWithCapInsets:UIEdgeInsetsMake(18,25,17,25) resizingMode:UIImageResizingModeStretch];
        }
        
    }else {
        if (state == UIControlStateNormal) {
            UIImage *image = [UIImage nim_imageInKit:@"icon_receiver_node_normal.png"];
            
            return [image resizableImageWithCapInsets:UIEdgeInsetsMake(18,25,17,25) resizingMode:UIImageResizingModeStretch];
            
        }else if (state == UIControlStateHighlighted) {
            UIImage *image = [UIImage nim_imageInKit:@"icon_receiver_node_pressed.png"] ;
            return [image resizableImageWithCapInsets:UIEdgeInsetsMake(18,25,17,25) resizingMode:UIImageResizingModeStretch];
        }
    }
    return nil;
}


- (UIImage *)notifyBubbleImageForState:(UIControlState)state
{
    return [[UIImage nim_imageInKit:@"icon_session_time_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(8,20,8,20) resizingMode:UIImageResizingModeStretch];
}

- (CGSize)bubbleViewSize:(NIMMessageModel *)model
{
    CGSize bubbleSize;
    CGSize contentSize  = model.contentSize;
    UIEdgeInsets insets = model.contentViewInsets;
    bubbleSize.width  = contentSize.width + insets.left + insets.right;
    bubbleSize.height = contentSize.height + insets.top + insets.bottom;
    return bubbleSize;
}


- (void)setHighlighted:(BOOL)highlighted{
    [super setHighlighted:highlighted];
    _bubbleImageView.highlighted = highlighted;
}

@end
