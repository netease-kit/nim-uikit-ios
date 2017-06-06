//
//  NTESMeetingUser.h
//  NIM
//
//  Created by chris on 2017/5/15.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM (NSInteger,NTESMeetingMemberState){
    NTESMeetingMemberStateConnecting,   //连接中
    NTESMeetingMemberStateTimeout,      //未连接
    NTESMeetingMemberStateConnected,    //已连接
    NTESMeetingMemberStateDisconnected, //已挂断
};

@interface NTESMeetingMember : NSObject

@property (nonatomic,copy)   NSString *userId;

@property (nonatomic,assign) NTESMeetingMemberState state;

@property (nonatomic,assign) BOOL mute;

@end
