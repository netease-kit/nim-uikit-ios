//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import NIMSDK
import UIKit

struct MediaMessageModel {
  var time: String
  var messageModels: [MessageImageModel]
}

@objcMembers
open class TeamHistoryMessageViewModel: ChatViewModel, NETeamListener {
  /// 快速搜索选项
  public var operationTypes = [OperationItem]()
  var pageToken: String? = ""
  var allMessageShowTime: Bool = true // 是否每条消息都显示时间

  var mediaMessageModels: [MediaMessageModel] = []

  public var themeColor = UIColor.ne_normalTheme

  override public init() {
    super.init(conversationId: ChatRepo.conversationId)
    getOperationTypes("")
  }

  /// 重写初始化方法
  override public init(conversationId: String) {
    super.init(conversationId: conversationId)
    getOperationTypes(conversationId)
  }

  /// 重写初始化方法
  override public init(conversationId: String, anchor: V2NIMMessage?) {
    super.init(conversationId: conversationId, anchor: anchor)
    getOperationTypes(conversationId)
  }

  open func getOperationTypes(_ conversationId: String) {
    let sessionType = V2NIMConversationIdUtil.conversationType(conversationId)
    if sessionType == .CONVERSATION_TYPE_TEAM || sessionType == .CONVERSATION_TYPE_SUPER_TEAM {
      operationTypes.append(OperationItem.searchTeamMemberItem())
    }
    operationTypes.append(OperationItem.searchImageItem())
    operationTypes.append(OperationItem.searchVideoItem())
    operationTypes.append(OperationItem.searchDateItem())
    operationTypes.append(OperationItem.searchFileItem())
  }

  override open func loadShowName(_ accountIds: [String], _ teamId: String? = nil, _ completion: @escaping () -> Void) {
    if V2NIMConversationIdUtil.conversationType(ChatRepo.conversationId) == .CONVERSATION_TYPE_P2P {
      NEFriendUserCache.shared.loadShowName(accountIds) { users in
        for user in users ?? [] {
          // 非好友，单独缓存
          if let uid = user.user?.accountId, !NEFriendUserCache.shared.isFriend(uid) {
            NEP2PChatUserCache.shared.updateUserInfo(user)
          }
        }
        completion()
      }
    } else {
      DispatchQueue.global().async {
        NETeamUserManager.shared.getTeamMembers(accountIds, false, completion)
      }
    }
  }

  override open func getShowName(_ accountId: String, _ showAlias: Bool = true) -> String {
    if V2NIMConversationIdUtil.conversationType(ChatRepo.conversationId) == .CONVERSATION_TYPE_P2P {
      if NEFriendUserCache.shared.isFriend(accountId) {
        return NEFriendUserCache.shared.getShowName(accountId, showAlias)
      } else {
        return NEP2PChatUserCache.shared.getShowName(accountId, showAlias)
      }
    } else {
      return NETeamUserManager.shared.getShowName(accountId, showAlias)
    }
  }

  open func searchHistoryMessages(_ params: V2NIMMessageSearchExParams,
                                  _ firstSearch: Bool = false,
                                  _ completion: @escaping (Error?, NSInteger, Bool) -> Void) {
    if firstSearch {
      pageToken = ""
      messages.removeAll()
      mediaMessageModels.removeAll()
    }
    params.pageToken = pageToken
    params.limit = 100

    if IMKitConfigCenter.shared.enableCloudMessageSearch {
      chatRepo.searchCloudMessagesEx(params: params) { [weak self] result, error in
        self?.loadMessageModel(result, params)
        completion(error, result?.count ?? 0, result?.hasMore ?? false)
      }
    } else {
      chatRepo.searchLocalMessages(params: params) { [weak self] result, error in
        self?.loadMessageModel(result, params)
        completion(error, result?.count ?? 0, result?.hasMore ?? false)
      }
    }
  }

  func searchHistryMediaMessages(_ firstSearch: Bool = false,
                                 _ searchType: MessageType = .image,
                                 _ completion: @escaping (Error?, NSInteger, Bool) -> Void) {
    mediaMessageModels.removeAll()

    let params = V2NIMMessageSearchExParams()
    params.conversationId = ChatRepo.conversationId
    params.limit = 100

    switch searchType {
    case .image:
      params.messageTypes = [NSNumber(value: V2NIMMessageType.MESSAGE_TYPE_IMAGE.rawValue)]
      allMessageShowTime = false
    case .video:
      params.messageTypes = [NSNumber(value: V2NIMMessageType.MESSAGE_TYPE_VIDEO.rawValue)]
      allMessageShowTime = false
    case .file:
      params.messageTypes = [NSNumber(value: V2NIMMessageType.MESSAGE_TYPE_FILE.rawValue)]
    default:
      params.messageTypes = [NSNumber(value: V2NIMMessageType.MESSAGE_TYPE_IMAGE.rawValue),
                             NSNumber(value: V2NIMMessageType.MESSAGE_TYPE_VIDEO.rawValue),
                             NSNumber(value: V2NIMMessageType.MESSAGE_TYPE_FILE.rawValue)]
    }

    searchHistoryMessages(params, firstSearch) { [weak self] error, messageCount, hasMore in
      guard let self = self else { return }

      var mediaMessageDic = [String: [MessageImageModel]]()
      var lastKsy: String?

      for (index, model) in self.messages.enumerated() {
        if let model = model as? MessageImageModel,
           let message = model.message {
          let date = Date(timeIntervalSince1970: message.createTime)
          var timeText = String.stringFromDate(date: date, showHM: false)
          if searchType == .file {
            let formatter = DateFormatter()
            formatter.dateFormat = commonLocalizable("ym")
            timeText = formatter.string(from: date)
          }

          if let _ = mediaMessageDic[timeText] {
            if searchType == .file {
              mediaMessageDic[timeText]?.append(model)
            } else {
              mediaMessageDic[timeText]?.insert(model, at: 0)
            }
          } else {
            mediaMessageDic[timeText] = [model]
            if let key = lastKsy, let value = mediaMessageDic[key] {
              let model = MediaMessageModel(time: key, messageModels: value)
              if searchType == .file {
                self.mediaMessageModels.append(model)
              } else {
                self.mediaMessageModels.insert(model, at: 0)
              }
              mediaMessageDic[key] = nil
            }
            lastKsy = timeText
          }

          if index == self.messages.count - 1 {
            if let value = mediaMessageDic[timeText] {
              let model = MediaMessageModel(time: timeText, messageModels: value)
              if searchType == .file {
                self.mediaMessageModels.append(model)
              } else {
                self.mediaMessageModels.insert(model, at: 0)
              }
            }
          }
        }
      }

      completion(error, messageCount, hasMore)
    }
  }

  open func loadMessageModel(_ result: V2NIMMessageSearchResult?,
                             _ params: V2NIMMessageSearchExParams) {
    guard let result = result, let messagesList = result.items.first?.messages else {
      return
    }

    pageToken = result.nextPageToken

    var filterNoti = false
    if params.senderAccountIds?.isEmpty == false {
      filterNoti = true
    }

    for msg in messagesList {
      if filterNoti, msg.messageType == .MESSAGE_TYPE_NOTIFICATION {
        continue
      }

      if ChatMessageHelper.isRevokeMessage(message: msg) {
        continue
      }

      // 数字人回复的消息
      if ChatMessageHelper.isAISender(msg) {
        setErrorText(msg)
      }

      let model = modelFromMessage(message: msg)
      if let keyword = params.keywordList?.first {
        if let m = model as? MessageTextModel {
          if let att = ChatMessageHelper.loadKeywordInMessage(msg, m.attributeStr, keyword, themeColor) {
            m.attributeStr = att
          }
        }

        if let m = model as? MessageRichTextModel {
          if let att = ChatMessageHelper.loadKeywordInMessage(msg, m.titleAttributeStr, keyword, themeColor) {
            m.titleAttributeStr = att
          }
        }
      }

      if messages.contains(where: { $0.message?.messageClientId == model.message?.messageClientId }) == false {
        messages.append(model)
      }
    }

    if allMessageShowTime {
      // 显示时间
      addTimeForHistoryMessage(false)
    }

    loadMoreWithMessage(messagesList)
  }

  override open func addTimeForHistoryMessage(_ forward: Bool = true) {
    for model in messages {
      let curTime = model.message?.createTime ?? 0
      let timeText = String.stringFromDate(date: Date(timeIntervalSince1970: curTime))
      model.timeContent = timeText
    }
  }

  override open func onReceiveMessages(_ messages: [V2NIMMessage]) {}

  override open func onMessageRevokeNotifications(_ revokeNotifications: [V2NIMMessageRevokeNotification]) {
    for revokeNoti in revokeNotifications {
      if revokeNoti.messageRefer?.conversationId != ChatRepo.conversationId {
        continue
      }
      if revokeNoti.messageRefer?.messageClientId?.isEmpty == true {
        continue
      }

      if mediaMessageModels.isEmpty,
         !messages.isEmpty {
        for (row, model) in messages.enumerated() {
          if let msg = model.message, msg.messageClientId == revokeNoti.messageRefer?.messageClientId {
            let indexPath = IndexPath(row: row, section: 0)
            messages.remove(at: row)
            delegate?.onRevokeMessage(msg, atIndexs: [indexPath])
            break
          }
        }
      }

      if !mediaMessageModels.isEmpty {
        for (section, models) in mediaMessageModels.enumerated() {
          for (item, model) in models.messageModels.enumerated() {
            if let msg = model.message, msg.messageClientId == revokeNoti.messageRefer?.messageClientId, !model.isRevoked {
              mediaMessageModels[section].messageModels.remove(at: item)
              delegate?.onRevokeMessage(msg, atIndexs: [IndexPath(item: item, section: section)])
              break
            }
          }
        }
      }
    }
  }

  override open func onMessageDeletedNotifications(_ messageDeletedNotification: [V2NIMMessageDeletedNotification]) {
    for deleteNoti in messageDeletedNotification {
      if deleteNoti.messageRefer.conversationId != ChatRepo.conversationId {
        continue
      }
      if deleteNoti.messageRefer.messageClientId?.isEmpty == true {
        continue
      }

      if mediaMessageModels.isEmpty,
         !messages.isEmpty {
        for (row, model) in messages.enumerated() {
          if let msg = model.message, msg.messageClientId == deleteNoti.messageRefer.messageClientId {
            let indexPath = IndexPath(row: row, section: 0)
            messages.remove(at: row)
            delegate?.onRevokeMessage(msg, atIndexs: [indexPath])
            break
          }
        }
      }

      if !mediaMessageModels.isEmpty {
        for (section, models) in mediaMessageModels.enumerated() {
          for (item, model) in models.messageModels.enumerated() {
            if let msg = model.message, msg.messageClientId == deleteNoti.messageRefer.messageClientId, !model.isRevoked {
              mediaMessageModels[section].messageModels.remove(at: item)
              delegate?.onRevokeMessage(msg, atIndexs: [IndexPath(item: item, section: section)])
              break
            }
          }
        }
      }
    }
  }
}
