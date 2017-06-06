//
//  NTESTeamMeetingMutesViewController.h
//  NIM
//
//  Created by chris on 2017/5/8.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NTESTeamMeetingMuteUser;

@protocol NTESTeamMeetingMutesDelegate <NSObject>

- (void)onTeamMembersMuteStateChange:(NSArray<NTESTeamMeetingMuteUser *> *)members;

@end



@interface NTESTeamMeetingMutesViewController : UITableViewController

@property (nonatomic,strong) NIMTeam *team;

@property (nonatomic,weak) id<NTESTeamMeetingMutesDelegate> delegate;

- (instancetype)initWithMeetingMembers:(NSArray<NTESTeamMeetingMuteUser *> *)members;

@end



@interface NTESTeamMeetingMuteUser : NSObject

@property (nonatomic,copy)   NSString *userId;

@property (nonatomic,assign) BOOL mute;

@end
