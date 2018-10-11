//
//  NIMAdvancedTeamCardViewController.h
//  NIM
//
//  Created by chris on 15/3/25.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <NIMSDK/NIMSDK.h>

#define kNIMAdvancedTeamCardConfigTopKey @"kNIMAdvancedTeamCardConfigTopKey"

@protocol NIMAdvancedTeamCardVCProtocol <NSObject>
@optional
- (void)NIMAdvancedTeamCardVCDidSetTop:(BOOL)isTop;
@end

@interface NIMAdvancedTeamCardViewController : UIViewController

@property (nonatomic, weak) id <NIMAdvancedTeamCardVCProtocol> delegate;

- (instancetype)initWithTeam:(NIMTeam *)team;

- (instancetype)initWithTeam:(NIMTeam *)team
                    exConfig:(NSDictionary *)exConfig;

@end
