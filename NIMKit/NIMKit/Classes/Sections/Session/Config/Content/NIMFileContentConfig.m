//
//  NIMFileContentConfig.m
//  NIMKit
//
//  Created by amao on 9/15/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import "NIMFileContentConfig.h"
#import "NIMKit.h"

@implementation NIMFileContentConfig

- (CGSize)contentSize:(CGFloat)cellWidth message:(NIMMessage *)message
{
    return CGSizeMake(220, 110);
}

- (NSString *)cellContent:(NIMMessage *)message
{
    return @"NIMSessionFileTransContentView";
}

- (UIEdgeInsets)contentViewInsets:(NIMMessage *)message
{
    return [[NIMKit sharedKit].config setting:message].contentInsets;
}



@end
