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
@protocol NIMTeamCardHeaderCellDelegate;



@interface NIMTeamCardHeaderCell : UICollectionViewCell

@property (nonatomic,strong) NIMAvatarImageView *imageView;

@property (nonatomic,strong) UIImageView *roleImageView;

@property (nonatomic,strong) UILabel *titleLabel;

@property (nonatomic,strong) UIButton *removeBtn;

@property (nonatomic,weak) id<NIMTeamCardHeaderCellDelegate>delegate;

@property (nonatomic,readonly) id<NIMKitCardHeaderData> data;

- (void)refreshData:(id<NIMKitCardHeaderData>)data;

@end


@protocol NIMTeamCardHeaderCellDelegate <NSObject>

- (void)cellDidSelected:(NIMTeamCardHeaderCell*)cell;


@optional
- (void)cellShouldBeRemoved:(NIMTeamCardHeaderCell*)cell;

@end