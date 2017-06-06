//
//  NTESTeamMeetingCalleeInfo.h
//  NIM
//
//  Created by chris on 2017/5/5.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NTESTeamMeetingCalleeInfo : NSObject

@property (nonatomic,copy) NSArray *members;

@property (nonatomic,copy) NSString *teamId;

@property (nonatomic,copy) NSString *teamName;

@property (nonatomic,copy) NSString *meetingName;

@end
