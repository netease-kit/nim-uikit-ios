
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
import NEKitCoreIM
import NEKitCore
public class NotificationMessageUtils {
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

  public class func textForTeamNotificationMessage(message: NIMMessage) -> String {
    var text = localizable("unknown_system_message")
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
          var str = fromName + localizable("invite")
          if let first = toNames.first {
            str = str + first
          }
          if toNames.count > 1 {
            str = str + " " + String(toNames.count) + " " + localizable("humans")
          }
          str = str + localizable("enter") + teamName
          text = str
        case .dismiss:
          text = fromName + localizable("dissolve") + teamName
        case .kick:
          var str = fromName + localizable("kick")
          if let first = toNames.first {
            str = str + first
          }
          if toNames.count > 1 {
            str = str + " " + String(toNames.count) + " " + localizable("humans")
          }
          str = str + localizable("out") + teamName
          text = str

        case .update:
          text = textOfUpdateTeam(
            fromName: fromName,
            teamName: teamName,
            content: content
          )
        case .leave:
          text = fromName + localizable("leave") + teamName
        case .applyPass:
          if fromName == toNamestext {
            text = fromName + localizable("join") + teamName
          } else {
            text = fromName + localizable("pass") + toNamestext
          }

        case .transferOwner:
          text = fromName + localizable("transfer") + toFirstName
        case .addManager:
          text = toFirstName + localizable("added_manager")
        case .removeManager:
          text = toFirstName + localizable("removed_mamager")
        case .acceptInvitation:
          text = fromName + localizable("accept") + toNamestext
        case .mute:
          var mute = false
          if let atta = content.attachment as? NIMMuteTeamMemberAttachment {
            mute = atta.flag
          }
          if let atta = content.attachment as? NIMMuteSuperTeamMemberAttachment {
            mute = atta.flag
          }
          text = mute ? localizable("team_all_mute") : localizable("team_all_no_mute")

        default:
          text = localizable("unknown_system_message")
        }
      }
    }
    return text
  }

  public class func fromName(message: NIMMessage) -> String {
    if let object = message.messageObject as? NIMNotificationObject {
      if let content = object.content as? NIMTeamNotificationContent {
        if content.sourceID == NIMSDK.shared().loginManager.currentAccount() {
          return localizable("You")
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
        toNames.append(localizable("You"))
      } else {
        toNames
          .append(UserInfoProvider.shared.getUserInfo(userId: targetID)?.showName() ?? "")
      }
    }
    return toNames
  }

  public class func teamName(message: NIMMessage) -> String {
    let team = TeamProvider.shared.teamInfo(teamId: message.session?.sessionId)
    if team?.type == .normalTeam {
      return localizable("discussion_group")
    } else {
      return localizable("group")
    }
  }

  private class func textOfUpdateTeam(fromName: String, teamName: String,
                                      content: NIMTeamNotificationContent) -> String {
    var text = fromName + localizable("has_updated") + teamName
    guard let attach = content.attachment as? NIMUpdateTeamInfoAttachment else {
      return text
    }
    if attach.values?.count == 1 {
      let tag = attach.values?.keys.first?.intValue
      switch tag {
      case 3:
        text = fromName + localizable("has_updated") + teamName + " " +
          localizable("team_name")
      case 14:
        text = fromName + localizable("has_updated") + teamName + " " +
          localizable("team_intro")
      case 15:
        text = fromName + localizable("has_updated") + teamName + " " +
          localizable("team_anouncement")
      case 16:
        text = fromName + localizable("has_updated") + teamName + " " +
          localizable("team_join_mode")
      case 18:
        text = fromName + localizable("has_updated") + " " + localizable("team_custom_info")
      case 19:
        text = fromName + localizable("has_updated") + " " + localizable("team_custom_info")
      case 20:
        text = fromName + localizable("has_updated") + teamName + " " +
          localizable("team_avatar")
      case 21:
        text = fromName + localizable("has_updated") + " " +
          localizable("team_be_invited_author")
      case 22:
        text = fromName + localizable("has_updated") + " " +
          localizable("team_be_invited_permission")
      case 23:
        text = fromName + localizable("has_updated") + " " +
          localizable("team_update_info_permission")
      case 24:
        text = fromName + localizable("has_updated") + " " +
          localizable("team_update_client_custom")
      case 100:
        let muteState = attach.values?.values.first

        if muteState == "0" {
          text = teamName + localizable("not_mute")
        } else {
          text = teamName + localizable("mute")
        }
      default:
        text = fromName + localizable("has_updated") + teamName
      }
    }
    return text
  }
}
