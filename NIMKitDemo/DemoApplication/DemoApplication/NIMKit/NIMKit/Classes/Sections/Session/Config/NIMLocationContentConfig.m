//
//  NIMLocationContentConfig.m
//  NIMKit
//
//  Created by amao on 9/15/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import "NIMLocationContentConfig.h"

@implementation NIMLocationContentConfig
- (CGSize)contentSize:(CGFloat)cellWidth
{
    return CGSizeMake(110.f, 105.f);
}

- (NSString *)cellContent
{
    return @"NIMSessionLocationContentView";
}

- (UIEdgeInsets)contentViewInsets
{
    return self.message.isOutgoingMsg ? UIEdgeInsetsMake(3,3,3,8) : UIEdgeInsetsMake(3,8,3,3);
}
@end
