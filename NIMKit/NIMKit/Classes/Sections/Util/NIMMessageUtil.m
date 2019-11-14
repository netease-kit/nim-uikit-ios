//
//  NIMMessageUtil.m
//  NIMKit
//
//  Created by Netease on 2019/10/17.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "NIMMessageUtil.h"
#import <NIMSDK/NIMSDK.h>

@implementation NIMMessageUtil

+ (NSString *)messageContent:(NIMMessage*)message {
    NSString *text = @"";
    switch (message.messageType) {
        case NIMMessageTypeText:
            text = message.text;
            break;
        case NIMMessageTypeAudio:
            text = @"[语音]";
            break;
        case NIMMessageTypeImage:
            text = @"[图片]";
            break;
        case NIMMessageTypeVideo:
            text = @"[视频]";
            break;
        case NIMMessageTypeLocation:
            text = @"[位置]";
            break;
        case NIMMessageTypeNotification:{
            return [self notificationMessageContent:message];
        }
        case NIMMessageTypeFile:
            text = @"[文件]";
            break;
        case NIMMessageTypeTip:
            text = message.text;
            break;
        default:
            text = @"[未知消息]";
    }
    return text;
}

+ (NSString *)notificationMessageContent:(NIMMessage *)message{
    NIMNotificationObject *object = message.messageObject;
    if (object.notificationType == NIMNotificationTypeNetCall) {
        NIMNetCallNotificationContent *content = (NIMNetCallNotificationContent *)object.content;
        if (content.callType == NIMNetCallTypeAudio) {
            return @"[网络通话]";
        }
        return @"[视频聊天]";
    }
    if (object.notificationType == NIMNotificationTypeTeam) {
        NIMTeam *team = [[NIMSDK sharedSDK].teamManager teamById:message.session.sessionId];
        if (team.type == NIMTeamTypeNormal) {
            return @"[讨论组信息更新]";
        }else{
            return @"[群信息更新]";
        }
    }
    
    if (object.notificationType == NIMNotificationTypeSuperTeam) {
        return @"[超大群信息更新]";
    }
    return @"[未知消息]";
}

@end
