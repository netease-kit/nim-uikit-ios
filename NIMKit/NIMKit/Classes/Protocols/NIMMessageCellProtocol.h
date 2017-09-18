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

#pragma mark - 点击事件
- (BOOL)onTapCell:(NIMKitEvent *)event;

- (BOOL)onLongPressCell:(NIMMessage *)message
                 inView:(UIView *)view;

- (BOOL)onTapAvatar:(NSString *)userId;

- (BOOL)onLongPressAvatar:(NSString *)userId;

- (void)onRetryMessage:(NIMMessage *)message;



#pragma mark - 样式设置
- (BOOL)disableAudioPlayedStatusIcon:(NIMMessage *)message;

@end
