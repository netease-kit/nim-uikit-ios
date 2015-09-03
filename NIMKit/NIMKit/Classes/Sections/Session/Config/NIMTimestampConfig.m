//
//  NIMTimestampConfig.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMTimestampConfig.h"

@implementation NIMTimestampConfig

- (NSString *)cellContent:(NIMMessageModel *)model{
    return @"time";
}

- (CGSize)contentSize:(NIMMessageModel *)model cellWidth:(CGFloat)width{
    return CGSizeZero;
}
@end
