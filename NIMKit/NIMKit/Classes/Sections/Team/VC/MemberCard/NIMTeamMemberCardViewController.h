//
//  TeamMemberCardViewController.h
//  NIM
//
//  Created by Xuhui on 15/3/19.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMTeamCardMemberItem.h"
#import "NIMTeamMemberListDataSource.h"

@protocol NIMTeamMemberCardActionDelegate <NSObject>
@optional

- (void)onTeamMemberMuted:(NIMTeamCardMemberItem *)member mute:(BOOL)mute;
- (void)onTeamMemberKicked:(NIMTeamCardMemberItem *)member;

@end

@interface NIMTeamMemberCardViewController : UIViewController

@property (nonatomic, strong) id<NIMTeamMemberCardActionDelegate> delegate;

- (instancetype)initWithMember:(NSString *)userId
                    dataSource:(id <NIMTeamMemberListDataSource>) dataSource;

@end
