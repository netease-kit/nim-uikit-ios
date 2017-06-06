//
//  NTESSessionListCell.h
//  NIMDemo
//
//  Created by chris on 15/2/10.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
@class NIMAvatarImageView;
@class NIMRecentSession;
@class NIMBadgeView;

@interface NIMSessionListCell : UITableViewCell

@property (nonatomic,strong) NIMAvatarImageView *avatarImageView;

@property (nonatomic,strong) UILabel *nameLabel;

@property (nonatomic,strong) UILabel *messageLabel;

@property (nonatomic,strong) UILabel *timeLabel;

@property (nonatomic,strong) NIMBadgeView *badgeView;

- (void)refresh:(NIMRecentSession*)recent;

@end
