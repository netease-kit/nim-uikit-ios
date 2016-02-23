//
//  NIMUnsupportContentConfig.m
//  NIMKit
//
//  Created by amao on 9/15/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import "NIMUnsupportContentConfig.h"

@implementation NIMUnsupportContentConfig
+ (instancetype)sharedConfig
{
    static NIMUnsupportContentConfig *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NIMUnsupportContentConfig alloc] init];
    });
    return instance;
}

- (CGSize)contentSize:(CGFloat)cellWidth
{
    return CGSizeMake(100.f, 40.f);
}

- (NSString *)cellContent
{
    return @"NIMSessionUnknowContentView";
}

- (UIEdgeInsets)contentViewInsets
{
    return self.message.isOutgoingMsg ?
    UIEdgeInsetsMake(11.f,11.f,9.f,15.f) : UIEdgeInsetsMake(11.f, 15.f, 9.f, 9.f);
}

@end
