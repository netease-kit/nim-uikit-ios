// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit

public let ModuleName = "NEChatKit" // imkit 模块名, 用于埋点上报

public let imkitVersion = "10.9.25" // imkit 版本号, 用于埋点上报

public let imkitDir = "NEIMUIKit/" // imkit 沙盒文件夹名称

public let keyReplyMsgKey = "yxReplyMsg" // 回复消息key, 用于不使用 thread 的消息回复方案

public let keyAllowAtAll = "yxAllowAt" // 是否允许at所有人 key

public let keyAllowTopMessage = "yxAllowTop" // 是否允许所有人置顶消息 key

public let keyTopMessage = "yxMessageTop" // 置顶消息 key

public let keyEnableCloudConversation = "yxEnableCloudConversation" // 云端会话 key

public let keyEnableCloudMessageSearch = "yxEnableCloudMessageSearch" // 云端消息检索 key

public let keyTeamJoinActionReadTime = "keyTeamJoinActionReadTime" // 入群申请已读时间戳

public let keyCustomMessage = "CustomMessage" // 自定义消息日志 key

public let allowAtAllValue = "all"
public let allowAtManagerValue = "manager"

public let multiForwardFileName = "multiForward" // 合并转发消息文件名前缀

public let revokeLocalMessage = "revoke_message_local"
public let revokeLocalMessageTitle = "revoke_message_local_title"
public let revokeLocalMessageContent = "revoke_message_local_content"
public let revokeLocalMessageTime = "revoke_message_local_time"

public let NEAISearchPlugin = "NEAISearchKit"

/// 收藏类型与消息类型映射(在类型基础上+1000)
public let collectionTypeOffset = 1000

let coreLoader = CommonLoader<ChatKitClient>()

// MARK: - notificationkey

public enum NENotificationName {
  public static let popGroupChatVC = Notification.Name(rawValue: "team.popGroupChatVC")
  public static let clearValidationMessageUnreadCount = Notification.Name("contact.clearValidationMessageUnreadCount")
  public static let friendCacheInit = Notification.Name("cache.friendCacheInit")
  public static let didTapHeader = Notification.Name("cache.didTapHeader")
  /// 通知通讯录清理清理在线订阅(释放订阅数量，防止达到订阅上限)
  public static let clearContactSubscribeNotificationName = Notification.Name("clear.contact.subscribe")
  /// 通知通讯录检查好友在线订阅
  public static let checkoutSubscribeNotificationName = Notification.Name("check.contact.subscribe")
  /// 删除会话通知
  public static let deleteConversationNotificationName = Notification.Name("conversation.delete.coversation")

  /// 切换 app 内语言
  public static let changeLanguage = Notification.Name("app.changeLanguage")
}
