//
//  NTESCustomNotificationObject.m
//  NIM
//
//  Created by chris on 15/5/28.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESCustomNotificationObject.h"

@implementation NTESCustomNotificationObject

- (instancetype)initWithNotification:(NIMCustomSystemNotification *)notification{
    self = [super init];
    if (self) {
        _sender    = notification.sender;
        _receiver  = notification.receiver;
        _timestamp = notification.timestamp;
        _content   = notification.content;
        _needBadge = notification.setting.shouldBeCounted;
    }
    return self;
}

@end
