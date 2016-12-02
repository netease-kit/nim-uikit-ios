//
//  NTESSystemNotificationCell.h
//  NIM
//
//  Created by amao on 3/17/15.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger, NotificationHandleType) {
    NotificationHandleTypePending = 0,
    NotificationHandleTypeOk,
    NotificationHandleTypeNo,
    NotificationHandleTypeOutOfDate
};

@class NIMSystemNotification;

@protocol NIMSystemNotificationCellDelegate <NSObject>
- (void)onAccept:(NIMSystemNotification *)notification;
- (void)onRefuse:(NIMSystemNotification *)notification;
@end


@interface NTESSystemNotificationCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *handleInfoLabel;
@property (strong, nonatomic) IBOutlet UIView *acceptButton;
@property (strong, nonatomic) IBOutlet UIView *refuseButton;
@property (weak, nonatomic) id<NIMSystemNotificationCellDelegate> actionDelegate;
- (void)update:(NIMSystemNotification *)notification;
@end
