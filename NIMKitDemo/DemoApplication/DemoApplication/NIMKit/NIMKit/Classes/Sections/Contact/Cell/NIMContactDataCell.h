//
//  NTESContactInfoCell.h
//  NIM
//
//  Created by chris on 15/2/26.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMContactDefines.h"

@protocol NIMContactDataCellDelegate <NSObject>

- (void)onPressAvatar:(NSString *)memberId;

@end

@class NIMAvatarImageView;

@interface NIMContactDataCell : UITableViewCell

@property (nonatomic,strong) NIMAvatarImageView * avatarImageView;

@property (nonatomic,strong) UIButton *accessoryBtn;

@property (nonatomic,weak) id<NIMContactDataCellDelegate> delegate;

- (void)refreshUser:(id<NIMGroupMemberProtocol>)member;

- (void)refreshTeam:(id<NIMGroupMemberProtocol>)member;

@end
