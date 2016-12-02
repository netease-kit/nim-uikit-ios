//
//  NTESChatroomManager.m
//  NIM
//
//  Created by chris on 16/1/15.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESChatroomManager.h"
#import "NSDictionary+NTESJson.h"
#import "NTESChatroomMaker.h"

@interface NTESChatroomManager()<NIMChatManagerDelegate>

@property (nonatomic,strong) NSMutableDictionary *myInfo;

@end

@implementation NTESChatroomManager


- (instancetype)init
{
    self = [super init];
    if (self) {
        _myInfo = [[NSMutableDictionary alloc] init];
        [[NIMSDK sharedSDK].chatManager addDelegate:self];
    }
    return self;
}

- (void)dealloc
{
    [[NIMSDK sharedSDK].chatManager removeDelegate:self];
}


- (NIMChatroomMember *)myInfo:(NSString *)roomId
{
    NIMChatroomMember *member = _myInfo[roomId];
    return member;
}

- (void)cacheMyInfo:(NIMChatroomMember *)info roomId:(NSString *)roomId
{
    [_myInfo setObject:info forKey:roomId];
}

#pragma mark - NIMChatManagerDelegate

- (void)onRecvMessages:(NSArray *)messages
{
    for (NIMMessage *message in messages) {
        if (message.session.sessionType == NIMSessionTypeChatroom
                 && message.messageType == NIMMessageTypeNotification)
        {
            NIMNotificationObject *object = message.messageObject;
            if (![object.content isKindOfClass:[NIMUnsupportedNotificationContent class]]) {
                [self dealMessage:message];
            }
        }
    }
}


- (void)dealMessage:(NIMMessage *)message
{
    NIMNotificationObject *object = message.messageObject;
    NIMChatroomNotificationContent *content = (NIMChatroomNotificationContent *)object.content;
    BOOL containsMe = NO;
    for (NIMChatroomNotificationMember *member in content.targets) {
        if ([member.userId isEqualToString:[[NIMSDK sharedSDK].loginManager currentAccount]]) {
            containsMe = YES;
            break;
        }
    }
    if (containsMe) {
        NIMChatroomMember *member = self.myInfo[message.session.sessionId];
        switch (content.eventType) {
            case NIMChatroomEventTypeAddManager:
                member.type = NIMChatroomMemberTypeManager;
                break;
            case NIMChatroomEventTypeRemoveManager:
            case NIMChatroomEventTypeAddCommon:
                member.type = NIMChatroomMemberTypeNormal;
                break;
            case NIMChatroomEventTypeAddMute:
                member.type = NIMChatroomMemberTypeLimit;
                member.isMuted = YES;
                break;
            case NIMChatroomEventTypeRemoveCommon:
                member.type = NIMChatroomMemberTypeGuest;
                break;
            case NIMChatroomEventTypeRemoveMute:
                member.type = NIMChatroomMemberTypeGuest;
                member.isMuted = NO;
                break;
            default:
                break;
        }
    }
}
@end
