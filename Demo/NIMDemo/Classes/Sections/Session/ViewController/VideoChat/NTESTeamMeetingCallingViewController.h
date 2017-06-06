//
//  NTESTeamMeetingCallingViewController.h
//  NIM
//
//  Created by chris on 2017/5/3.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NTESTeamMeetingCalleeInfo;

@interface NTESTeamMeetingCallingViewController : UIViewController

@property (nonatomic,strong) IBOutlet UILabel *nameLabel;

- (instancetype)initWithCalleeInfo:(NTESTeamMeetingCalleeInfo *)info;

@end
