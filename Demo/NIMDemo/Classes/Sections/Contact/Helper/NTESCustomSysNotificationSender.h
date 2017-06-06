//
//  NTESCustomSysNotiSender.h
//  NIM
//
//  Created by chris on 15/5/26.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#define NTESNotifyID        @"id"
#define NTESCustomContent   @"content"
#define NTESTeamMeetingMembers   @"members"
#define NTESTeamMeetingTeamId    @"teamId"
#define NTESTeamMeetingTeamName  @"teamName"
#define NTESTeamMeetingName      @"room"

#define NTESCommandTyping   (1)
#define NTESCustom          (2)
#define NTESTeamMeetingCall (3)

@interface NTESCustomSysNotificationSender : NSObject

- (void)sendCustomContent:(NSString *)content toSession:(NIMSession *)session;

- (void)sendTypingState:(NIMSession *)session;

- (void)sendCallNotification:(NSString *)teamId
                    roomName:(NSString *)roomName
                     members:(NSArray *)members;

@end
