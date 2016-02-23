//
//  NTESSessionTipCell.h
//  NIMDemo
//
//  Created by ght on 15-1-28.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMMessageCellProtocol.h"
@class NIMTimestampModel;

@interface NIMSessionTimestampCell : UITableViewCell

@property (strong, nonatomic) UIImageView *timeBGView;

@property (strong, nonatomic) UILabel *timeLabel;

- (void)refreshData:(NIMTimestampModel *)data;

@end
