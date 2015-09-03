//
//  NIMUtil.h
//  NIMKit
//
//  Created by chris on 15/8/10.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NIMKitUtil : NSObject

+ (NSString *)showNick:(NSString*)uid inSession:(NIMSession*)session;

+ (NSString *)showTime:(NSTimeInterval) msglastTime showDetail:(BOOL)showDetail;

+ (NSString *)formatedMessage:(NIMMessage *)message;

@end
