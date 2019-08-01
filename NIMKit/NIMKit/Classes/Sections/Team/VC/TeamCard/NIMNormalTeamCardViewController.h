//
//  NIMNormalTeamCardViewController.h
//  NIM
//
//  Created by chris on 15/3/10.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMTeamCardViewController.h"
#import <NIMSDK/NIMSDK.h>

@interface NIMNormalTeamCardViewController : NIMTeamCardViewController

- (instancetype)initWithTeam:(NIMTeam *)team
                     session:(NIMSession *)session
                      option:(NIMTeamCardViewControllerOption *)option;

@end
