
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK

public enum TeamType {
  case advanceTeam
  case discussTeam
}

open class NotificationMessageUtils: NSObject {
  open class func textForNotification(message: V2NIMMessage) -> String {
    if message.messageType != .MESSAGE_TYPE_NOTIFICATION {
      return ""
    }
    if message.attachment is V2NIMMessageNotificationAttachment {
      let text = textForTeamNotificationMessage(message: message)
      return text
    } else {
      return fromName(message: message) + (message.text ?? "")
    }
  }

  /// 是否是群通知
  open class func isDiscussSeniorTeamNoti(message: V2NIMMessage) -> Bool {
    if message.attachment is V2NIMMessageNotificationAttachment {
      return true
    }
    return false
  }

  open class func isTeamLeaveOrDismiss(message: V2NIMMessage) -> (isLeave: Bool, isDismiss: Bool) {
    var leave = false
    var dismiss = false
    if let content = message.attachment as? V2NIMMessageNotificationAttachment {
      switch content.type {
      case .MESSAGE_NOTIFICATION_TYPE_TEAM_LEAVE:
        leave = true
      case .MESSAGE_NOTIFICATION_TYPE_TEAM_DISMISS:
        dismiss = true
      default:
        break
      }
    }
    return (leave, dismiss)
  }

  open class func textForTeamNotificationMessage(message: V2NIMMessage) -> String {
    var text = chatLocalizable("unknown_system_message")
    if let content = message.attachment as? V2NIMMessageNotificationAttachment {
      let fromName = fromName(message: message)
      let toNames = toName(message: message)
      let toFirstName = toNames.first ?? ""
      let teamName = teamName(message: message)
      var toNamestext = toNames.first ?? ""
      if toNames.count > 1 {
        toNamestext = toNames.joined(separator: "、")
      }
      switch content.type {
      case .MESSAGE_NOTIFICATION_TYPE_TEAM_INVITE:
        text = fromName + chatLocalizable("invite") + toNamestext + chatLocalizable("enter") + chatLocalizable("group_chat")
      case .MESSAGE_NOTIFICATION_TYPE_TEAM_DISMISS:
        text = fromName + chatLocalizable("dissolve") + chatLocalizable("group_chat")
      case .MESSAGE_NOTIFICATION_TYPE_TEAM_KICK:
        text = fromName + chatLocalizable("kick") + toNamestext + chatLocalizable("out") + chatLocalizable("group_chat")
      case .MESSAGE_NOTIFICATION_TYPE_TEAM_UPDATE_TINFO:
        text = "update team info"
        text = textOfUpdateTeam(
          fromName: fromName,
          teamName: teamName,
          content: content
        )
      case .MESSAGE_NOTIFICATION_TYPE_TEAM_LEAVE:
        text = fromName + chatLocalizable("leave") + chatLocalizable("group_chat")
      case .MESSAGE_NOTIFICATION_TYPE_TEAM_APPLY_PASS:
        if fromName == toNamestext {
          text = fromName + chatLocalizable("join") + chatLocalizable("group_chat")
        } else {
          text = fromName + chatLocalizable("pass") + toNamestext
        }
      case .MESSAGE_NOTIFICATION_TYPE_TEAM_OWNER_TRANSFER:
        text = fromName + chatLocalizable("transfer") + toFirstName
      case .MESSAGE_NOTIFICATION_TYPE_TEAM_ADD_MANAGER:
        text = toNamestext + chatLocalizable("added_manager")
      case .MESSAGE_NOTIFICATION_TYPE_TEAM_REMOVE_MANAGER:
        text = toFirstName + chatLocalizable("removed_manager")
      case .MESSAGE_NOTIFICATION_TYPE_TEAM_INVITE_ACCEPT:
        text = fromName + chatLocalizable("accept") + toNamestext
      case .MESSAGE_NOTIFICATION_TYPE_TEAM_BANNED_TEAM_MEMBER:
        text = "\(toNamestext) \(content.chatBanned ? chatLocalizable("mute") : chatLocalizable("not_mute"))"
      default:
        text = chatLocalizable("unknown_system_message")
      }
      return text
    } else {
      return text
    }
  }

  open class func fromName(message: V2NIMMessage) -> String {
    if let sourceId = message.senderId {
      if sourceId == IMKitClient.instance.account() {
        return chatLocalizable("You") + " "
      } else {
        return NETeamUserManager.shared.getShowName(sourceId)
      }
    } else {
      return ""
    }
  }

  open class func toName(message: V2NIMMessage) -> [String] {
    var toNames = [String]()
    guard let content = message.attachment as? V2NIMMessageNotificationAttachment,
          let targetIDs = content.targetIds else {
      return toNames
    }

    for targetID in targetIDs {
      if targetID == IMKitClient.instance.account() {
        toNames.append(chatLocalizable("You") + " ")
      } else {
        let name = NETeamUserManager.shared.getShowName(targetID)
        toNames.append(name)
      }
    }
    return toNames
  }

  open class func teamName(message: V2NIMMessage) -> String {
    let teamtype = teamType(message: message)
    switch teamtype {
    case .advanceTeam:
      return chatLocalizable("group")
    case .discussTeam:
      return chatLocalizable("discussion_group")
    }
  }

  open class func teamType(message: V2NIMMessage) -> TeamType {
    if let team = NETeamUserManager.shared.getTeamInfo() {
      if team.isDisscuss() == true {
        return .discussTeam
      } else {
        return .advanceTeam
      }
    }
    return .advanceTeam
  }

  private class func textOfUpdateTeam(fromName: String,
                                      teamName: String,
                                      content: V2NIMMessageNotificationAttachment) -> String {
    var text = fromName + chatLocalizable("has_updated") + teamName

    guard let updatedTeamInfo = content.updatedTeamInfo else { return text }

    // 群名
    if let name = updatedTeamInfo.name {
      return fromName + " " + chatLocalizable("has_updated") + teamName +
        chatLocalizable("team_name") + chatLocalizable("to") + "\"" + name + "\""
    }

    // 群简介
    if updatedTeamInfo.intro != nil {
      return fromName + " " + chatLocalizable("has_updated") + teamName +
        chatLocalizable("team_intro")
    }

    // 群公告
    if updatedTeamInfo.announcement != nil {
      return fromName + " " + chatLocalizable("has_updated") + teamName +
        chatLocalizable("team_anouncement")
    }

    // 头像
    if updatedTeamInfo.avatar != nil {
      return fromName + " " + chatLocalizable("has_updated") + teamName +
        chatLocalizable("team_avatar")
    }

    // 群验证方式
    if updatedTeamInfo.joinMode.rawValue != -1 {
      return fromName + " " + chatLocalizable("has_updated") + teamName +
        chatLocalizable("team_join_mode")
    }

    // 被邀请模式
    if updatedTeamInfo.agreeMode.rawValue != -1 {
      return fromName + " " + chatLocalizable("has_updated") +
        chatLocalizable("team_be_invited_author")
    }

    // 邀请权限,仅高级群有效
    if updatedTeamInfo.inviteMode.rawValue != -1 {
      return fromName + " " + chatLocalizable("has_updated") + chatLocalizable("team_permission") + " \"" +
        chatLocalizable("team_be_invited_permission") + "\" " + chatLocalizable("to") + "\"" + (updatedTeamInfo.inviteMode == .TEAM_INVITE_MODE_MANAGER ? chatLocalizable("only_team_owner") : chatLocalizable("user_select_all")) + "\""
    }

    // 更新群信息权限,仅高级群有效
    if updatedTeamInfo.updateInfoMode.rawValue != -1 {
      return fromName + " " + chatLocalizable("has_updated") + chatLocalizable("team_permission") + " \"" +
        chatLocalizable("team_update_info_permission") + "\" " + chatLocalizable("to") + "\"" + (updatedTeamInfo.updateInfoMode == .TEAM_UPDATE_INFO_MODE_MANAGER ? chatLocalizable("only_team_owner") : chatLocalizable("user_select_all")) + "\""
    }

    // 群整体禁言
    if updatedTeamInfo.chatBannedMode.rawValue != -1 {
      return updatedTeamInfo.chatBannedMode == .TEAM_CHAT_BANNED_MODE_BANNED_NORMAL ? chatLocalizable("team_all_mute") : chatLocalizable("team_all_no_mute")
    }

    // 客户端自定义拓展字段
    if let serverExt = updatedTeamInfo.serverExtension, let extDic = getDictionaryFromJSONString(serverExt) {
      var lastOpt = keyAllowAtAll

      // 上一次操作的字段
      if let opt = extDic["lastOpt"] as? String {
        lastOpt = opt
      }

      // @所有人权限
      if lastOpt == keyAllowAtAll, let allowAt = extDic[keyAllowAtAll] as? String {
        if allowAt == allowAtManagerValue {
          return chatLocalizable("team_at_permission") + chatLocalizable("only_team_owner")
        }
        if allowAt == allowAtAllValue {
          return chatLocalizable("team_at_permission") + chatLocalizable("everyone")
        }
      }

      // 置顶消息权限
      if lastOpt == keyAllowTopMessage, let allowAt = extDic[keyAllowTopMessage] as? String {
        if allowAt == allowAtManagerValue {
          return chatLocalizable("team_top_permission") + chatLocalizable("only_team_owner")
        }
        if allowAt == allowAtAllValue {
          return chatLocalizable("team_top_permission") + chatLocalizable("everyone")
        }
      }

      // 置顶消息
      if lastOpt == keyTopMessage, let topInfo = extDic[keyTopMessage] as? [String: Any] {
        if let type = topInfo["operation"] as? Int {
          return fromName + " " + (type == 0 ? chatLocalizable("top_message") : chatLocalizable("untop_message"))
        }
      }
    } else {
      return fromName + " " + chatLocalizable("has_updated") + chatLocalizable("team_custom_info")
    }

    // 更新群客户端自定义拓展字段权限
    if updatedTeamInfo.updateExtensionMode.rawValue != -1 {
      return fromName + " " + chatLocalizable("has_updated") +
        chatLocalizable("team_update_client_custom")
    }

    return text
  }
}
