// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objc
public protocol PinMessageViewModelDelegate: NSObjectProtocol {
  func tableViewReload(needLoad: Bool)
  func tableViewReload(_ indexPaths: [IndexPath])
  func tableViewDelete(_ indexPaths: [IndexPath])
  func refreshModel(_ model: NEPinMessageModel)
}

@objcMembers
open class PinMessageViewModel: NSObject, NEChatListener {
  public let chatRepo = ChatRepo.shared
  public var items = [NEPinMessageModel]()
  public var delegate: PinMessageViewModelDelegate?
  public var conversationId: String?

  override public init() {
    super.init()
    chatRepo.addChatListener(self)
  }

  open func getPinitems(conversationId: String, _ completion: @escaping (Error?) -> Void) {
    let group = DispatchGroup()
    weak var weakSelf = self
    self.conversationId = conversationId
    chatRepo.searchMessagePinHistory(conversationId: conversationId) { pinItems, error in
      if let pins = pinItems {
        let messageRefers = pins.compactMap(\.messageRefer)
        group.enter()
        weakSelf?.chatRepo.getMessageListByRefers(messageRefers) { messages, error in
          if let messages = messages {
            weakSelf?.items.removeAll()
            for message in messages {
              for item in pins {
                if message.messageClientId == item.messageRefer?.messageClientId {
                  let pinModel = NEPinMessageModel(message: message, item: item)
                  weakSelf?.items.append(pinModel)
                }
              }
            }
          } else {
            completion(error)
          }
          group.leave()
        }

        group.notify(queue: .main) {
          weakSelf?.items.sort { model1, model2 in
            model1.message.createTime > model2.message.createTime
          }
          completion(error)
          weakSelf?.loadMoreWithModel(items: weakSelf?.items) {
            weakSelf?.delegate?.tableViewReload(needLoad: false)
          }
        }
      } else {
        completion(error)
      }
    }
  }

  open func loadMoreWithModel(items: [NEPinMessageModel]?, _ completion: @escaping () -> Void) {
    guard let items = items else {
      completion()
      return
    }

    let userIds = items.compactMap(\.message.senderId)
    if let conversationId = conversationId, let teamId = V2NIMConversationIdUtil.conversationTargetId(conversationId) {
      ChatTeamCache.shared.loadShowName(userIds: userIds, teamId: teamId) {
        for item in items {
          let (name, user) = ChatTeamCache.shared.getShowName(item.chatmodel.message?.senderId ?? "")
          item.chatmodel.avatar = user?.user?.avatar
          item.chatmodel.fullName = name
          item.chatmodel.shortName = ChatMessageHelper.getShortName(user?.showName(false) ?? "")
        }
        completion()
      }
    }
  }

  open func removePinMessage(_ message: V2NIMMessage,
                             _ completion: @escaping (Error?)
                               -> Void) {
    NEALog.infoLog("PinMessageViewModel", desc: #function + ", messageId: \(String(describing: message.messageClientId))")
    chatRepo.removeMessagePin(messageRefer: message, serverExtension: "") { error in
      completion(error)
    }
  }

  open func sendTextMessage(text: String, conversationId: String, _ completion: @escaping (V2NIMSendMessageResult?, Error?, UInt) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", text.count: \(text.count)")
    if text.count <= 0 {
      return
    }
    chatRepo.sendMessage(
      message: MessageUtils.textMessage(text: text),
      conversationId: conversationId,
      completion
    )
  }

  open func forwardUserMessage(_ message: V2NIMMessage,
                               _ users: [V2NIMUser],
                               _ comment: String?,
                               _ completion: @escaping (V2NIMSendMessageResult?, Error?, UInt) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: \(String(describing: message.messageClientId))")
    for user in users {
      if let uid = user.accountId, let conversationId = V2NIMConversationIdUtil.p2pConversationId(uid) {
        let forwardMessage = MessageUtils.forwardMessage(message: message)
        ChatMessageHelper.clearForwardAtMark(forwardMessage)
        chatRepo.sendMessage(message: forwardMessage, conversationId: conversationId, completion)
        if let text = comment {
          sendTextMessage(text: text, conversationId: conversationId, completion)
        }
      }
    }
  }

  open func forwardTeamMessage(_ message: V2NIMMessage,
                               _ team: V2NIMTeam,
                               _ comment: String?,
                               _ completion: @escaping (V2NIMSendMessageResult?, Error?, UInt) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: \(String(describing: message.messageClientId))")
    let conversationId = V2NIMConversationIdUtil.teamConversationId(team.teamId) ?? ""
    let forwardMessage = MessageUtils.forwardMessage(message: message)
    ChatMessageHelper.clearForwardAtMark(forwardMessage)
    chatRepo.sendMessage(message: forwardMessage, conversationId: conversationId, completion)
    if let text = comment {
      sendTextMessage(text: text, conversationId: conversationId, completion)
    }
  }

  open func downLoad(_ urlString: String,
                     _ filePath: String,
                     _ progress: ((UInt) -> Void)?,
                     _ completion: ((String?, NSError?) -> Void)?) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + urlString)
    ResourceRepo.shared.downLoad(urlString, filePath, progress, completion)
  }

  open func getHandSetEnable() -> Bool {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    return SettingRepo.shared.getHandsetMode()
  }

  func onDeleteIndexPath(_ messageRefers: [V2NIMMessageRefer?]) {
    var indexs = [IndexPath]()
    for messageRefer in messageRefers {
      for (i, model) in items.enumerated() {
        if model.message.messageClientId == messageRefer?.messageClientId {
          indexs.append(IndexPath(row: i, section: 0))
        }
      }
    }

    for messageRefer in messageRefers {
      items.removeAll { $0.message.messageClientId == messageRefer?.messageClientId }
    }

    delegate?.tableViewDelete(indexs)
  }

  // MARK: - NEChatListener

  /// 收到消息撤回回调
  /// - Parameter revokeNotifications: 消息撤回通知数据
  public func onMessageRevokeNotifications(_ revokeNotifications: [V2NIMMessageRevokeNotification]) {
    delegate?.tableViewReload(needLoad: true)
  }

  /// 消息pin状态回调通知
  /// - Parameter pinNotification: 消息pin状态变化通知数据
  public func onMessagePinNotification(_ pinNotification: V2NIMMessagePinNotification) {
    switch pinNotification.pinState {
    case .MESSAGE_PIN_STEATE_NOT_PINNED:
      let messageRefer = pinNotification.pin?.messageRefer
      onDeleteIndexPath([messageRefer])
    case .MESSAGE_PIN_STEATE_PINNED:
      delegate?.tableViewReload(needLoad: true)
    case .MESSAGE_PIN_STEATE_UPDATED:
      delegate?.tableViewReload(needLoad: true)
    default:
      break
    }
  }

  /// 消息被删除通知
  /// - Parameter messageDeletedNotification: 被删除的消息列表
  public func onMessageDeletedNotifications(_ messageDeletedNotification: [V2NIMMessageDeletedNotification]) {
    let messageRefers = messageDeletedNotification.map(\.messageRefer)
    onDeleteIndexPath(messageRefers)
  }
}
