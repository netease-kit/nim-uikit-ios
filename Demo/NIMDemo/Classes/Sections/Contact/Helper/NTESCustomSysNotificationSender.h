//
//  NTESCustomSysNotiSender.h
//  NIM
//
//  Created by chris on 15/5/26.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#define NTESNotifyID        @"id"
#define NTESCustomContent  @"content"

#define NTESCommandTyping  (1)
#define NTESCustom         (2)


@interface NTESCustomSysNotificationSender : NSObject

- (void)sendCustomContent:(NSString *)content toSession:(NIMSession *)session;

- (void)sendTypingState:(NIMSession *)session;

@end
