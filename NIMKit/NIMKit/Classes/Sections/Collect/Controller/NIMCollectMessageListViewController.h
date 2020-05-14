//
//  NIMCollectListViewController.h
//  NIMKit
//
//  Created by 丁文超 on 2020/3/19.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMMessageCell.h"
@class NIMSession;
@class NIMKitEvent;
@class NIMMessage;

NS_ASSUME_NONNULL_BEGIN

@interface NIMCollectMessageListViewController : UIViewController<NIMMessageCellDelegate>

@property (nonatomic, readonly) UITableView *tableView;

@end

NS_ASSUME_NONNULL_END
