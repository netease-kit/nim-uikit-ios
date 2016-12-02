//
//  NTESChatroomMaker.m
//  NIM
//
//  Created by chris on 16/1/19.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESChatroomMaker.h"
#import "NSDictionary+NTESJson.h"
#import "NTESSessionUtil.h"

@implementation NTESChatroomMaker

+ (nullable NIMChatroom *)makeChatroom:(nonnull NSDictionary *)dict
{
    BOOL status = [dict jsonInteger:@"status"];
    if (status)
    {
        NIMChatroom *chatroom = [[NIMChatroom alloc] init];
        chatroom.roomId  = [dict jsonString:@"roomid"];
        chatroom.name    = [dict jsonString:@"name"];
        chatroom.creator = [dict jsonString:@"creator"];
        chatroom.announcement = [dict jsonString:@"announcement"];
        chatroom.ext     = [dict jsonString:@"ext"];
        chatroom.onlineUserCount = [dict jsonInteger:@"onlineusercount"];
        return chatroom;
    }
    else
    {
        return nil;
    }
}

@end