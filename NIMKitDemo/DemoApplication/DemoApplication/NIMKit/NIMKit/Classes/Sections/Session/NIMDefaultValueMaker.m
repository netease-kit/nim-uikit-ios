//
//  NIMDefaultValueMaker.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMDefaultValueMaker.h"
#import "NIMAttributedLabel+NIMKit.h"
#import "NIMKitUtil.h"
#import "UIImage+NIM.h"

@implementation NIMDefaultValueMaker

+ (instancetype)sharedMaker{
    static NIMDefaultValueMaker *maker;
    if (!maker) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            maker = [[NIMDefaultValueMaker alloc] init];
        });
    }
    return maker;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _cellLayoutDefaultConfig = [[NIMCellLayoutDefaultConfig alloc] init];
    }
    return self;
}

- (CGFloat)maxNotificationTipPadding{
    return 20.f;
}


@end
