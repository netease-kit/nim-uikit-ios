//
//  TeamCardHeaderCell.h
//  NIM
//
//  Created by chris on 15/3/7.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMCardDataSourceProtocol.h"
@class NIMAvatarImageView;
@protocol TeamCardHeaderCellDelegate;



@interface NIMTeamCardHeaderCell : UICollectionViewCell

@property (nonatomic,strong) NIMAvatarImageView *imageView;

@property (nonatomic,strong) UIImageView *roleImageView;

@property (nonatomic,strong) UILabel *titleLabel;

@property (nonatomic,strong) UIButton *removeBtn;

@property (nonatomic,weak) id<TeamCardHeaderCellDelegate>delegate;

@property (nonatomic,readonly) id<NIMKitCardHeaderData> data;

- (void)refreshData:(id<NIMKitCardHeaderData>)data;

@end


@protocol TeamCardHeaderCellDelegate <NSObject>

- (void)cellDidSelected:(NIMTeamCardHeaderCell*)cell;


@optional
- (void)cellShouldBeRemoved:(NIMTeamCardHeaderCell*)cell;

@end