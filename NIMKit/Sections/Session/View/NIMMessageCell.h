//
//  NIMMessageCell.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMMessageCellProtocol.h"
#import "NIMTimestampModel.h"

@class NIMSessionMessageContentView;
@class NIMAvatarImageView;
@class NIMBadgeView;

@interface NIMMessageCell : UITableViewCell

@property (nonatomic, strong) NIMAvatarImageView *headImageView;
@property (nonatomic, strong) UILabel *nameLabel;                                 //姓名（群显示 个人不显示）
@property (nonatomic, strong) NIMSessionMessageContentView *bubbleView;           //内容区域
@property (nonatomic, strong) UIActivityIndicatorView *traningActivityIndicator;  //发送loading
@property (nonatomic, strong) UIButton *retryButton;                              //重试
@property (nonatomic, strong) NIMBadgeView *audioPlayedIcon;                      //语音未读红点
@property (nonatomic, strong) UILabel *readLabel;                                 //已读

@property (nonatomic, weak)   id<NIMMessageCellDelegate> delegate;

- (void)refreshData:(NIMMessageModel *)data;

@end
