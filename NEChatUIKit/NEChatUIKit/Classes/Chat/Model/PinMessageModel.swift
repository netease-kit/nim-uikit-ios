// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIMKit
import NIMSDK
import UIKit

public class PinMessageModel: NSObject {
  var chatmodel: MessageModel?
  var message: NIMMessage
  var item: NIMMessagePinItem
  var session: NIMSession
  var repo = ChatRepo.shared

  init(message: NIMMessage, item: NIMMessagePinItem) {
    self.message = message
    session = item.session
    self.item = item
    super.init()
    chatmodel = modelFromMessage(message: message)
  }

  private func modelFromMessage(message: NIMMessage) -> MessageModel {
    var model: MessageModel
    switch message.messageType {
    case .video:
      model = MessageVideoModel(message: message)
    case .text:
      model = MessageTextModel(message: message)
    case .image:
      model = MessageImageModel(message: message)
    case .audio:
      model = MessageAudioModel(message: message)
    case .notification:
      model = MessageTipsModel(message: message)
    case .file:
      model = MessageFileModel(message: message)
    case .tip:
      model = MessageTipsModel(message: message)
    case .location:
      model = MessageLocationModel(message: message)
    case .rtcCallRecord:
      model = MessageCallRecordModel(message: message)
    default:
      // 未识别的消息类型，默认为文本消息类型，text为未知消息
      message.text = "未知消息"
      model = MessageContentModel(message: message)
    }

    if let uid = message.from {
      let user = UserInfoProvider.shared.getUserInfo(userId: uid)
      var fullName = uid
      if let nickName = user?.userInfo?.nickName {
        fullName = nickName
      }
      model.avatar = user?.userInfo?.avatarUrl
      if session.sessionType == .team {
        // team
        let teamMember = TeamProvider.shared.teamMember(uid, session.sessionId)
        if let teamNickname = teamMember?.nickname {
          fullName = teamNickname
        }
      }
      if let alias = user?.alias {
        fullName = alias
      }
      model.fullName = fullName
      model.shortName = fullName
        .count > 2 ? String(fullName[fullName.index(fullName.endIndex, offsetBy: -2)...]) :
        fullName
    }

//    model.replyedModel = getReplyMessageWithoutThread(message: message)
//    if let pin = repo.searchMessagePinHistory(message) {
//      model.isPined = true
//      model.pinAccount = pin.accountID
//      let pinID = pin.accountID ?? NIMSDK.shared().loginManager.currentAccount()
//      model.pinShowName = getShowName(userId: pinID, teamId: session.sessionId)
//    } else {
//      model.isPined = false
//    }
    return model
  }

  public func getMessageType() -> Int {
    if message.messageType == .file ||
      message.messageType == .audio ||
      message.messageType == .text ||
      message.messageType == .image ||
      message.messageType == .video ||
      message.messageType == .location {
      return message.messageType.rawValue
    }
    return PinMessageDefaultType
  }

  public func cellHeight() -> CGFloat {
    var height = chatmodel?.contentSize.height ?? 0
    if let textModel = chatmodel as? MessageTextModel {
      height = textModel.textHeight
    }
    height += 100

    if chatmodel?.type == .text, height > 162 {
      height = 162
    }

    if chatmodel?.replyedModel?.isReplay == true {
      height += 12
    }

    return height
  }

  public func getReplyMessageWithoutThread(message: NIMMessage) -> MessageModel? {
    var replyId: String? = message.repliedMessageId
    if let yxReplyMsg = message.remoteExt?[keyReplyMsgKey] as? [String: Any] {
      replyId = yxReplyMsg["idClient"] as? String
    }

    guard let id = replyId, !id.isEmpty else {
      return nil
    }

    if let m = ConversationProvider.shared.messagesInSession(session, messageIds: [id])?
      .first {
      let model = modelFromMessage(message: m)
      model.isReplay = true
      return model
    }
    let message = NIMMessage()
    let model = modelFromMessage(message: message)
    model.isReplay = true
    return model
  }

  //    获取展示的用户名字，p2p： 备注 > 昵称 > ID  team: 备注 > 群昵称 > 昵称 > ID
  private func getShowName(userId: String, teamId: String?) -> String {
    let user = getUserInfo(userId: userId)
    var fullName = userId
    if let nickName = user?.userInfo?.nickName {
      fullName = nickName
    }
    if let tID = teamId, session.sessionType == .team {
      // team
      let teamMember = getTeamMember(userId: userId, teamId: tID)
      if let teamNickname = teamMember?.nickname {
        fullName = teamNickname
      }
    }
    if let alias = user?.alias {
      fullName = alias
    }
    return fullName
  }

  public func getUserInfo(userId: String) -> User? {
    repo.getUserInfo(userId: userId)
  }

  public func getTeamMember(userId: String, teamId: String) -> NIMTeamMember? {
    repo.getTeamMemberList(userId: userId, teamId: teamId)
  }
}
