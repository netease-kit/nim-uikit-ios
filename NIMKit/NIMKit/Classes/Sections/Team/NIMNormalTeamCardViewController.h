//
//  NIMNormalTeamCardViewController.h
//  NIM
//
//  Created by chris on 15/3/10.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <NIMSDK/NIMSDK.h>

#define kNIMNormalTeamCardConfigTopKey @"kNormalTeamCardConfigTopKey"

@protocol NIMNormalTeamCardVCProtocol <NSObject>
@optional
- (void)NIMNormalTeamCardVCDidSetTop:(BOOL)isTop;
@end

@interface NIMNormalTeamCardViewController : UIViewController

@property (nonatomic, weak) id <NIMNormalTeamCardVCProtocol> delegate;

- (instancetype)initWithTeam:(NIMTeam *)team;

- (instancetype)initWithTeam:(NIMTeam *)team exConfig:(NSDictionary *)exConfig;

@end
