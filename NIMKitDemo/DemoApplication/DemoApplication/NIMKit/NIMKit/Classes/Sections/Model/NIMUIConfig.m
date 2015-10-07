//
//  NIMUIConfig.m
//  NIMKit
//
//  Created by amao on 8/19/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import "NIMUIConfig.h"

@implementation NIMUIConfig
+ (CGFloat)topInputViewHeight
{
    return 46.0;
}

+ (CGFloat)bottomInputViewHeight
{
    return 216.0;
}

+ (NSInteger)messageLimit
{
    return 20;
}

+ (NSTimeInterval)messageTimeInterval
{
    return 5 * 60.0;
}

@end
