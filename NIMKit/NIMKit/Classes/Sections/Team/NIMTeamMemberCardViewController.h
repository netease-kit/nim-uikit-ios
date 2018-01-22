//
//  TeamMemberCardViewController.h
//  NIM
//
//  Created by Xuhui on 15/3/19.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMCardMemberItem.h"

@protocol NIMTeamMemberCardActionDelegate <NSObject>
@optional

- (void)onTeamMemberKicked:(NIMTeamCardMemberItem *)member;
- (void)onTeamMemberInfoChaneged:(NIMTeamCardMemberItem *)member;

@end

@interface NIMTeamMemberCardViewController : UIViewController

@property (nonatomic, strong) id<NIMTeamMemberCardActionDelegate> delegate;
@property (nonatomic, strong) NIMTeamCardMemberItem *member;
@property (nonatomic, strong) NIMTeamCardMemberItem *viewer;

- (instancetype)initWithUserId:(NSString *)userId team:(NSString *)teamId;

@end
