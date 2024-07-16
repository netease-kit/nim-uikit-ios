// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreText
import Foundation
import NEChatKit
import NECoreIM2Kit
import NIMSDK

@objc
public protocol TeamChatViewModelDelegate: ChatViewModelDelegate {
  @objc optional func onTeamRemoved(team: V2NIMTeam)
  @objc optional func onTeamUpdate(team: V2NIMTeam)
  @objc optional func onTeamMemberUpdate(_ teamMembers: [V2NIMTeamMember])
}

@objcMembers
open class TeamChatViewModel: ChatViewModel, NETeamListener {
  public let teamRepo = TeamRepo.shared
  public var team: V2NIMTeam?
  /// 当前成员的群成员对象类
  public var teamMember: V2NIMTeamMember?

  override init(conversationId: String) {
    super.init(conversationId: conversationId)
  }

  override init(conversationId: String, anchor: V2NIMMessage?) {
    super.init(conversationId: conversationId, anchor: anchor)
  }

  /// 添加子类监听
  override open func addListener() {
    super.addListener()
    teamRepo.addTeamListener(self)
    NETeamUserManager.shared.addListener(self)
    NETeamUserManager.shared.loadData(sessionId)
  }

  deinit {
    teamRepo.removeTeamListener(self)
    NETeamUserManager.shared.removeListener(self)
  }

  /// 重写 获取用户展示名称
  /// - Parameters:
  ///   - accountId: 用户 accountId
  ///   - showAlias: 是否展示备注
  /// - Returns: 名称和好友信息
  override open func getShowName(_ accountId: String, _ showAlias: Bool = true) -> String {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", accountId:" + accountId)
    return NETeamUserManager.shared.getShowName(accountId, showAlias)
  }

  /// 重写 获取用户展示名称
  /// - Parameters:
  ///   - accountId: 用户 accountId
  ///   - showAlias: 是否展示备注
  ///   - completion: 完成回调
  override open func loadShowName(_ accountIds: [String],
                                  _ teamId: String?,
                                  _ completion: @escaping () -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamId:\(String(describing: teamId))")
    NETeamUserManager.shared.getTeamMembers(accountIds: accountIds, completion)
  }

  /// 加载置顶消息
  override open func loadTopMessage() {
    // 校验配置项
    if !IMKitConfigCenter.shared.enableTopMessage {
      return
    }

    if let serverJson = team?.serverExtension, let extDic = getDictionaryFromJSONString(serverJson) {
      if let topInfo = extDic[keyTopMessage] as? [String: Any] {
        if let type = topInfo["operation"] as? Int, type == 0 {
          let refer = ChatMessageHelper.createMessageRefer(topInfo)
          chatRepo.getMessageListByRefers([refer]) { [weak self] messages, error in
            // 这里查询只是为了校验消息是否还存在（未被删除或撤回）
            if let topMessage = messages?.first,
               let senderId = ChatMessageHelper.getSenderId(topMessage) {
              var senderName = self?.getShowName(senderId) ?? ""
              let group = DispatchGroup()

              if senderName == senderId {
                group.enter()
                self?.loadShowName([senderId], self?.sessionId) {
                  senderName = self?.getShowName(senderId) ?? ""
                  group.leave()
                }
              }

              group.notify(queue: .main) {
                let content = ChatMessageHelper.contentOfMessage(topMessage)
                var thumbUrl: String?
                var isVideo = false
                var hideClose = true

                // 获取图片缩略图
                if let attach = topMessage.attachment as? V2NIMMessageImageAttachment, let imageUrl = attach.url {
                  thumbUrl = V2NIMStorageUtil.imageThumbUrl(imageUrl, thumbSize: 350)
                }

                // 获取视频首帧
                if let attach = topMessage.attachment as? V2NIMMessageVideoAttachment, let videoUrl = attach.url {
                  thumbUrl = V2NIMStorageUtil.videoCoverUrl(videoUrl, offset: 0)
                  isVideo = true
                }

                // 是否隐藏移除置顶按钮
                if self?.hasTopMessagePremission() == true {
                  hideClose = false
                }

                self?.delegate?.setTopValue(name: senderName,
                                            content: content,
                                            url: thumbUrl,
                                            isVideo: isVideo,
                                            hideClose: hideClose)
                self?.topMessage = topMessage
              }
            } else {
              // 置顶消息已被删除
              self?.topMessage = nil
              self?.delegate?.setTopValue(name: nil, content: nil, url: nil, isVideo: false, hideClose: false)
            }
          }
        } else {
          topMessage = nil
          delegate?.setTopValue(name: nil, content: nil, url: nil, isVideo: false, hideClose: false)
        }
      }
    }
  }

  /// 校验置顶消息权限
  /// - Returns: 是否具有置顶消息权限
  func hasTopMessagePremission() -> Bool {
    // 讨论组所有人都有权限
    if team?.isDisscuss() == true {
      return true
    }

    // 高级群
    if teamMember?.memberRole == .TEAM_MEMBER_ROLE_OWNER || teamMember?.memberRole == .TEAM_MEMBER_ROLE_MANAGER {
      // 群主和管理员都有权限
      return true
    } else if teamMember?.memberRole == .TEAM_MEMBER_ROLE_NORMAL {
      if let custom = team?.serverExtension,
         let json = getDictionaryFromJSONString(custom) {
        if let atValue = json[keyAllowTopMessage] as? String, atValue == allowAtAllValue {
          return true
        } else {
          return false
        }
      } else {
        return false
      }
    }

    return false
  }

  /// 置顶消息
  /// - Parameter completion: 回调
  override open func topMessage(_ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageClientId: \(String(describing: operationModel?.message?.messageClientId))")
    guard let message = operationModel?.message else { return }

    let topMessageDic: [String: Any] = [
      "idClient": message.messageClientId as Any,
      "scene": message.conversationType.rawValue,
      "from": message.senderId as Any,
      "receiverId": message.receiverId as Any,
      "to": message.conversationId as Any,
      "idServer": message.messageServerId as Any,
      "time": Int(message.createTime * 1000),
      "operator": IMKitClient.instance.account(), // 操作者
      "operation": 0, // 操作: 0 - "add"; 1 - "remove";
    ]

    // 更新群扩展
    TeamRepo.shared.getTeamInfo(sessionId) { [weak self] team, error in
      if let err = error {
        print("getTeamInfo error: \(String(describing: err))")
        completion(err)
        return
      }

      guard let tid = self?.sessionId else { return }

      // 校验权限
      if self?.hasTopMessagePremission() == false {
        let error = NSError(domain: chatLocalizable("no_permission_tip"), code: noPermissionOperationCode)
        completion(error)
        return
      }

      var serverExtension = [String: Any]()
      if let serverJson = team?.serverExtension, let serverExt = NECommonUtil.getDictionaryFromJSONString(serverJson) as? [String: Any] {
        serverExtension = serverExt
      }

      serverExtension[keyTopMessage] = topMessageDic
      serverExtension["lastOpt"] = keyTopMessage
      TeamRepo.shared.updateTeamExtension(tid, .TEAM_TYPE_NORMAL, NECommonUtil.getJSONStringFromDictionary(serverExtension)) { error in
        print("updateTeamExtension error: \(String(describing: error))")
        completion(error)
      }
    }
  }

  /// 取消置顶消息
  /// - Parameter completion: 回调
  override open func untopMessage(_ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageClientId \(String(describing: topMessage?.messageClientId))")

    guard let _ = topMessage?.messageClientId else {
      let error = NSError(domain: chatLocalizable("failed_operation"), code: failedOperation)
      completion(error)
      return
    }

    let topMessageDic: [String: Any] = [
      "idClient": topMessage?.messageClientId as Any,
      "operator": IMKitClient.instance.account(), // 操作者
      "operation": 1, // 操作: 0 - "add"; 1 - "remove";
    ]

    // 更新群扩展
    TeamRepo.shared.getTeamInfo(sessionId) { [weak self] team, error in
      if let err = error {
        print("getTeamInfo error: \(String(describing: err))")
        completion(err)
        return
      }

      guard let tid = self?.sessionId else { return }

      // 校验权限
      if self?.hasTopMessagePremission() == false {
        let error = NSError(domain: chatLocalizable("no_permission_tip"), code: noPermissionOperationCode)
        completion(error)
        return
      }

      if let serverJson = team?.serverExtension,
         var serverExtension = NECommonUtil.getDictionaryFromJSONString(serverJson) as? [String: Any],
         serverExtension[keyTopMessage] != nil {
        serverExtension[keyTopMessage] = topMessageDic
        serverExtension["lastOpt"] = keyTopMessage

        self?.topMessage = nil
        TeamRepo.shared.updateTeamExtension(tid, .TEAM_TYPE_NORMAL, NECommonUtil.getJSONStringFromDictionary(serverExtension)) { error in
          print("updateTeamExtension error: \(String(describing: error))")
          completion(error)
        }
      }
    }
  }

  open func getTeamInfo(teamId: String,
                        _ completion: @escaping (Error?, V2NIMTeam?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamId: " + teamId)
    if let team = NETeamUserManager.shared.getTeamInfo() {
      self.team = team
      teamMember = NETeamUserManager.shared.getTeamMemberInfo(IMKitClient.instance.account())
      completion(nil, team)
    } else {
      teamRepo.getTeamInfo(teamId) { [weak self] team, error in
        if error == nil {
          self?.team = team
        }
        completion(error, team)
      }
    }
  }

  /// 获取自己的群成员信息
  public func getTeamMember(_ completion: @escaping () -> Void) {
    if let teamMember = NETeamUserManager.shared.getTeamMemberInfo(IMKitClient.instance.account()) {
      self.teamMember = teamMember
      completion()
    } else {
      teamRepo.getTeamMember(sessionId, .TEAM_TYPE_NORMAL, IMKitClient.instance.account()) { [weak self] member, error in
        self?.teamMember = member
        completion()
      }
    }
  }

  /// 重写发送消息已读回执
  /// - Parameters:
  ///   - messages: 需要发送已读回执的消息
  ///   - completion: 完成回调
  override open func markRead(messages: [V2NIMMessage], _ completion: @escaping ((any Error)?) -> Void) {
    markReadInTeam(messages: messages, completion)
  }

  /// 群消息发送已读回执
  /// - Parameters:
  ///   - messages: 需要发送已读回执的消息
  ///   - completion: 完成回调
  private func markReadInTeam(messages: [V2NIMMessage], _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messages.count: \(messages.count)")

    var markMessages = [V2NIMMessage]()
    for message in messages {
      if message.messageServerId != nil, !message.isSelf, message.messageConfig?.readReceiptEnabled == true {
        markMessages.append(message)
      }
    }
    chatRepo.markTeamMessagesRead(messages: markMessages, completion)
  }

  /// 重写获取消息已读未读回执
  /// - Parameters:
  ///   - messages: 消息列表
  ///   - completion: 完成回调
  override open func getMessageReceipts(messages: [V2NIMMessage],
                                        _ completion: @escaping ([IndexPath], Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messages.count: \(messages.count)")
    getTeamMessageReceipts(messages: messages, completion)
  }

  /// 获取群消息已读未读回执
  /// - Parameters:
  ///   - messages: 消息列表
  ///   - completion: 完成回调
  func getTeamMessageReceipts(messages: [V2NIMMessage], _ completion: @escaping ([IndexPath], Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    let sendMessages = messages.filter { msg in
      msg.messageServerId != nil && msg.isSelf && msg.messageType != .MESSAGE_TYPE_NOTIFICATION && msg.messageType != .MESSAGE_TYPE_TIP
    }

    if sendMessages.isEmpty {
      completion([], nil)
      return
    }

    chatRepo.getTeamMessageReceipts(messages: sendMessages) { readReceipts, error in
      var reloadIndexs = [IndexPath]()
      readReceipts?.forEach { readReceipt in
        for (i, model) in self.messages.enumerated() {
          if model.message?.isSelf == false {
            continue
          }

          if model.message?.messageConfig?.readReceiptEnabled == false {
            continue
          }

          if model.message?.messageClientId == readReceipt.messageClientId {
            if model.readCount == readReceipt.readCount,
               model.unreadCount == readReceipt.unreadCount {
              continue
            }

            model.readCount = readReceipt.readCount
            model.unreadCount = readReceipt.unreadCount
            reloadIndexs.append(IndexPath(row: i, section: 0))
          }
        }
      }
      completion(reloadIndexs, error)
    }
  }

  // MARK: - NETeamListener

  public func onTeamDismissed(_ team: V2NIMTeam) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamId: " + (team.teamId))
    if sessionId == team.teamId {
      if let delegate = delegate as? TeamChatViewModelDelegate {
        delegate.onTeamRemoved?(team: team)
      }
    }
  }
}

// MARK: - NETeamChatUserCacheListener

extension TeamChatViewModel: NETeamChatUserCacheListener {
  /// 群信息更新
  /// - Parameter teamId: 群 id
  public func onTeamInfoUpdate(_ teamId: String) {
    guard let team = NETeamUserManager.shared.getTeamInfo(), team.teamId == sessionId else { return }

    self.team = team
    loadTopMessage()

    if let delegate = delegate as? TeamChatViewModelDelegate {
      delegate.onTeamUpdate?(team: team)
    }
  }

  /// 群成员更新
  /// - Parameter accountId: 用户 id
  public func onTeamMemberUpdate(_ accountId: String) {
    guard let teamMember = NETeamUserManager.shared.getTeamMemberInfo(accountId) else { return }

    if self.teamMember == nil || accountId == self.teamMember?.accountId {
      self.teamMember = teamMember
      loadTopMessage()
    }

    updateMessageInfo(accountId)

    if let delegate = delegate as? TeamChatViewModelDelegate {
      delegate.onTeamMemberUpdate?([teamMember])
    }
  }
}

// MARK: - NEIMKitClientListener

extension TeamChatViewModel: NEIMKitClientListener {
  /// 登录连接状态回调
  /// - Parameter status: 连接状态
  public func onDataSync(_ type: V2NIMDataSyncType, state: V2NIMDataSyncState, error: V2NIMError?) {
    // 断网重连后，重新拉取群信息、自己的群成员信息
    if type == .DATA_SYNC_TYPE_TEAM_MEMBER, state == .DATA_SYNC_STATE_COMPLETED {
      getTeamInfo(teamId: sessionId) { [weak self] error, team in
        if error == nil {
          self?.team = team
        }
        self?.getTeamMember {
          self?.loadTopMessage()
        }
      }
    }
  }
}
