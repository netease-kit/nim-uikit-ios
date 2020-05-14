//
//  NIMMessagePinListViewController.h
//  NIM
//
//  Created by 丁文超 on 2020/3/18.
//  Copyright © 2020 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMMessageCell.h"

@class NIMSession,NIMSessionViewController,NIMMessagePinListViewController,NIMMessagePinItem,NIMMessage;

NS_ASSUME_NONNULL_BEGIN

@protocol NIMMessagePinListViewControllerDelegate <NSObject>

@optional

- (void)pinListViewController:(NIMMessagePinListViewController *)pinListVC didRemovePinItem:(NIMMessagePinItem *)item  forMessage:(NIMMessage *)message;

- (void)pinListViewController:(NIMMessagePinListViewController *)pinListVC didRequestViewMessage:(NIMMessage *)message;

@end

@interface NIMMessagePinListViewController : UIViewController<NIMMessageCellDelegate>

@property (nonatomic, readonly) UITableView *tableView;

@property (nonatomic, weak) id<NIMMessagePinListViewControllerDelegate> delegate;

- (instancetype)initWithSession:(NIMSession *)session;

@end


NS_ASSUME_NONNULL_END
