//
//  NIMMessageModel.m
//  NIMKit
//
//  Created by NetEase.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMMessageModel.h"
#import "NIMDefaultValueMaker.h"

@implementation NIMMessageModel

@synthesize contentSize        = _contentSize;
@synthesize contentViewInsets  = _contentViewInsets;
@synthesize bubbleViewInsets   = _bubbleViewInsets;
@synthesize shouldShowAvatar   = _shouldShowAvatar;
@synthesize shouldShowNickName = _shouldShowNickName;

- (instancetype)initWithMessage:(NIMMessage*)message
{
    if (self = [self init])
    {
        _message = message;
    }
    return self;
}

- (void)cleanCache
{
    _contentSize = CGSizeZero;
    _contentViewInsets = UIEdgeInsetsZero;
    _bubbleViewInsets = UIEdgeInsetsZero;
}

- (NSString*)description{
    return self.message.text;
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[NIMMessageModel class]])
    {
        return NO;
    }
    else
    {
        NIMMessageModel *model = object;
        return [self.message isEqual:model.message];
    }
}

- (void)calculateContent:(CGFloat)width{
    if (CGSizeEqualToSize(_contentSize, CGSizeZero))
    {
        _contentSize = [self.layoutConfig contentSize:self cellWidth:width];
    }
}


- (UIEdgeInsets)contentViewInsets{
    if (UIEdgeInsetsEqualToEdgeInsets(_contentViewInsets, UIEdgeInsetsZero))
    {
        if ([self.layoutConfig respondsToSelector:@selector(contentViewInsets:)])
        {
            _contentViewInsets = [self.layoutConfig contentViewInsets:self];
        }
        else
        {
            _contentViewInsets = [[NIMDefaultValueMaker sharedMaker].cellLayoutDefaultConfig contentViewInsets:self];
        }
    }
    return _contentViewInsets;
}

- (UIEdgeInsets)bubbleViewInsets{
    if (UIEdgeInsetsEqualToEdgeInsets(_bubbleViewInsets, UIEdgeInsetsZero))
    {
        if ([self.layoutConfig respondsToSelector:@selector(cellInsets:)])
        {
            _bubbleViewInsets = [self.layoutConfig cellInsets:self];
        }
        else
        {
            _bubbleViewInsets = [[NIMDefaultValueMaker sharedMaker].cellLayoutDefaultConfig cellInsets:self];
        }
    }
    return _bubbleViewInsets;
}

- (void)setLayoutConfig:(id<NIMCellLayoutConfig>)layoutConfig{
    _layoutConfig = layoutConfig;
    if ([layoutConfig respondsToSelector:@selector(shouldShowAvatar:)])
    {
        _shouldShowAvatar = [layoutConfig shouldShowAvatar:self];
    }
    else
    {
        _shouldShowAvatar = [[NIMDefaultValueMaker sharedMaker].cellLayoutDefaultConfig shouldShowAvatar:self];
    }
    
    if ([layoutConfig respondsToSelector:@selector(shouldShowNickName:)])
    {
        _shouldShowNickName = [layoutConfig shouldShowNickName:self];
    }
    else
    {
        _shouldShowNickName = [[NIMDefaultValueMaker sharedMaker].cellLayoutDefaultConfig shouldShowNickName:self];
    }
}

@end
