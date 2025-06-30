// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit
import NIMSDK

@objc
public protocol LocalConversationViewModelDelegate: NSObjectProtocol {
  func reloadData()
  func reloadTableView()
  /// 底部加载更多状态变更
  func loadMoreStateChange(_ finish: Bool)
}

public typealias LocalConversationCallBack = (NSError?, Bool?) -> Void

@objcMembers
open class LocalConversationViewModel: NSObject, NELocalConversationListener, NETeamListener, NEChatListener, NEContactListener, NEIMKitClientListener, AIUserPinListener, AIUserChangeListener {
  public weak var delegate: LocalConversationViewModelDelegate?
  private let className = "LocalConversationViewModel"
  private var networkBroken = false // 网络断开标志

  /// 会话API单例
  public let conversationRepo = LocalConversationRepo.shared

  /// 会话列表起始索引
  public var offset: Int = 0

  /// 会话列表分页大小
  public var page = 100

  /// 非置顶会话数据
  public var conversationListData = [NELocalConversationListModel]()

  /// 置顶会话数据
  public var stickTopConversations = [NELocalConversationListModel]()

  /// AI 数字人列表
  public var aiUserListData = [NEAIUserModel]()

  /// 所有会话数据记录
  public var conversationDic = [String: NELocalConversationListModel]()

  /// 当前是否在请求会话列表
  private var isRequesting = false

  /// 是否同步完成
  public var syncFinished = false {
    didSet {
      print("syncFinished ", syncFinished)
    }
  }

  /// 回调
  public var callBack: LocalConversationCallBack?

  /// 单聊账号 id
  var p2pAccountIds = Set<String>()

  /// （单聊会话）在线状态记录，[单聊会话 id: 是否在线]
  public var onlineStatusDic = [String: Bool]()

  override public init() {
    NEALog.infoLog(ModuleName + " " + className, desc: #function)
    super.init()
    NotificationCenter.default.addObserver(self, selector: #selector(atMessageChange), name: Notification.Name(AtMessageChangeNoti), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(deleteConversationNoti), name: NENotificationName.deleteConversationNotificationName, object: nil)
    conversationRepo.addLocalConversationListener(self)
    ChatRepo.shared.addChatListener(self)
    TeamRepo.shared.addTeamListener(self)
    ContactRepo.shared.addContactListener(self)
    IMKitClient.instance.addLoginListener(self)
    NEAIUserPinManager.shared.addPinManagerListener(self)
    NEAIUserManager.shared.addAIUserChangeListener(listener: self)
    if IMKitConfigCenter.shared.enableOnlineStatus {
      SubscribeRepo.shared.addListener(self)
    }
  }

  deinit {
    NEALog.infoLog(ModuleName + className(), desc: #function)
    NotificationCenter.default.removeObserver(self)
    conversationRepo.removeLocalConversationListener(self)
    ChatRepo.shared.removeChatListener(self)
    TeamRepo.shared.removeTeamListener(self)
    ContactRepo.shared.removeContactListener(self)
    IMKitClient.instance.removeLoginListener(self)
    NEAIUserPinManager.shared.removePinManagerListener(self)
    NEAIUserManager.shared.removeAIUserChangeListener(listener: self)
    if IMKitConfigCenter.shared.enableOnlineStatus {
      SubscribeRepo.shared.removeListener(self)
    }
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
    if IMKitConfigCenter.shared.enableAIUser,
       NEAIUserManager.shared.isAIUserListEmpty() {
      NEAIUserManager.shared.getAIUserList()
    }
  }

  /// 分页获取会话列表
  open func getConversationListByPage(_ completion: @escaping (NSError?, Bool?) -> Void) {
    if syncFinished == false {
      callBack = completion
    }

    if isRequesting == true {
      // 防止多次请求造成数据混乱，等上次请求成功后进行下一次
      completion(nil, false)
      return
    }

    isRequesting = true

    NEALog.infoLog(className() + " [Performance]", desc: #function + " start, syncFinished:\(syncFinished), timestamp: \(Date().timeIntervalSince1970)")
    conversationRepo.getConversationList(offset, page) { [weak self] conversations, offset, finished, error in
      NEALog.infoLog((self?.className() ?? "") + " [Performance]", desc: #function + " onSuccess, syncFinished:\(self?.syncFinished ?? false), count: \(conversations?.count ?? 0), timestamp: \(Date().timeIntervalSince1970)")
      if error == nil {
        if let set = offset {
          // 更新索引
          self?.offset = set
        }
        self?.isRequesting = false

        conversations?.forEach { conversation in
          // 区分置顶消息和非置顶消息
          self?.addOrUpdateConversationData(conversation)

          if V2NIMConversationIdUtil.conversationType(conversation.conversationId) == .CONVERSATION_TYPE_P2P,
             let accountId = V2NIMConversationIdUtil.conversationTargetId(conversation.conversationId) {
            self?.p2pAccountIds.insert(accountId)
          }
        }

        // 订阅单聊在线状态
        if IMKitConfigCenter.shared.enableOnlineStatus,
           let accountIds = self?.p2pAccountIds {
          self?.subscribeOnlineStatus(Array(accountIds))
        }

        // 单聊会话主动拉取用户信息，避免用户信息缺失影响会话展示
        if let p2pAccountIds = self?.p2pAccountIds, !p2pAccountIds.isEmpty {
          ContactRepo.shared.getUserListFromCloud(accountIds: Array(p2pAccountIds)) { [weak self] users, error in
            let conversationIds = p2pAccountIds.compactMap { V2NIMConversationIdUtil.p2pConversationId($0) }
            self?.conversationRepo.getConversationListByIds(conversationIds) { conversations, error in
              if let conversations = conversations {
                for conversation in conversations {
                  self?.conversationDic[conversation.conversationId]?.conversation = conversation
                }
                self?.delegate?.reloadTableView()
              }
            }
          }
        }
        self?.delegate?.reloadTableView()
      }
      completion(error, finished)
    }
  }

  /// 添加或者更新会话
  /// - Parameter conversation 会话对象
  open func addOrUpdateConversationData(_ conversation: V2NIMLocalConversation) {
    if let cacheModel = conversationDic[conversation.conversationId] {
      cacheModel.conversation = conversation
    } else {
      let model = NELocalConversationListModel()
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
  open func deleteConversation(_ conversation: V2NIMLocalConversation, _ completion: @escaping (NSError?) -> Void) {
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
  open func addStickTop(conversation: V2NIMLocalConversation,
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
  open func removeStickTop(conversation: V2NIMLocalConversation,
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

  open func updateUserInfo(_ model: NELocalConversationListModel, _ user: NEUserWithFriend, _ conversation: V2NIMLocalConversation) {
    model.conversation = conversation
  }

  open func updateTeamInfo(_ model: NELocalConversationListModel, _ team: V2NIMTeam, _ conversation: V2NIMLocalConversation) {
    model.conversation = conversation
  }

  /// 处理置顶变更逻辑
  open func filterStickTopData(_ conversations: [V2NIMLocalConversation]) {
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
  open func onLocalConversationCreated(_ conversation: V2NIMLocalConversation) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", did add session targetId:" + conversation.conversationId)
    if checkDismissTeamNoti(conversation) {
      return
    }

    addOrUpdateConversationData(conversation)

    // 订阅单聊在线状态
    if IMKitConfigCenter.shared.enableOnlineStatus,
       let accountId = V2NIMConversationIdUtil.conversationTargetId(conversation.conversationId) {
      p2pAccountIds.insert(accountId)
      subscribeOnlineStatus([accountId])
    }

    delegate?.reloadTableView()
  }

  /// 会话变更
  /// - Parameter conversations 会话列表
  open func onLocalConversationChanged(_ conversations: [V2NIMLocalConversation]) {
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
  open func onLocalConversationDeleted(_ conversationIds: [String]) {
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
  open func checkDismissTeamNoti(_ conversation: V2NIMLocalConversation) -> Bool {
    if IMKitConfigCenter.shared.enableDismissTeamDeleteConversation == false {
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
  /// - Parameter messageRevoke: 撤回通知
  /// - Parameter completion: 完成回调
  open func saveRevokeMessage(_ messageRevoke: V2NIMMessageRevokeNotification,
                              _ completion: @escaping (NSError?) -> Void) {
    let messageNew = V2NIMMessageCreator.createTextMessage(localizable("message_recalled"))
    messageNew.messageConfig?.unreadEnabled = false

    var muta = [String: Any]()
    if let ext = NECommonUtil.getDictionaryFromJSONString(messageRevoke.serverExtension ?? "") as? [String: Any] {
      muta = ext
    }
    muta[revokeLocalMessage] = true
    messageNew.serverExtension = NECommonUtil.getJSONStringFromDictionary(muta)

    ChatRepo.shared.insertMessageToLocal(message: messageNew,
                                         conversationId: messageRevoke.messageRefer?.conversationId ?? "",
                                         senderId: messageRevoke.revokeAccountId,
                                         createTime: messageRevoke.messageRefer?.createTime) { _, error in
      completion(error)
    }
  }

  /// 撤回通知监听
  /// - Parameter revokeNotifications: 撤回通知列表
  open func onMessageRevokeNotifications(_ revokeNotifications: [V2NIMMessageRevokeNotification]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + "onMessageRevokeNotifications ids: \(revokeNotifications.map { $0.messageRefer?.messageServerId })")

    for messageRevoke in revokeNotifications {
      guard let msgServerId = messageRevoke.messageRefer?.messageServerId else {
        return
      }

      // 防止重复插入本地撤回消息
      if LocalConversationDeduplicationHelper.instance.isRevokeMessageSaved(messageId: msgServerId) {
        return
      }

      saveRevokeMessage(messageRevoke) { error in
        if let err = error {
          NEALog.infoLog(ModuleName + " " + LocalConversationViewModel.className(), desc: "saveRevokeMessage error \(err)")
        }
      }
    }
  }

  /// 收到点对点已读回执
  /// - Parameter readReceipts: 已读回执
  open func onReceiveP2PMessageReadReceipts(_ readReceipts: [V2NIMP2PMessageReadReceipt]) {
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
  open func onTeamJoined(_ team: V2NIMTeam) {}

  /// 建群回调
  /// - Parameter team: 群信息
  open func onTeamCreated(_ team: V2NIMTeam) {}

  open func onTeamLeft(_ team: V2NIMTeam, isKicked: Bool) {
    NEALog.infoLog(className(), desc: "conversation onTeamLeft team id: \(team.teamId) team name : \(team.name) isKicked : \(isKicked)")
    if let cid = V2NIMConversationIdUtil.teamConversationId(team.teamId) {
      didDeleteConversation(cid)
    }
  }

  /// 群解散回调
  /// - Parameter team: 群信息
  open func onTeamDismissed(_ team: V2NIMTeam) {
    NEALog.infoLog(className(), desc: "onTeamDismissed team id : \(team.teamId) team name: \(team.name)")
    if IMKitConfigCenter.shared.enableDismissTeamDeleteConversation {
      if let cid = V2NIMConversationIdUtil.teamConversationId(team.teamId) {
        didDeleteConversation(cid)
      }
    }
  }

  private func didDeleteConversation(_ cid: String) {
    if IMKitConfigCenter.shared.enableDismissTeamDeleteConversation == false {
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

  open func onLocalConversationSyncFinished() {
    NEALog.infoLog(className() + "[Performance]", desc: #function + " timestamp: \(Date().timeIntervalSince1970)")
    /// 设置同步完成标识
    syncFinished = true

    if let completion = callBack {
      NEALog.infoLog(className() + "[Performance]", desc: #function + " getConversationListByPage again")
      /// 取数据

      getConversationListByPage(completion)
      /// 回调置空
      callBack = nil
    }
  }

  /// 登录连接状态回调
  /// - Parameter status: 连接状态
  open func onConnectStatus(_ status: V2NIMConnectStatus) {
    if status == .CONNECT_STATUS_WAITING {
      networkBroken = true
    }

    if status == .CONNECT_STATUS_CONNECTED, networkBroken {
      networkBroken = false
      DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: DispatchWorkItem(block: { [weak self] in
        // 断网重连后不会重发标记回调，需要手动拉取
        if self?.callBack == nil {
          NEALog.infoLog(self?.className() ?? "", desc: #function + " retrieveConversationDatas")
          self?.retrieveConversationDatas()
        }
      }))
    }
  }

  /// 发生重连的情况重新获取数据
  open func retrieveConversationDatas() {
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

  open func onFriendDeleted(_ accountId: String, deletionType: V2NIMFriendDeletionType) {
    delegate?.reloadTableView()
  }

  open func onTeamSyncFinished() {
    delegate?.reloadTableView()
  }

  open func onLocalConversationSyncFailed(_ error: V2NIMError) {
    NEALog.infoLog(className(), desc: "onLocalConversationSyncFailed : \(error.desc)")
  }

  /// 好友信息缓存更新
  /// - Parameter friendInfo: 好友信息
  open func onFriendInfoChanged(_ friendInfo: V2NIMFriend) {
    NEALog.infoLog(className(), desc: "onFriendInfoUpdate : \(String(describing: friendInfo.accountId))")
    delegate?.reloadTableView()
  }

  // MARK: Pin Manager Listener

  open func userInfoDidChange() {
    NEALog.infoLog(className(), desc: #function + "" + "conversaion view model userInfoDidChange")
    getAIUserList()
  }

  open func onAIUserChanged(aiUsers: [V2NIMAIUser]) {
    if !IMKitConfigCenter.shared.enableAIUser {
      return
    }

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

// MARK: - NEEventListener

extension LocalConversationViewModel: NESubscribeListener {
  /// 订阅在线状态
  open func subscribeOnlineStatus(_ accoundIds: [String]) {
    var subscribeList: [String] = []
    for accountId in accoundIds {
      if NEAIUserManager.shared.isAIUser(accountId) {
        continue
      }

      if let event = NESubscribeManager.shared.getSubscribeStatus(accountId),
         let conversationId = V2NIMConversationIdUtil.p2pConversationId(accountId) {
        onlineStatusDic[conversationId] = event.statusType == .USER_STATUS_TYPE_LOGIN
      } else {
        subscribeList.append(accountId)
      }
    }

    if !subscribeList.isEmpty {
      NESubscribeManager.shared.subscribeUsersOnlineState(subscribeList) { error in
      }
    }
  }

  /// 取消订阅
  open func unsubscribeOnlineStatus() {
    let subscribeList = Array(p2pAccountIds)
    NESubscribeManager.shared.unSubscribeUsersOnlineState(subscribeList) { error in
    }
  }

  /// 用户状态变更
  /// - Parameter data: 用户状态列表
  public func onUserStatusChanged(_ data: [V2NIMUserStatus]) {
    var needRefresh = false
    for d in data {
      if p2pAccountIds.contains(d.accountId),
         let conversationId = V2NIMConversationIdUtil.p2pConversationId(d.accountId) {
        onlineStatusDic[conversationId] = d.statusType == .USER_STATUS_TYPE_LOGIN
        needRefresh = true
      }
    }

    if needRefresh {
      delegate?.reloadTableView()
    }
  }
}
