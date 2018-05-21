//
//  NIMMessageModel.m
//  NIMKit
//
//  Created by NetEase.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMMessageModel.h"
#import "NIMKit.h"

@interface NIMMessageModel()

@property (nonatomic,strong) NSMutableDictionary *contentSizeInfo;

@end

@implementation NIMMessageModel

@synthesize contentViewInsets  = _contentViewInsets;
@synthesize bubbleViewInsets   = _bubbleViewInsets;
@synthesize shouldShowAvatar   = _shouldShowAvatar;
@synthesize shouldShowNickName = _shouldShowNickName;
@synthesize shouldShowLeft     = _shouldShowLeft;
@synthesize avatarMargin       = _avatarMargin;
@synthesize nickNameMargin     = _nickNameMargin;
@synthesize avatarSize         = _avatarSize;

- (instancetype)initWithMessage:(NIMMessage*)message
{
    if (self = [self init])
    {
        _message = message;
        _messageTime = message.timestamp;
        _contentSizeInfo = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)cleanCache
{
    [_contentSizeInfo removeAllObjects];
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

- (CGSize)contentSize:(CGFloat)width
{
    CGSize size = [self.contentSizeInfo[@(width)] CGSizeValue];
    if (CGSizeEqualToSize(size, CGSizeZero))
    {
        [self updateLayoutConfig];
        id<NIMCellLayoutConfig> layoutConfig = [[NIMKit sharedKit] layoutConfig];
        size = [layoutConfig contentSize:self cellWidth:width];
        [self.contentSizeInfo setObject:[NSValue valueWithCGSize:size] forKey:@(width)];
    }
    return size;
}


- (UIEdgeInsets)contentViewInsets{
    if (UIEdgeInsetsEqualToEdgeInsets(_contentViewInsets, UIEdgeInsetsZero))
    {
        id<NIMCellLayoutConfig> layoutConfig = [[NIMKit sharedKit] layoutConfig];
        _contentViewInsets = [layoutConfig contentViewInsets:self];
    }
    return _contentViewInsets;
}

- (UIEdgeInsets)bubbleViewInsets{
    if (UIEdgeInsetsEqualToEdgeInsets(_bubbleViewInsets, UIEdgeInsetsZero))
    {
        id<NIMCellLayoutConfig> layoutConfig = [[NIMKit sharedKit] layoutConfig];
        _bubbleViewInsets = [layoutConfig cellInsets:self];
    }
    return _bubbleViewInsets;
}

- (void)updateLayoutConfig
{
    id<NIMCellLayoutConfig> layoutConfig = [[NIMKit sharedKit] layoutConfig];
    
    _shouldShowAvatar       = [layoutConfig shouldShowAvatar:self];
    _shouldShowNickName     = [layoutConfig shouldShowNickName:self];
    _shouldShowLeft         = [layoutConfig shouldShowLeft:self];
    _avatarMargin           = [layoutConfig avatarMargin:self];
    _nickNameMargin         = [layoutConfig nickNameMargin:self];
    _avatarSize             = [layoutConfig avatarSize:self];
}


- (BOOL)shouldShowReadLabel
{
    if (self.message.session.sessionType == NIMSessionTypeP2P)
    {
        return _shouldShowReadLabel && self.message.isRemoteRead;
    }
    else
    {
        return _shouldShowReadLabel;
    }
    
}

@end
