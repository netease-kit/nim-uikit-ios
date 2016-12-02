//
//  NTESNotificationCenter.h
//  NIM
//
//  Created by Xuhui on 15/3/25.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESService.h"
@class NTESCustomNotificationDB;

extern NSString *NTESCustomNotificationCountChanged;

@interface NTESNotificationCenter : NSObject

+ (instancetype)sharedCenter;
- (void)start;

@end
