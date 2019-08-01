//
//  NIMSuperTeamCardViewController.h
//  NIMKit
//
//  Created by Netease on 2019/6/10.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "NIMTeamCardViewController.h"
#import <NIMSDK/NIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface NIMSuperTeamCardViewController : NIMTeamCardViewController

- (instancetype)initWithTeam:(NIMTeam *)team
                     session:(NIMSession *)session
                      option:(NIMTeamCardViewControllerOption *)option;

@end

NS_ASSUME_NONNULL_END
