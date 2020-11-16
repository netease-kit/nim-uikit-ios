//
//  NIMMessageUtil.m
//  NIMKit
//
//  Created by Netease on 2019/10/17.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "NIMMessageUtil.h"
#import <NIMSDK/NIMSDK.h>
#import "NIMGlobalMacro.h"
#import "NIMKitUtil.h"
#import "NSDictionary+NIMKit.h"

@implementation NIMMessageUtil

+ (NSString *)messageContent:(NIMMessage*)message {
    NSString *text = @"";
    switch (message.messageType) {
        case NIMMessageTypeText:
            text = message.text;
            break;
        case NIMMessageTypeAudio:
            text = @"[语音]".nim_localized;
            break;
        case NIMMessageTypeImage:
            text = @"[图片]".nim_localized;
            break;
        case NIMMessageTypeVideo:
            text = @"[视频]".nim_localized;
            break;
        case NIMMessageTypeLocation:
            text = @"[位置]".nim_localized;
            break;
        case NIMMessageTypeNotification:{
            return [self notificationMessageContent:message];
        }
        case NIMMessageTypeFile:
            text = @"[文件]".nim_localized;
            break;
        case NIMMessageTypeTip:
            text = message.text;
            break;
        case NIMMessageTypeRtcCallRecord: {
            NIMRtcCallRecordObject *record = message.messageObject;
            return (record.callType == NIMRtcCallTypeAudio ? @"[网络通话]" : @"[视频聊天]").nim_localized;
        }
        default:
            text = @"[未知消息]".nim_localized;
    }
    return text;
}

+ (NSString *)notificationMessageContent:(NIMMessage *)message{
    NIMNotificationObject *object = message.messageObject;
    if (object.notificationType == NIMNotificationTypeNetCall) {
        NIMNetCallNotificationContent *content = (NIMNetCallNotificationContent *)object.content;
        if (content.callType == NIMNetCallTypeAudio) {
            return @"[网络通话]".nim_localized;
        }
        return @"[视频聊天]".nim_localized;
    }
    if (object.notificationType == NIMNotificationTypeTeam) {
        NIMTeam *team = [[NIMSDK sharedSDK].teamManager teamById:message.session.sessionId];
        if (team.type == NIMTeamTypeNormal) {
            return @"[讨论组信息更新]".nim_localized;
        }else{
            return @"[群信息更新]".nim_localized;
        }
    }
    
    if (object.notificationType == NIMNotificationTypeSuperTeam) {
        return @"[超大群信息更新]".nim_localized;
    }
    return @"[未知消息]".nim_localized;
}

@end
