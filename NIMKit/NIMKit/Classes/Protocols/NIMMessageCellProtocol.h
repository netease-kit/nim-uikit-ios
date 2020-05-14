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
@class NIMQuickComment;
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

- (BOOL)onTapAvatar:(NIMMessage *)message;

- (BOOL)onLongPressAvatar:(NIMMessage *)message;

- (BOOL)onPressReadLabel:(NIMMessage *)message;

- (void)onRetryMessage:(NIMMessage *)message;

- (void)onSelectedMessage:(BOOL)selected message:(NIMMessage *)message;

- (void)onClickReplyButton:(NIMMessage *)message;

- (void)onClickEmoticon:(NIMMessage *)message
                comment:(NIMQuickComment *)comment
               selected:(BOOL)isSelected;

@end
