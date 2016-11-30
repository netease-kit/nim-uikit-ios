//
//  NIMUtil.m
//  NIMKit
//
//  Created by chris on 15/8/10.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMKitUtil.h"
#import "NIMKit.h"

@implementation NIMKitUtil

+ (NSString *)genFilenameWithExt:(NSString *)ext
{
    CFUUIDRef uuid = CFUUIDCreate(nil);
    NSString *uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(nil, uuid);
    CFRelease(uuid);
    NSString *uuidStr = [[uuidString stringByReplacingOccurrencesOfString:@"-" withString:@""] lowercaseString];
    NSString *name = [NSString stringWithFormat:@"%@",uuidStr];
    return [ext length] ? [NSString stringWithFormat:@"%@.%@",name,ext]:name;
}

+ (NSString *)showNick:(NSString*)uid inMessage:(NIMMessage*)message
{
    if (!uid.length) {
        return nil;
    }
    
    return [[NIMKit sharedKit] infoByUser:uid
                              withMessage:message].showName;
}

+ (NSString *)showNick:(NSString*)uid inSession:(NIMSession*)session{
    if (!uid.length) {
        return nil;
    }
    return [[NIMKit sharedKit] infoByUser:uid
                                inSession:session].showName;
}


+ (NSString*)showTime:(NSTimeInterval) msglastTime showDetail:(BOOL)showDetail
{
    //今天的时间
    NSDate * nowDate = [NSDate date];
    NSDate * msgDate = [NSDate dateWithTimeIntervalSince1970:msglastTime];
    NSString *result = nil;
    NSCalendarUnit components = (NSCalendarUnit)(NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitWeekday|NSCalendarUnitHour | NSCalendarUnitMinute);
    NSDateComponents *nowDateComponents = [[NSCalendar currentCalendar] components:components fromDate:nowDate];
    NSDateComponents *msgDateComponents = [[NSCalendar currentCalendar] components:components fromDate:msgDate];
    
    NSInteger hour = msgDateComponents.hour;
    double OnedayTimeIntervalValue = 24*60*60;  //一天的秒数

    result = [NIMKitUtil getPeriodOfTime:hour withMinute:msgDateComponents.minute];
    if (hour > 12)
    {
        hour = hour - 12;
    }
    if(nowDateComponents.day == msgDateComponents.day) //同一天,显示时间
    {
        result = [[NSString alloc] initWithFormat:@"%@ %zd:%02d",result,hour,(int)msgDateComponents.minute];
    }
    else if(nowDateComponents.day == (msgDateComponents.day+1))//昨天
    {
        result = showDetail?  [[NSString alloc] initWithFormat:@"昨天%@ %zd:%02d",result,hour,(int)msgDateComponents.minute] : @"昨天";
    }
    else if(nowDateComponents.day == (msgDateComponents.day+2)) //前天
    {
        result = showDetail? [[NSString alloc] initWithFormat:@"前天%@ %zd:%02d",result,hour,(int)msgDateComponents.minute] : @"前天";
    }
    else if([nowDate timeIntervalSinceDate:msgDate] < 7 * OnedayTimeIntervalValue)//一周内
    {
        NSString *weekDay = [NIMKitUtil weekdayStr:msgDateComponents.weekday];
        result = showDetail? [weekDay stringByAppendingFormat:@"%@ %zd:%02d",result,hour,(int)msgDateComponents.minute] : weekDay;
    }
    else//显示日期
    {
        NSString *day = [NSString stringWithFormat:@"%zd-%zd-%zd", msgDateComponents.year, msgDateComponents.month, msgDateComponents.day];
        result = showDetail? [day stringByAppendingFormat:@"%@ %zd:%02d",result,hour,(int)msgDateComponents.minute]:day;
    }
    return result;
}

#pragma mark - Private

+ (NSString *)getPeriodOfTime:(NSInteger)time withMinute:(NSInteger)minute
{
    NSInteger totalMin = time *60 + minute;
    NSString *showPeriodOfTime = @"";
    if (totalMin > 0 && totalMin <= 5 * 60)
    {
        showPeriodOfTime = @"凌晨";
    }
    else if (totalMin > 5 * 60 && totalMin < 12 * 60)
    {
        showPeriodOfTime = @"上午";
    }
    else if (totalMin >= 12 * 60 && totalMin <= 18 * 60)
    {
        showPeriodOfTime = @"下午";
    }
    else if ((totalMin > 18 * 60 && totalMin <= (23 * 60 + 59)) || totalMin == 0)
    {
        showPeriodOfTime = @"晚上";
    }
    return showPeriodOfTime;
}

+(NSString*)weekdayStr:(NSInteger)dayOfWeek
{
    static NSDictionary *daysOfWeekDict = nil;
    daysOfWeekDict = @{@(1):@"星期日",
                       @(2):@"星期一",
                       @(3):@"星期二",
                       @(4):@"星期三",
                       @(5):@"星期四",
                       @(6):@"星期五",
                       @(7):@"星期六",};
    return [daysOfWeekDict objectForKey:@(dayOfWeek)];
}


+ (NSString *)messageTipContent:(NIMMessage *)message{
    
    NSString *text = nil;
    
    if (text == nil) {
        switch (message.messageType) {
            case NIMMessageTypeNotification:
                text =  [NIMKitUtil notificationMessage:message];
                break;
            case NIMMessageTypeTip:
                text = message.text;
                break;
            default:
                break;
        }
    }
    return text;
}


+ (NSString *)notificationMessage:(NIMMessage *)message{
    NIMNotificationObject *object = message.messageObject;
    switch (object.notificationType) {
        case NIMNotificationTypeTeam:{
            return [NIMKitUtil teamNotificationFormatedMessage:message];
        }
        case NIMNotificationTypeNetCall:{
            return [NIMKitUtil netcallNotificationFormatedMessage:message];
        }
        case NIMNotificationTypeChatroom:{
            return [NIMKitUtil chatroomNotificationFormatedMessage:message];
        }
        default:
            return @"";
    }
}


+ (NSString*)teamNotificationFormatedMessage:(NIMMessage *)message{
    NSString *formatedMessage = @"";
    NIMNotificationObject *object = message.messageObject;
    if (object.notificationType == NIMNotificationTypeTeam)
    {
        NIMTeamNotificationContent *content = (NIMTeamNotificationContent*)object.content;
        NSString *source = [NIMKitUtil teamNotificationSourceName:message];
        NSArray *targets = [NIMKitUtil teamNotificationTargetNames:message];
        NSString *targetText = [targets count] > 1 ? [targets componentsJoinedByString:@","] : [targets firstObject];
        NSString *teamName = [NIMKitUtil teamNotificationTeamShowName:message];
        
        switch (content.operationType) {
            case NIMTeamOperationTypeInvite:{
                NSString *str = [NSString stringWithFormat:@"%@邀请%@",source,targets.firstObject];
                if (targets.count>1) {
                    str = [str stringByAppendingFormat:@"等%zd人",targets.count];
                }
                str = [str stringByAppendingFormat:@"进入了%@",teamName];
                formatedMessage = str;
            }
                break;
            case NIMTeamOperationTypeDismiss:
                formatedMessage = [NSString stringWithFormat:@"%@解散了%@",source,teamName];
                break;
            case NIMTeamOperationTypeKick:{
                NSString *str = [NSString stringWithFormat:@"%@将%@",source,targets.firstObject];
                if (targets.count>1) {
                    str = [str stringByAppendingFormat:@"等%zd人",targets.count];
                }
                str = [str stringByAppendingFormat:@"移出了%@",teamName];
                formatedMessage = str;
            }
                break;
            case NIMTeamOperationTypeUpdate:
            {
                id attachment = [content attachment];
                if ([attachment isKindOfClass:[NIMUpdateTeamInfoAttachment class]]) {
                    NIMUpdateTeamInfoAttachment *teamAttachment = (NIMUpdateTeamInfoAttachment *)attachment;
                    formatedMessage = [NSString stringWithFormat:@"%@更新了%@信息",source,teamName];
                    //如果只是单个项目项被修改则显示具体的修改项
                    if ([teamAttachment.values count] == 1) {
                        NIMTeamUpdateTag tag = [[[teamAttachment.values allKeys] firstObject] integerValue];
                        switch (tag) {
                            case NIMTeamUpdateTagName:
                                formatedMessage = [NSString stringWithFormat:@"%@更新了%@名称",source,teamName];
                                break;
                            case NIMTeamUpdateTagIntro:
                                formatedMessage = [NSString stringWithFormat:@"%@更新了%@介绍",source,teamName];
                                break;
                            case NIMTeamUpdateTagAnouncement:
                                formatedMessage = [NSString stringWithFormat:@"%@更新了%@公告",source,teamName];
                                break;
                            case NIMTeamUpdateTagJoinMode:
                                formatedMessage = [NSString stringWithFormat:@"%@更新了%@验证方式",source,teamName];
                                break;
                            case NIMTeamUpdateTagAvatar:
                                formatedMessage = [NSString stringWithFormat:@"%@更新了%@头像",source,teamName];
                                break;
                            case NIMTeamUpdateTagInviteMode:
                                formatedMessage = [NSString stringWithFormat:@"%@更新了邀请他人权限",source];
                                break;
                            case NIMTeamUpdateTagBeInviteMode:
                                formatedMessage = [NSString stringWithFormat:@"%@更新了被邀请人身份验证权限",source];
                                break;
                            case NIMTeamUpdateTagUpdateInfoMode:
                                formatedMessage = [NSString stringWithFormat:@"%@更新了群资料修改权限",source];
                                break;
                            case NIMTeamUpdateTagMuteMode:{
                                NIMTeam *team = [[NIMSDK sharedSDK].teamManager teamById:message.session.sessionId];
                                BOOL inAllMuteMode = [team inAllMuteMode];
                                formatedMessage = inAllMuteMode? [NSString stringWithFormat:@"%@设置了群全体禁言",source]: [NSString stringWithFormat:@"%@取消了全体禁言",source];
                                break;
                            }
                            default:
                                break;
                                
                        }
                    }
                }
                if (formatedMessage == nil){
                    formatedMessage = [NSString stringWithFormat:@"%@更新了%@信息",source,teamName];
                }
            }
                break;
            case NIMTeamOperationTypeLeave:
                formatedMessage = [NSString stringWithFormat:@"%@离开了%@",source,teamName];
                break;
            case NIMTeamOperationTypeApplyPass:{
                if ([source isEqualToString:targetText]) {
                    //说明是以不需要验证的方式进入
                    formatedMessage = [NSString stringWithFormat:@"%@进入了%@",source,teamName];
                }else{
                    formatedMessage = [NSString stringWithFormat:@"%@通过了%@的申请",source,targetText];
                }
            }
                break;
            case NIMTeamOperationTypeTransferOwner:
                formatedMessage = [NSString stringWithFormat:@"%@转移了群主身份给%@",source,targetText];
                break;
            case NIMTeamOperationTypeAddManager:
                formatedMessage = [NSString stringWithFormat:@"%@被添加为群管理员",targetText];
                break;
            case NIMTeamOperationTypeRemoveManager:
                formatedMessage = [NSString stringWithFormat:@"%@被撤销了群管理员身份",targetText];
                break;
            case NIMTeamOperationTypeAcceptInvitation:
                formatedMessage = [NSString stringWithFormat:@"%@接受%@的邀请进群",source,targetText];
                break;
            case NIMTeamOperationTypeMute:{
                id attachment = [content attachment];
                if ([attachment isKindOfClass:[NIMMuteTeamMemberAttachment class]])
                {
                    BOOL mute = [(NIMMuteTeamMemberAttachment *)attachment flag];
                    NSString *muteStr = mute? @"禁言" : @"解除禁言";
                    NSString *str = [targets componentsJoinedByString:@","];
                    formatedMessage = [NSString stringWithFormat:@"%@被%@%@",str,source,muteStr];
                }
            }
                break;
            default:
                break;
        }
        
    }
    if (!formatedMessage.length) {
        formatedMessage = [NSString stringWithFormat:@"未知系统消息"];
    }
    return formatedMessage;
}


+ (NSString *)netcallNotificationFormatedMessage:(NIMMessage *)message{
    NIMNotificationObject *object = message.messageObject;
    NIMNetCallNotificationContent *content = (NIMNetCallNotificationContent *)object.content;
    NSString *text = @"";
    NSString *currentAccount = [[NIMSDK sharedSDK].loginManager currentAccount];
    switch (content.eventType) {
        case NIMNetCallEventTypeMiss:{
            text = @"未接听";
            break;
        }
        case NIMNetCallEventTypeBill:{
            text =  ([object.message.from isEqualToString:currentAccount])? @"通话拨打时长 " : @"通话接听时长 ";
            NSTimeInterval duration = content.duration;
            NSString *durationDesc = [NSString stringWithFormat:@"%02d:%02d",(int)duration/60,(int)duration%60];
            text = [text stringByAppendingString:durationDesc];
            break;
        }
        case NIMNetCallEventTypeReject:{
            text = ([object.message.from isEqualToString:currentAccount])? @"对方正忙" : @"已拒绝";
            break;
        }
        case NIMNetCallEventTypeNoResponse:{
            text = @"未接通，已取消";
            break;
        }
        default:
            break;
    }
    return text;
}


+ (NSString *)chatroomNotificationFormatedMessage:(NIMMessage *)message{
    NIMNotificationObject *object = message.messageObject;
    NIMChatroomNotificationContent *content = (NIMChatroomNotificationContent *)object.content;
    NSMutableArray *targetNicks = [[NSMutableArray alloc] init];
    for (NIMChatroomNotificationMember *memebr in content.targets) {
        if ([memebr.userId isEqualToString:[[NIMSDK sharedSDK].loginManager currentAccount]]) {
           [targetNicks addObject:@"你"];
        }else{
           [targetNicks addObject:memebr.nick];
        }

    }
    NSString *targetText =[targetNicks componentsJoinedByString:@","];
    switch (content.eventType) {
        case NIMChatroomEventTypeEnter:
        {
            return [NSString stringWithFormat:@"欢迎%@进入直播间",targetText];
        }
        case NIMChatroomEventTypeAddBlack:
        {
            return [NSString stringWithFormat:@"%@被管理员拉入黑名单",targetText];
        }
        case NIMChatroomEventTypeRemoveBlack:
        {
            return [NSString stringWithFormat:@"%@被管理员解除拉黑",targetText];
        }
        case NIMChatroomEventTypeAddMute:
        {
            if (content.targets.count == 1 && [[content.targets.firstObject userId] isEqualToString:[[NIMSDK sharedSDK].loginManager currentAccount]])
            {
                return @"你已被禁言";
            }
            else
            {
                return [NSString stringWithFormat:@"%@被管理员禁言",targetText];
            }
        }
        case NIMChatroomEventTypeRemoveMute:
        {
            return [NSString stringWithFormat:@"%@被管理员解除禁言",targetText];
        }
        case NIMChatroomEventTypeAddManager:
        {
            return [NSString stringWithFormat:@"%@被任命管理员身份",targetText];
        }
        case NIMChatroomEventTypeRemoveManager:
        {
            return [NSString stringWithFormat:@"%@被解除管理员身份",targetText];
        }
        case NIMChatroomEventTypeRemoveCommon:
        {
            return [NSString stringWithFormat:@"%@被解除直播室成员身份",targetText];
        }
        case NIMChatroomEventTypeAddCommon:
        {
            return [NSString stringWithFormat:@"%@被添加为直播室成员身份",targetText];
        }
        case NIMChatroomEventTypeInfoUpdated:
        {
            return [NSString stringWithFormat:@"直播间公告已更新"];
        }
        case NIMChatroomEventTypeKicked:
        {
            return [NSString stringWithFormat:@"%@被管理员移出直播间",targetText];
        }
        case NIMChatroomEventTypeExit:
        {
            return [NSString stringWithFormat:@"%@离开了直播间",targetText];
        }
        case NIMChatroomEventTypeClosed:
        {
            return [NSString stringWithFormat:@"直播间已关闭"];
        }
        case NIMChatroomEventTypeAddMuteTemporarily:
        {
            if (content.targets.count == 1 && [[content.targets.firstObject userId] isEqualToString:[[NIMSDK sharedSDK].loginManager currentAccount]])
            {
                return @"你已被临时禁言";
            }
            else
            {
                return [NSString stringWithFormat:@"%@被管理员禁言",targetText];
            }
        }
        case NIMChatroomEventTypeRemoveMuteTemporarily:
        {
            return [NSString stringWithFormat:@"%@被管理员解除临时禁言",targetText];
        }
        case NIMChatroomEventTypeMemberUpdateInfo:
        {
            return [NSString stringWithFormat:@"%@更新了自己的个人信息",targetText];
        }
        case NIMChatroomEventTypeRoomMuted:
        {
            return @"全体禁言，管理员可发言";
        }
        case NIMChatroomEventTypeRoomUnMuted:
        {
            return @"解除全体禁言";
        }
        default:
            break;
    }
    return @"";
}


#pragma mark - Private
+ (NSString *)teamNotificationSourceName:(NIMMessage *)message{
    NSString *source;
    NIMNotificationObject *object = message.messageObject;
    NIMTeamNotificationContent *content = (NIMTeamNotificationContent*)object.content;
    NSString *currentAccount = [[NIMSDK sharedSDK].loginManager currentAccount];
    if ([content.sourceID isEqualToString:currentAccount]) {
        source = @"你";
    }else{
        source = [NIMKitUtil showNick:content.sourceID inSession:message.session];
    }
    return source;
}

+ (NSArray *)teamNotificationTargetNames:(NIMMessage *)message{
    NSMutableArray *targets = [[NSMutableArray alloc] init];
    NIMNotificationObject *object = message.messageObject;
    NIMTeamNotificationContent *content = (NIMTeamNotificationContent*)object.content;
    NSString *currentAccount = [[NIMSDK sharedSDK].loginManager currentAccount];
    for (NSString *item in content.targetIDs) {
        if ([item isEqualToString:currentAccount]) {
            [targets addObject:@"你"];
        }else{
            NSString *targetShowName = [NIMKitUtil showNick:item inSession:message.session];
            [targets addObject:targetShowName];
        }
    }
    return targets;
}


+ (NSString *)teamNotificationTeamShowName:(NIMMessage *)message{
    NIMTeam *team = [[NIMSDK sharedSDK].teamManager teamById:message.session.sessionId];
    NSString *teamName = team.type == NIMTeamTypeNormal ? @"讨论组" : @"群";
    return teamName;
}

+ (BOOL)canEditTeamInfo:(NIMTeamMember *)member
{
    NIMTeam *team = [[NIMSDK sharedSDK].teamManager teamById:member.teamId];
    if (team.updateInfoMode == NIMTeamUpdateInfoModeManager)
    {
        return member.type == NIMTeamMemberTypeOwner || member.type == NIMTeamMemberTypeManager;
    }
    else
    {
        return member.type == NIMTeamMemberTypeOwner || member.type == NIMTeamMemberTypeManager || member.type == NIMTeamMemberTypeNormal;
    }
}

+ (BOOL)canInviteMember:(NIMTeamMember *)member
{
    NIMTeam *team = [[NIMSDK sharedSDK].teamManager teamById:member.teamId];
    if (team.inviteMode == NIMTeamInviteModeManager)
    {
        return member.type == NIMTeamMemberTypeOwner || member.type == NIMTeamMemberTypeManager;
    }
    else
    {
        return member.type == NIMTeamMemberTypeOwner || member.type == NIMTeamMemberTypeManager || member.type == NIMTeamMemberTypeNormal;
    }

}

@end
