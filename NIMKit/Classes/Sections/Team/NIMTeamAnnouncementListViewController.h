//
//  TeamAnnouncementListViewController.h
//  NIM
//
//  Created by Xuhui on 15/3/31.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMSDK.h"

@interface NIMTeamAnnouncementListViewController : UIViewController

@property (nonatomic, strong) NIMTeam *team;
@property (nonatomic, assign) BOOL canCreateAnnouncement;

@end
