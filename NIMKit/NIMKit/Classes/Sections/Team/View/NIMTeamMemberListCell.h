//
//  NIMTeamMemberListCell.h
//  NIM
//
//  Created by chris on 15/3/26.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <NIMSDK/NIMSDK.h>
#import "NIMKit.h"

@protocol NIMTeamMemberListCellActionDelegate <NSObject>

- (void)didSelectAddOpeartor;

@end


@interface NIMTeamMemberListCell : UITableViewCell


@property(nonatomic, assign) BOOL disableInvite;

@property(nonatomic, assign) NSInteger maxShowMemberCount;

@property(nonatomic, strong) NSMutableArray <NIMKitInfo *> *infos;

@property(nonatomic, weak) id<NIMTeamMemberListCellActionDelegate>delegate;

@end
