
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
import NECoreIMKit
import NECoreKit
public class NotificationMessageUtils: NSObject {
  public class func textForNotification(message: NIMMessage) -> String {
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

  public class func isDiscussSeniorTeamUpdateCustomNoti(message: NIMMessage) -> Bool {
    if let object = message.messageObject as? NIMNotificationObject {
      guard let content = object.content as? NIMTeamNotificationContent else {
        return false
      }

      // 转移讨论组的通知
      if content.operationType == .transferOwner,
         teamName(message: message) == chatLocalizable("discussion_group") {
        return true
      }

      if content.operationType != .update {
        return false
      }
      guard let attach = content.attachment as? NIMUpdateTeamInfoAttachment,
            let tag = attach.values?.keys.first?.intValue else {
        return false
      }

      if tag == 18 || tag == 19 {
        return true
      }
    }
    return false
  }

  public class func isTeamLeaveOrDismiss(message: NIMMessage) -> (isLeave: Bool, isDismiss: Bool) {
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

  public class func textForTeamNotificationMessage(message: NIMMessage) -> String {
    var text = chatLocalizable("unknown_system_message")
    if let object = message.messageObject as? NIMNotificationObject {
      if let content = object.content as? NIMTeamNotificationContent {
        let fromName = fromName(message: message)
        let toNames = toName(message: message)
        let toFirstName = toNames.first ?? ""
        let teamName = teamName(message: message)
        var toNamestext = toNames.first ?? ""
        if toNames.count > 1 {
          toNamestext = toNames.joined(separator: ",")
        }
        switch content.operationType {
        case .invite:
          var str = fromName + chatLocalizable("invite")
          if let first = toNames.first {
            str += first
          }
          if toNames.count > 1 {
            str = str + " " + String(toNames.count) + " " + chatLocalizable("humans")
          }
          str = str + chatLocalizable("enter") + teamName
          text = str
        case .dismiss:
          text = fromName + chatLocalizable("dissolve") + teamName
        case .kick:
          var str = fromName + chatLocalizable("kick")
          if let first = toNames.first {
            str += first
          }
          if toNames.count > 1 {
            str = str + " " + String(toNames.count) + " " + chatLocalizable("humans")
          }
          str = str + chatLocalizable("out") + teamName
          text = str

        case .update:
          text = textOfUpdateTeam(
            fromName: fromName,
            teamName: teamName,
            content: content
          )
        case .leave:
          text = fromName + chatLocalizable("leave") + teamName
        case .applyPass:
          if fromName == toNamestext {
            text = fromName + chatLocalizable("join") + teamName
          } else {
            text = fromName + chatLocalizable("pass") + toNamestext
          }

        case .transferOwner:
          text = fromName + chatLocalizable("transfer") + toFirstName
        case .addManager:
          text = toFirstName + chatLocalizable("added_manager")
        case .removeManager:
          text = toFirstName + chatLocalizable("removed_mamager")
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

  public class func fromName(message: NIMMessage) -> String {
    if let object = message.messageObject as? NIMNotificationObject {
      if let content = object.content as? NIMTeamNotificationContent {
        if content.sourceID == NIMSDK.shared().loginManager.currentAccount() {
          return chatLocalizable("You")
        } else {
          if let sourceId = content.sourceID {
            let user = UserInfoProvider.shared.getUserInfo(userId: sourceId)
            return user?.showName() ?? ""
          }
        }
      }
    }
    return ""
  }

  public class func toName(message: NIMMessage) -> [String] {
    var toNames = [String]()
    guard let object = message.messageObject as? NIMNotificationObject,
          let content = object.content as? NIMTeamNotificationContent,
          let targetIDs = content.targetIDs else {
      return toNames
    }
    for targetID in targetIDs {
      if targetID == NIMSDK.shared().loginManager.currentAccount() {
        toNames.append(chatLocalizable("You"))
      } else {
        toNames
          .append(UserInfoProvider.shared.getUserInfo(userId: targetID)?.showName() ?? "")
      }
    }
    return toNames
  }

  public class func teamName(message: NIMMessage) -> String {
    let team = TeamProvider.shared.teamInfo(teamId: message.session?.sessionId)
    if team?.type == .normalTeam || (team?.type == .advancedTeam && team?.nimTeam?.clientCustomInfo?.contains(discussTeamKey) == true) {
      return chatLocalizable("discussion_group")
    } else {
      return chatLocalizable("group")
    }
  }

  private class func textOfUpdateTeam(fromName: String, teamName: String,
                                      content: NIMTeamNotificationContent) -> String {
    var text = fromName + chatLocalizable("has_updated") + teamName
    if let attach = content.attachment as? NIMUpdateTeamInfoAttachment {
      if let tag = attach.values?.keys.first?.intValue {
        let string = getShowString(fromName, teamName, tag, attach.values?.values.first)
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

  private class func getShowString(_ fromName: String, _ teamName: String, _ tag: Int, _ muteState: String?) -> String {
    var text = ""
    switch tag {
    case 3:
      text = fromName + chatLocalizable("has_updated") + teamName + " " +
        chatLocalizable("team_name")
    case 14:
      text = fromName + chatLocalizable("has_updated") + teamName + " " +
        chatLocalizable("team_intro")
    case 15:
      text = fromName + chatLocalizable("has_updated") + teamName + " " +
        chatLocalizable("team_anouncement")
    case 16:
      text = fromName + chatLocalizable("has_updated") + teamName + " " +
        chatLocalizable("team_join_mode")
    case 18:
      text = fromName + chatLocalizable("has_updated") + " " + chatLocalizable("team_custom_info")
    case 19:
      text = fromName + chatLocalizable("has_updated") + " " + chatLocalizable("team_custom_info")
    case 20:
      text = fromName + chatLocalizable("has_updated") + teamName + " " +
        chatLocalizable("team_avatar")
    case 21:
      text = fromName + chatLocalizable("has_updated") + " " +
        chatLocalizable("team_be_invited_author")
    case 22:
      text = fromName + chatLocalizable("has_updated") + " " +
        chatLocalizable("team_be_invited_permission")
    case 23:
      text = fromName + chatLocalizable("has_updated") + " " +
        chatLocalizable("team_update_info_permission")
    case 24:
      text = fromName + chatLocalizable("has_updated") + " " +
        chatLocalizable("team_update_client_custom")
    case 100:

      if muteState == "1" || muteState == "3" {
        text = chatLocalizable("team_all_mute")
      } else if muteState == "0" {
        text = chatLocalizable("team_all_no_mute")
      }
    default:
      text = fromName + chatLocalizable("has_updated") + teamName
    }
    return text
  }
}
