//
//  NTESTeamMemberListViewController.h
//  NIM
//
//  Created by chris on 15/3/26.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <NIMSDK/NIMSDK.h>
#import "NIMTeamMemberListDataSource.h"

@interface NIMTeamMemberListViewController : UIViewController

- (instancetype)initWithDataSource:(id<NIMTeamMemberListDataSource>)dataSource;

@end
