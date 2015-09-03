//
//  NIMMessageCellProtocol.h
//  NIMKit
//
//  Created by NetEase.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMCellConfig.h"


@class NIMMessageModel;
@class NIMMessage;
@class NIMKitEvent;
@protocol NIMMessageCellDelegate <NSObject>

@optional

- (void)onTapCell:(NIMKitEvent *)event;

- (void)onLongPressCell:(NIMMessage *)message
                 inView:(UIView *)view;

- (void)onRetryMessage:(NIMMessage *)message;

- (void)onTapAvatar:(NSString *)userId;

- (void)onTapLinkData:(id)linkData;

@end
