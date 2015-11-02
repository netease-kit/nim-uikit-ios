//
//  TeamAnnouncementListCell.h
//  NIM
//
//  Created by Xuhui on 15/3/31.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NIMTeamAnnouncementListCell : UITableViewCell

- (void)refreshData:(NSDictionary *)data team:(NIMTeam *)team;

@end
