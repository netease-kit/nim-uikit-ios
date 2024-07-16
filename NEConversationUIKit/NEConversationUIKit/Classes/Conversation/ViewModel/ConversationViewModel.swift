// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit
import NIMSDK

@objc
public protocol ConversationViewModelDelegate: NSObjectProtocol {
  func reloadData()
  func reloadTableView()
  /// 底部加载更多状态变更
  func loadMoreStateChange(_ finish: Bool)
}

public typealias ConversationCallBack = (NSError?, Bool?) -> Void

@objcMembers
open class ConversationViewModel: NSObject, NEConversationListener, NETeamListener, NEChatListener, NEContactListener, NEIMKitClientListener, AIUserPinListener, AIUserChangeListener {
  public weak var delegate: ConversationViewModelDelegate?
  private let className = "ConversationViewModel"

  /// 会话API单例
  public let conversationRepo = ConversationRepo.shared

  /// 会话列表起始索引
  public var offset: Int64 = 0

  /// 会话列表分页大小
  public var page = 200

  /// 非置顶会话数据
  public var conversationListData = [NEConversationListModel]()

  /// 置顶会话数据
  public var stickTopConversations = [NEConversationListModel]()

  /// AI 数字人列表
  public var aiUserListData = [NEAIUserModel]()

  /// 所有会话数据记录
  public var conversationDic = [String: NEConversationListModel]()

  /// 当前是否在请求会话列表
  private var isRequesting = false

  /// 是否同步完成
  public var syncFinished = false {
    didSet {
      print("syncFinished ", syncFinished)
    }
  }

  /// 回调
  public var callBack: ConversationCallBack?

  override public init() {
    NEALog.infoLog(ModuleName + " " + className, desc: #function)
    super.init()
    NotificationCenter.default.addObserver(self, selector: #selector(atMessageChange), name: Notification.Name(AtMessageChangeNoti), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(deleteConversationNoti), name: NENotificationName.deleteConversationNotificationName, object: nil)
    conversationRepo.addConversationListener(self)
    ChatRepo.shared.addChatListener(self)
    TeamRepo.shared.addTeamListener(self)
    ContactRepo.shared.addContactListener(self)
    IMKitClient.instance.addLoginListener(self)
    NEAIUserPinManager.shared.addPinManagerListener(self)
    NEAIUserManager.shared.addAIUserChangeListener(listener: self)
  }

  deinit {
    NEALog.infoLog(ModuleName + className(), desc: #function)
    NotificationCenter.default.removeObserver(self)
    conversationRepo.removeConversationListener(self)
    ChatRepo.shared.removeChatListener(self)
    TeamRepo.shared.removeTeamListener(self)
    ContactRepo.shared.removeContactListener(self)
    IMKitClient.instance.removeLoginListener(self)
    NEAIUserPinManager.shared.removePinManagerListener(self)
    NEAIUserManager.shared.removeAIUserChangeListener(listener: self)
  }

  func atMessageChange() {
    NEALog.infoLog(className(), desc: "atMessageChange")
    delegate?.reloadTableView()
  }

  func deleteConversationNoti(_ noti: NSNotification) {
    if let conversationId = noti.object as? String {
      weak var weakSelf = self
      conversationRepo.deleteConversation(conversationId) { error in
        NEALog.infoLog(weakSelf?.className() ?? "", desc: #function + " deleteConversationNoti \(error?.localizedDescription ?? "") ")
      }
    }
  }

  open func getAIUserList() {
    NEAIUserManager.shared.getAIUserList()
  }

  /// 分页获取会话列表
  open func getConversationListByPage(_ completion: @escaping (NSError?, Bool?) -> Void) {
    if syncFinished == false {
      callBack = completion
      return
    }

    if isRequesting == true {
      // 防止多次请求造成数据混乱，等上次请求成功后进行下一次
      completion(nil, false)
      return
    }
    isRequesting = true
    print("did getConversationList")
    conversationRepo.getConversationList(offset, page) { [weak self] conversations, offset, finished, error in
      if error == nil {
        if let set = offset {
          // 更新索引
          self?.offset = set
        }
        self?.isRequesting = false
        // 区分置顶消息和非置顶消息
        conversations?.forEach { conversation in
          self?.addOrUpdateConversationData(conversation)
        }
      }
      completion(error, finished)
    }
  }

  /// 添加或者更新会话
  /// - Parameter conversation 会话对象
  open func addOrUpdateConversationData(_ conversation: V2NIMConversation) {
    if let cacheModel = conversationDic[conversation.conversationId] {
      cacheModel.conversation = conversation
    } else {
      let model = NEConversationListModel()
      model.conversation = conversation
      conversationDic[conversation.conversationId] = model
      if conversation.stickTop == true {
        stickTopConversations.insert(model, at: 0)
      } else {
        conversationListData.insert(model, at: 0)
      }
    }
  }

  /// 删除会话
  ///  - Parameter conversation 会话对象
  ///  - Parameter completion 完成回调
  open func deleteConversation(_ conversation: V2NIMConversation, _ completion: @escaping (NSError?) -> Void) {
    conversationRepo.deleteConversation(conversation.conversationId) { error in
      if let err = error {
        completion(err)
      } else {
        // 通知界面刷新
        completion(nil)
      }
    }
  }

  /// 添加置顶
  /// - Parameter conversation 会话对象
  /// - Parameter completion 完成回调
  open func addStickTop(conversation: V2NIMConversation,
                        _ completion: @escaping (NSError?)
                          -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", sessionId:" + conversation.conversationId)
    conversationRepo.setStickTop(conversation.conversationId, true) { error in
      completion(error)
    }
  }

  /// 取消置顶
  /// - Parameter conversation 会话对象
  /// - Parameter completion 完成回调
  open func removeStickTop(conversation: V2NIMConversation,
                           _ completion: @escaping (NSError?)
                             -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", sessionId:" + conversation.conversationId)
    conversationRepo.setStickTop(conversation.conversationId, false) { error in
      completion(error)
    }
  }

  open func onMuteListChanged() {
    delegate?.reloadTableView()
  }

  public func updateUserInfo(_ model: NEConversationListModel, _ user: NEUserWithFriend, _ conversation: V2NIMConversation) {
    model.conversation = conversation
  }

  public func updateTeamInfo(_ model: NEConversationListModel, _ team: V2NIMTeam, _ conversation: V2NIMConversation) {
    model.conversation = conversation
  }

  /// 处理置顶变更逻辑
  public func filterStickTopData(_ conversations: [V2NIMConversation]) {
    // 记录置顶
    var changeTostickTopSet = Set<String>()
    // 记录移除置顶
    var changeToUnStickTopDic = Set<String>()
    for conversation in conversations {
      if let model = conversationDic[conversation.conversationId] {
        if model.conversation?.stickTop != conversation.stickTop {
          if conversation.stickTop == true {
            changeTostickTopSet.insert(conversation.conversationId)
          } else {
            changeToUnStickTopDic.insert(conversation.conversationId)
          }
        }
        model.conversation = conversation
      }
    }

    conversationListData.removeAll { model in
      if let cid = model.conversation?.conversationId {
        if changeTostickTopSet.contains(cid) {
          stickTopConversations.insert(model, at: 0)
          return true
        }
      }
      return false
    }

    stickTopConversations.removeAll { model in
      if let cid = model.conversation?.conversationId {
        if changeToUnStickTopDic.contains(cid) {
          conversationListData.append(model)
          return true
        }
      }
      return false
    }
  }

  // 创建会话回调
  public func onConversationCreated(_ conversation: V2NIMConversation) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", did add session targetId:" + conversation.conversationId)
    if checkDismissTeamNoti(conversation) {
      return
    }

    addOrUpdateConversationData(conversation)
    delegate?.reloadTableView()
  }

  /// 会话变更
  /// - Parameter conversations 会话列表
  public func onConversationChanged(_ conversations: [V2NIMConversation]) {
    // 置顶逻辑处理
    filterStickTopData(conversations)

    for conversation in conversations {
      if let manager = NEAtMessageManager.instance {
        if conversation.unreadCount == 0, manager.isAtCurrentUser(conversationId: conversation.conversationId) {
          NEAtMessageManager.instance?.clearAtRecord(conversation.conversationId)
        }
      }

      if checkDismissTeamNoti(conversation) {
        continue
      }
      addOrUpdateConversationData(conversation)
    }

    delegate?.reloadTableView()
  }

  /// 会话删除
  /// - Parameter conversationIds: 会话id列表
  public func onConversationDeleted(_ conversationIds: [String]) {
    var removeFlagSet = Set<String>()
    for id in conversationIds {
      removeFlagSet.insert(id)
      conversationDic.removeValue(forKey: id)
    }
    stickTopConversations.removeAll(where: {
      if let sid = $0.conversation?.conversationId, removeFlagSet.contains(sid) {
        return true
      }
      return false
    })
    conversationListData.removeAll(where: {
      if let sid = $0.conversation?.conversationId, removeFlagSet.contains(sid) {
        return true
      }
      return false
    })
    delegate?.reloadTableView()
  }

  /// 检查会话是否包含解散通知的变更
  /// - Parameter conversation: 会话
  public func checkDismissTeamNoti(_ conversation: V2NIMConversation) -> Bool {
    if IMKitConfigCenter.shared.enabledismissTeamDeleteConversation == false {
      return false
    }

    if conversation.type != V2NIMConversationType.CONVERSATION_TYPE_TEAM {
      return false
    }
    // 解散、退出群聊
    let targetId = conversation.conversationId

    if conversation.lastMessage?.messageType == V2NIMMessageType.MESSAGE_TYPE_NOTIFICATION {
      if let content = conversation.lastMessage?.attachment as? V2NIMMessageNotificationAttachment {
        if content.type == V2NIMMessageNotificationType.MESSAGE_NOTIFICATION_TYPE_TEAM_DISMISS ||
          (content.type == V2NIMMessageNotificationType.MESSAGE_NOTIFICATION_TYPE_TEAM_KICK &&
            content.targetIds?.contains(IMKitClient.instance.account()) == true) ||
          (content.type == V2NIMMessageNotificationType.MESSAGE_NOTIFICATION_TYPE_TEAM_LEAVE &&
            IMKitClient.instance.isMe(conversation.lastMessage?.messageRefer.senderId)) {
          // 群聊被解散
          // 被踢出群聊
          // 主动退出群聊
          NEALog.infoLog(
            ModuleName + " " + className,
            desc: #function + "didAdd team dismiss or leave noti " + targetId
          )
          conversationRepo.deleteConversation(targetId) { error in
          }

          // 移除置顶
          conversationDic.removeValue(forKey: targetId)
          stickTopConversations.removeAll { model in
            if model.conversation?.conversationId == targetId {
              return true
            }
            return false
          }
          delegate?.reloadTableView()
          return true
        }
      }
    }
    return false
  }

  /// 保存撤回消息
  /// - Parameter conversationId: 会话id
  /// - Parameter createTime: 撤回时间
  /// - Parameter revokeAccountId: 撤回人id
  /// - Parameter extention: 扩展信息
  /// - Parameter completion: 完成回调
  open func saveRevokeMessage(_ messageRevoke: V2NIMMessageRevokeNotification,
                              _ completion: @escaping (NSError?) -> Void) {
    let messageNew = V2NIMMessageCreator.createTextMessage(localizable("message_recalled"))
    messageNew.messageConfig?.unreadEnabled = true

    if let ext = messageRevoke.serverExtension {
      messageNew.localExtension = ext
    } else {
      var muta = [String: Any]()
      muta[revokeLocalMessage] = true
      messageNew.localExtension = NECommonUtil.getJSONStringFromDictionary(muta)
    }

    ChatRepo.shared.insertMessageToLocal(message: messageNew,
                                         conversationId: messageRevoke.messageRefer?.conversationId ?? "",
                                         senderId: messageRevoke.revokeAccountId,
                                         createTime: messageRevoke.messageRefer?.createTime) { _, error in
      completion(error)
    }
  }

  /// 撤回通知监听
  /// - Parameter revokeNotifications: 撤回通知列表
  public func onMessageRevokeNotifications(_ revokeNotifications: [V2NIMMessageRevokeNotification]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + "onMessageRevokeNotifications ids: \(revokeNotifications.map { $0.messageRefer?.messageServerId })")

    for messageRevoke in revokeNotifications {
      guard let msgServerId = messageRevoke.messageRefer?.messageServerId else {
        return
      }

      // 防止重复插入本地撤回消息
      if ConversationDeduplicationHelper.instance.isRevokeMessageSaved(messageId: msgServerId) {
        return
      }

      saveRevokeMessage(messageRevoke) { error in
        if let err = error {
          NEALog.infoLog(ModuleName + " " + ConversationViewModel.className(), desc: "saveRevokeMessage error \(err)")
        }
      }
    }
  }

  /// 收到点对点已读回执
  /// - Parameter readReceipts: 已读回执
  public func onReceiveP2PMessageReadReceipts(_ readReceipts: [V2NIMP2PMessageReadReceipt]) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + "onReceive p2p readReceipts count: \(readReceipts.count)")
    for receipt in readReceipts {
      if let cid = receipt.conversationId {
        if conversationDic[cid] != nil {
          delegate?.reloadTableView()
          break
        }
      }
    }
  }

  /// 加入群回调
  /// - Parameter team: 群信息
  public func onTeamJoined(_ team: V2NIMTeam) {}

  /// 建群回调
  /// - Parameter team: 群信息
  public func onTeamCreated(_ team: V2NIMTeam) {}

  public func onTeamLeft(_ team: V2NIMTeam, isKicked: Bool) {
    NEALog.infoLog(className(), desc: "conversation onTeamLeft team id: \(team.teamId) team name : \(team.name) isKicked : \(isKicked)")
    if let cid = V2NIMConversationIdUtil.teamConversationId(team.teamId) {
      didDeleteConversation(cid)
    }
  }

  /// 群解散回调
  /// - Parameter team: 群信息
  public func onTeamDismissed(_ team: V2NIMTeam) {
    NEALog.infoLog(className(), desc: "onTeamDismissed team id : \(team.teamId) team name: \(team.name)")
    if IMKitConfigCenter.shared.enabledismissTeamDeleteConversation {
      if let cid = V2NIMConversationIdUtil.teamConversationId(team.teamId) {
        didDeleteConversation(cid)
      }
    }
  }

  private func didDeleteConversation(_ cid: String) {
    if IMKitConfigCenter.shared.enabledismissTeamDeleteConversation == false {
      return
    }
    conversationRepo.deleteConversation(cid) { [weak self] error in
      if let err = error {
        NEALog.infoLog(self?.className() ?? " ", desc: "onTeamDismissed delete conversation error : \(err.localizedDescription)")
      } else {
        self?.conversationDic.removeValue(forKey: cid)
        self?.stickTopConversations.removeAll { model in
          if model.conversation?.conversationId == cid {
            return true
          }
          return false
        }
        self?.conversationListData.removeAll { model in
          if model.conversation?.conversationId == cid {
            return true
          }
          return false
        }
        self?.delegate?.reloadTableView()
      }
    }
  }

  public func onConversationSyncFinished() {
    NEALog.infoLog(className(), desc: "onConversationSyncFinished")
    delegate?.reloadTableView()
  }

  public func onDataSync(_ type: V2NIMDataSyncType, state: V2NIMDataSyncState, error: V2NIMError?) {
    if type == .DATA_SYNC_TYPE_MAIN, state == .DATA_SYNC_STATE_COMPLETED {
      /// 设置同步完成标识
      syncFinished = true

      if let completion = callBack {
        NEALog.infoLog(className(), desc: "onConversationSyncFinished getConversationListByPage")
        /// 取数据
        getConversationListByPage(completion)
        /// 回调置空
        callBack = nil

      } else {
        NEALog.infoLog(className(), desc: #function + " retrieveConversationDatas")
        retrieveConversationDatas()
      }
    }
  }

  /// 发生重连的情况重新获取数据
  public func retrieveConversationDatas() {
    var limit = 0
    if conversationDic.count > page {
      limit = conversationDic.count
    } else {
      limit = page
    }
    conversationRepo.getConversationList(0, limit) { [weak self] conversations, offset, finished, error in
      if error == nil {
        if let set = offset {
          // 更新索引
          self?.offset = set
        }
        // 清理之前数据
        self?.stickTopConversations.removeAll()
        self?.conversationListData.removeAll()
        self?.conversationDic.removeAll()
        // 区分置顶消息和非置顶消息
        conversations?.forEach { conversation in
          self?.addOrUpdateConversationData(conversation)
        }
        self?.delegate?.reloadTableView()
        if let complete = finished {
          self?.delegate?.loadMoreStateChange(complete)
        }
      }
    }
  }

  public func onFriendDeleted(_ accountId: String, deletionType: V2NIMFriendDeletionType) {
    delegate?.reloadTableView()
  }

  public func onTeamSyncFinished() {
    delegate?.reloadTableView()
  }

  public func onConversationSyncFailed(_ error: V2NIMError) {
    NEALog.infoLog(className(), desc: "onConversationSyncFailed : \(error.desc)")
  }

  /// 好友信息缓存更新
  /// - Parameter accountId: 用户 id
  public func onFriendInfoChanged(_ friendInfo: V2NIMFriend) {
    NEALog.infoLog(className(), desc: "onFriendInfoUpdate : \(String(describing: friendInfo.accountId))")
    delegate?.reloadTableView()
  }

  // MARK: Pin Manager Listener

  public func userInfoDidChange() {
    NEALog.infoLog(className(), desc: #function + "" + "conversaion view model userInfoDidChange")
    getAIUserList()
  }

  public func onAIUserChanged(aiUsers: [V2NIMAIUser]) {
    aiUserListData.removeAll()
    weak var weakSelf = self
    for aiUser in aiUsers {
      if NEAIUserPinManager.shared.checkoutUnPinAIUser(aiUser) == true {
        let model = NEAIUserModel()
        model.aiUser = aiUser
        weakSelf?.aiUserListData.append(model)
      }
    }
    delegate?.reloadTableView()
  }
}
