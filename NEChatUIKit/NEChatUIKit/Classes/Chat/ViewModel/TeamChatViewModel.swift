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
open class TeamChatViewModel: ChatViewModel, NETeamListener, NEContactListener {
  public let teamRepo = TeamRepo.shared
  public var team: V2NIMTeam?
  /// 当前成员的群成员对象类
  public var teamMember: V2NIMTeamMember?

  override init(conversationId: String) {
    super.init(conversationId: conversationId)
    teamRepo.addTeamListener(self)
    contactRepo.addContactListener(self)
  }

  override init(conversationId: String, anchor: V2NIMMessage?) {
    super.init(conversationId: conversationId, anchor: anchor)
    teamRepo.addTeamListener(self)
    contactRepo.addContactListener(self)
    getTeamMember {}
  }

  /// 重写 获取用户展示名称
  /// - Parameters:
  ///   - accountId: 用户 accountId
  ///   - showAlias: 是否展示备注
  /// - Returns: 名称和好友信息
  override open func getShowName(_ accountId: String, _ showAlias: Bool = true) -> (name: String, user: NEUserWithFriend?) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", accountId:" + accountId)
    return ChatTeamCache.shared.getShowName(accountId, showAlias)
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
    guard let teamId = teamId else {
      return
    }

    ChatTeamCache.shared.loadShowName(userIds: accountIds, teamId: teamId, completion)
  }

  open func getTeamInfo(teamId: String,
                        _ completion: @escaping (Error?, V2NIMTeam?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamId: " + teamId)
    teamRepo.getTeamInfo(teamId) { [weak self] team, error in
      if error == nil {
        self?.team = team
      }
      completion(error, team)
    }
  }

  open func getTeamMemberInfo(teamId: String,
                              _ completion: @escaping (Error?, NETeamInfoModel?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamId: " + teamId)
    teamRepo.getTeamWithMembers(teamId,
                                .TEAM_MEMBER_ROLE_QUERY_TYPE_ALL) { [weak self] error, teamInfoModel in
      if error == nil {
        self?.team = teamInfoModel?.team
      }
      completion(error, teamInfoModel)
    }
  }

  /// 获取自己的群成员信息
  public func getTeamMember(_ completion: @escaping () -> Void) {
    teamRepo.getTeamMember(sessionId, IMKitClient.instance.account()) { [weak self] member, error in
      self?.teamMember = member
      completion()
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
    chatRepo.markTeamMessageRead(messages: markMessages, completion)
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

  // MARK: - NEContactListener

  /// 用户信息变更回调
  /// - Parameter users: 用户列表
  public func onUserProfileChanged(_ users: [V2NIMUser]) {
    for item in users {
      let userFriend = NEUserWithFriend(user: item)
      ChatTeamCache.shared.updateTeamMemberInfo(userFriend)
      updateMessageInfo(item.accountId)
    }
  }

  /// 好友信息变更回调
  /// - Parameter friendInfo: 好友信息
  public func onFriendInfoChanged(_ friendInfo: V2NIMFriend) {
    let userFriend = NEUserWithFriend(friend: friendInfo)
    ChatTeamCache.shared.updateTeamMemberInfo(userFriend)
    updateMessageInfo(friendInfo.accountId)
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

  public func onTeamInfoUpdated(_ team: V2NIMTeam) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamId: " + (team.teamId))
    if sessionId == team.teamId {
      self.team = team
      if let delegate = delegate as? TeamChatViewModelDelegate {
        delegate.onTeamUpdate?(team: team)
      }
    }
  }

  /// 群成员加入回调
  /// - Parameter teamMembers: 群成员列表
  public func onTeamMemberJoined(_ teamMembers: [V2NIMTeamMember]) {
    for teamMember in teamMembers {
      guard teamMember.teamId == team?.teamId else { break }

      ChatTeamCache.shared.updateTeamMemberInfo(teamMember)
      updateMessageInfo(teamMember.accountId)
    }
  }

  public func onTeamMemberInfoUpdated(_ teamMembers: [V2NIMTeamMember]) {
    for teamMember in teamMembers {
      guard teamMember.teamId == team?.teamId else { break }

      if teamMember.accountId == self.teamMember?.accountId {
        self.teamMember = teamMember
      }

      ChatTeamCache.shared.updateTeamMemberInfo(teamMember)
      updateMessageInfo(teamMember.accountId)
    }

    if let delegate = delegate as? TeamChatViewModelDelegate {
      delegate.onTeamMemberUpdate?(teamMembers)
    }
  }
}
