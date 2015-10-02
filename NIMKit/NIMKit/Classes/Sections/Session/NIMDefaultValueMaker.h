//
//  NIMDefaultValueMaker.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMCellConfig.h"
#import "NIMCellLayoutDefaultConfig.h"
@interface NIMDefaultValueMaker : NSObject

@property (nonatomic,readonly) NIMCellLayoutDefaultConfig *cellLayoutDefaultConfig;

+ (instancetype)sharedMaker;

- (CGFloat)maxNotificationTipPadding;

@end
