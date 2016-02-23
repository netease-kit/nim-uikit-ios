//
//  NIMSDKHeaders.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#ifndef NIMLib_NIMSDKHeaders_h
#define NIMLib_NIMSDKHeaders_h

/**
 *  全局枚举和结构体定义
 */
#import "NIMGlobalDefs.h"

/**
 *  配置项
 */
#import "NIMSDKConfig.h"

/**
 *  会话相关定义
 */
#import "NIMSession.h"
#import "NIMRecentSession.h"
#import "NIMMessageSearchOption.h"

/**
 *  用户定义
 */
#import "NIMUser.h"

/**
 *  群相关定义
 */
#import "NIMTeam.h"
#import "NIMTeamMember.h"

/**
 *  聊天室相关定义
 */
#import "NIMChatroom.h"
#import "NIMChatroomEnterRequest.h"
#import "NIMMessageChatroomExtension.h"
#import "NIMChatroomMember.h"
#import "NIMChatroomMemberRequest.h"

/**
 *  消息定义
 */
#import "NIMMessage.h"
#import "NIMSystemNotification.h"

/**
 *  推送定义
 */
#import "NIMPushNotificationSetting.h"

/**
 *  登录定义
 */
#import "NIMLoginClient.h"

/**
 *  实时会话选项定义
 */
#import "NIMRTSOption.h"
#import "NIMRTSRecordingInfo.h"

/**
 *  音视频网络通话选项定义
 */
#import "NIMNetCallOption.h"


/**
 *  各个对外接口协议定义
 */
#import "NIMLoginManagerProtocol.h"
#import "NIMChatManagerProtocol.h"
#import "NIMConversationManagerProtocol.h"
#import "NIMMediaManagerProtocol.h"
#import "NIMUserManagerProtocol.h"
#import "NIMTeamManagerProtocol.h"
#import "NIMSystemNotificationManagerProtocol.h"
#import "NIMApnsManagerProtocol.h"
#import "NIMResourceManagerProtocol.h"
#import "NIMNetCallManagerProtocol.h"
#import "NIMRTSManagerProtocol.h"
#import "NIMChatroomManagerProtocol.h"

#endif
