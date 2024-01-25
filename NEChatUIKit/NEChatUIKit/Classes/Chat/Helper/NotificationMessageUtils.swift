
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIMKit
import NECoreKit
import NIMSDK

public enum TeamType {
  case advanceTeam
  case discussTeam
}

open class NotificationMessageUtils: NSObject {
  open class func textForNotification(message: NIMMessage) -> String {
    if message.messageType != .notification {
      return ""
    }
    if let object = message.messageObject as? NIMNotificationObject {
      switch object.notificationType {
      case .team:
        return textForTeamNotificationMessage(message: message)
      case .superTeam:
        return ""
      case .netCall:
        return ""
      case .chatroom:
        return ""
      default:
        return ""
      }
    }
    return ""
  }

  /// 是否是群通知
  open class func isDiscussSeniorTeamNoti(message: NIMMessage) -> Bool {
    if let object = message.messageObject as? NIMNotificationObject,
       let _ = object.content as? NIMTeamNotificationContent {
      return true
    }
    return false
  }

  open class func isDiscussSeniorTeamUpdateCustomNoti(message: NIMMessage) -> Bool {
    if let object = message.messageObject as? NIMNotificationObject {
      guard let content = object.content as? NIMTeamNotificationContent else {
        return false
      }

      // 转移讨论组的通知
      if content.operationType == .transferOwner,
         teamType(message: message) == .discussTeam {
        return true
      }

      if content.operationType != .update {
        return false
      }
      guard let attach = content.attachment as? NIMUpdateTeamInfoAttachment,
            let tag = attach.values?.keys.first?.intValue else {
        return false
      }

      // 18:客户端自定义拓展字段, 19: 服务器自定义拓展字段
      if tag == 18 || tag == 19 {
        return true
      }
    }
    return false
  }

  open class func isTeamLeaveOrDismiss(message: NIMMessage) -> (isLeave: Bool, isDismiss: Bool) {
    var leave = false
    var dismiss = false
    if let object = message.messageObject as? NIMNotificationObject, object.notificationType == .team {
      if let content = object.content as? NIMTeamNotificationContent {
        switch content.operationType {
        case .leave:
          leave = true

        case .dismiss:
          dismiss = true

        @unknown default:
          break
        }
      }
    }
    return (leave, dismiss)
  }

  open class func textForTeamNotificationMessage(message: NIMMessage) -> String {
    var text = chatLocalizable("unknown_system_message")
    if let object = message.messageObject as? NIMNotificationObject {
      if let content = object.content as? NIMTeamNotificationContent {
        let fromName = fromName(message: message)
        let toNames = toName(message: message)
        let toFirstName = toNames.first ?? ""
        let teamName = teamName(message: message)
        var toNamestext = toNames.first ?? ""
        if toNames.count > 1 {
          toNamestext = toNames.joined(separator: "、")
        }
        switch content.operationType {
        case .invite:
          text = fromName + chatLocalizable("invite") + toNamestext + chatLocalizable("enter") + chatLocalizable("group_chat")
        case .dismiss:
          text = fromName + chatLocalizable("dissolve") + chatLocalizable("group_chat")
        case .kick:
          text = fromName + chatLocalizable("kick") + toNamestext + chatLocalizable("out") + chatLocalizable("group_chat")
        case .update:
          text = textOfUpdateTeam(
            fromName: fromName,
            teamName: teamName,
            content: content
          )
        case .leave:
          text = fromName + chatLocalizable("leave") + chatLocalizable("group_chat")
        case .applyPass:
          if fromName == toNamestext {
            text = fromName + chatLocalizable("join") + chatLocalizable("group_chat")
          } else {
            text = fromName + chatLocalizable("pass") + toNamestext
          }

        case .transferOwner:
          text = fromName + chatLocalizable("transfer") + toFirstName
        case .addManager:
          text = toNamestext + chatLocalizable("added_manager")
        case .removeManager:
          text = toFirstName + chatLocalizable("removed_manager")
        case .acceptInvitation:
          text = fromName + chatLocalizable("accept") + toNamestext
        case .mute:
          var mute = false
          if let atta = content.attachment as? NIMMuteTeamMemberAttachment {
            mute = atta.flag
          }
          if let atta = content.attachment as? NIMMuteSuperTeamMemberAttachment {
            mute = atta.flag
          }
          // text = mute ? chatLocalizable("team_all_mute") : chatLocalizable("team_all_no_mute")
          text = "\(toNamestext) \(mute ? chatLocalizable("mute") : chatLocalizable("not_mute"))"

        default:
          text = chatLocalizable("unknown_system_message")
        }
      }
    }
    return text
  }

  open class func fromName(message: NIMMessage) -> String {
    if let object = message.messageObject as? NIMNotificationObject {
      if let content = object.content as? NIMTeamNotificationContent {
        if content.sourceID == NIMSDK.shared().loginManager.currentAccount() {
          return chatLocalizable("You") + " "
        } else {
          if let sourceId = content.sourceID {
            return ChatUserCache.getShowName(userId: sourceId, teamId: message.session?.sessionId)
          }
        }
      }
    }
    return ""
  }

  open class func toName(message: NIMMessage) -> [String] {
    var toNames = [String]()
    guard let object = message.messageObject as? NIMNotificationObject,
          let content = object.content as? NIMTeamNotificationContent,
          let targetIDs = content.targetIDs else {
      return toNames
    }
    for targetID in targetIDs {
      if targetID == NIMSDK.shared().loginManager.currentAccount() {
        toNames.append(chatLocalizable("You") + " ")
      } else {
        toNames
          .append(ChatUserCache.getShowName(userId: targetID, teamId: message.session?.sessionId))
      }
    }
    return toNames
  }

  open class func teamName(message: NIMMessage) -> String {
    let teamtype = teamType(message: message)
    switch teamtype {
    case .advanceTeam:
      return chatLocalizable("group")
    case .discussTeam:
      return chatLocalizable("discussion_group")
    }
  }

  open class func teamType(message: NIMMessage) -> TeamType {
    let team = TeamProvider.shared.getTeam(teamId: message.session?.sessionId ?? "")
    if team?.isDisscuss() == true {
      return .discussTeam
    } else {
      return .advanceTeam
    }
  }

  private class func textOfUpdateTeam(fromName: String,
                                      teamName: String,
                                      content: NIMTeamNotificationContent) -> String {
    var text = fromName + chatLocalizable("has_updated") + teamName
    if let attach = content.attachment as? NIMUpdateTeamInfoAttachment {
      if let tag = attach.values {
        let string = getShowString(fromName, teamName, tag)
        if string.count > 0 {
          text = string
        }
      }
    }
    if let attach = content.attachment as? NIMMuteTeamMemberAttachment {
      if attach.flag == false {
        text = teamName + chatLocalizable("team_all_mute")
      } else {
        text = teamName + chatLocalizable("team_all_no_mute")
      }
    }
    return text
  }

  private class func getShowString(_ fromName: String,
                                   _ teamName: String,
                                   _ tag: [NSNumber: String]) -> String {
    var text = ""

    // 群名
    if let value = tag[3] {
      text = fromName + " " + chatLocalizable("has_updated") + teamName +
        chatLocalizable("team_name") + chatLocalizable("to") + "\"" + value + "\""
    }

    // 群简介
    if let _ = tag[14] {
      text = fromName + " " + chatLocalizable("has_updated") + teamName +
        chatLocalizable("team_intro")
    }

    // 群公告
    if let _ = tag[15] {
      text = fromName + " " + chatLocalizable("has_updated") + teamName +
        chatLocalizable("team_anouncement")
    }

    // 群验证方式
    if let _ = tag[16] {
      text = fromName + " " + chatLocalizable("has_updated") + teamName +
        chatLocalizable("team_join_mode")
    }

    // 客户端自定义拓展字段
    if let _ = tag[18] {
      text = fromName + " " + chatLocalizable("has_updated") + chatLocalizable("team_custom_info")
    }

    // 服务器自定义拓展字段(SDK 无法直接修改这个字段, 请调用服务器接口)
    if let _ = tag[19] {
      text = fromName + " " + chatLocalizable("has_updated") + chatLocalizable("team_custom_info")
    }

    // 头像
    if let _ = tag[20] {
      text = fromName + " " + chatLocalizable("has_updated") + teamName +
        chatLocalizable("team_avatar")
    }

    // 被邀请模式
    if let _ = tag[21] {
      text = fromName + " " + chatLocalizable("has_updated") +
        chatLocalizable("team_be_invited_author")
    }

    // 邀请权限,仅高级群有效
    if let value = tag[22] {
      text = fromName + " " + chatLocalizable("has_updated") + chatLocalizable("team_permission") + " \"" +
        chatLocalizable("team_be_invited_permission") + "\" " + chatLocalizable("to") + "\"" + (value == "0" ? chatLocalizable("only_team_owner") : chatLocalizable("user_select_all")) + "\""
    }

    // 更新群信息权限,仅高级群有效
    if let value = tag[23] {
      text = fromName + " " + chatLocalizable("has_updated") + chatLocalizable("team_permission") + " \"" +
        chatLocalizable("team_update_info_permission") + "\" " + chatLocalizable("to") + "\"" + (value == "0" ? chatLocalizable("only_team_owner") : chatLocalizable("user_select_all")) + "\""
    }

    // 更新群客户端自定义拓展字段权限
    if let _ = tag[24] {
      text = fromName + " " + chatLocalizable("has_updated") +
        chatLocalizable("team_update_client_custom")
    }

    // 群禁言模式
    if let value = tag[100] {
      if value == "1" || value == "3" {
        text = chatLocalizable("team_all_mute")
      } else if value == "0" {
        text = chatLocalizable("team_all_no_mute")
      }
    }

    return text
  }
}
