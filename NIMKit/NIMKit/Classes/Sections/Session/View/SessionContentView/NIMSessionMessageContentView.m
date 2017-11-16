//
//  NIMSessionMessageContentView.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMSessionMessageContentView.h"
#import "NIMMessageModel.h"
#import "UIImage+NIMKit.h"
#import "UIView+NIM.h"
#import "NIMKit.h"

@interface NIMSessionMessageContentView()

@end

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

- (void)refresh:(NIMMessageModel*)data
{
    _model = data;
    [_bubbleImageView setImage:[self chatBubbleImageForState:UIControlStateNormal outgoing:data.message.isOutgoingMsg]];
    [_bubbleImageView setHighlightedImage:[self chatBubbleImageForState:UIControlStateHighlighted outgoing:data.message.isOutgoingMsg]];
    [self setNeedsLayout];
}


- (void)layoutSubviews{
    [super layoutSubviews];
    _bubbleImageView.frame = self.bounds;
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
- (UIImage *)chatBubbleImageForState:(UIControlState)state outgoing:(BOOL)outgoing
{
    
    NIMKitSetting *setting = [[NIMKit sharedKit].config setting:self.model.message];
    if (state == UIControlStateNormal)
    {
        return setting.normalBackgroundImage;
    }
    else
    {
        return setting.highLightBackgroundImage;
    }
}


- (void)setHighlighted:(BOOL)highlighted{
    [super setHighlighted:highlighted];
    _bubbleImageView.highlighted = highlighted;
}

@end
