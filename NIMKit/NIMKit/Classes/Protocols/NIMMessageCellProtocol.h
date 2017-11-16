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

#pragma mark - cell 样式更改

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)disableAudioPlayedStatusIcon:(NIMMessage *)message;

#pragma mark - 点击事件
- (BOOL)onTapCell:(NIMKitEvent *)event;

- (BOOL)onLongPressCell:(NIMMessage *)message
                 inView:(UIView *)view;

- (BOOL)onTapAvatar:(NSString *)userId;

- (BOOL)onLongPressAvatar:(NSString *)userId;

- (void)onRetryMessage:(NIMMessage *)message;


@end
