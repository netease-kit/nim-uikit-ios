// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
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
  public var page = 50

  /// 会话数据列表
  public var conversationListData = [NELocalConversationListModel]()

  /// AI 数字人列表
  public var aiUserListData = [NEAIUserModel]()

  /// 所有会话数据记录
  public var conversationDic = [String: NELocalConversationListModel]()

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
    NotificationCenter.default.addObserver(self, selector: #selector(atMessageChange), name: Notification.Name(localAtMessageChangeNoti), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(deleteConversationNoti), name: NENotificationName.deleteConversationNotificationName, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(robotDidRemove), name: NEAIRobotManager.robotDidRemoveNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(robotDisplayInfoDidChange), name: NEAIRobotManager.robotDisplayInfoDidChangeNotification, object: nil)
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
      conversationRepo.deleteConversation(conversationId) { error in
        NEALog.infoLog(LocalConversationViewModel.className(), desc: #function + " deleteConversationNoti \(error?.localizedDescription ?? "") ")
      }
    }
  }

  @objc
  private func robotDidRemove(_ notification: Notification) {
    guard let accountId = notification.object as? String,
          let conversationId = V2NIMConversationIdUtil.p2pConversationId(accountId) else {
      return
    }
    DispatchQueue.main.async { [weak self] in
      guard let self, self.conversationDic[conversationId] != nil else {
        return
      }
      self.delegate?.reloadTableView()
    }
  }

  @objc
  private func robotDisplayInfoDidChange(_ notification: Notification) {
    guard let accountIds = notification.object as? [String] else { return }
    executeOnMain { [weak self] in
      guard let self, accountIds.contains(where: { accountId in
        guard let conversationId = V2NIMConversationIdUtil.p2pConversationId(accountId) else { return false }
        return self.conversationDic[conversationId] != nil
      }) else { return }
      self.delegate?.reloadTableView()
    }
  }

  open func getAIUserList() {
    if IMKitConfigCenter.shared.enableAIUser {
      NEAIUserManager.shared.getAIUserList()
    }
  }

  private func executeOnMain(_ work: @escaping () -> Void) {
    if Thread.isMainThread {
      work()
    } else {
      DispatchQueue.main.async(execute: work)
    }
  }

  /// 分页获取会话列表
  open func getConversationListByPage(_ completion: @escaping (NSError?, Bool?) -> Void) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async { [weak self] in
        self?.getConversationListByPage(completion)
      }
      return
    }

    if syncFinished == false {
      callBack = completion
    }

    NEALog.infoLog(className() + " [Performance]", desc: #function + " start, syncFinished:\(syncFinished), timestamp: \(Date().timeIntervalSince1970)")
    conversationRepo.getConversationList(offset, page) { [weak self] conversations, offset, finished, error in
      NEALog.infoLog((LocalConversationViewModel.className()) + " [Performance]", desc: #function + " onSuccess, syncFinished:\(self?.syncFinished ?? false), count: \(conversations?.count ?? 0), timestamp: \(Date().timeIntervalSince1970)")
      guard let self else {
        completion(error, finished)
        return
      }

      DispatchQueue.main.async {
        guard error == nil else {
          completion(error, finished)
          return
        }

        if let set = offset {
          // 更新索引
          self.offset = set
        }

        let pageConversations = conversations ?? []
        pageConversations.forEach { conversation in
          self.mergeConversationData(conversation)

          if V2NIMConversationIdUtil.conversationType(conversation.conversationId) == .CONVERSATION_TYPE_P2P,
             let accountId = V2NIMConversationIdUtil.conversationTargetId(conversation.conversationId) {
            self.p2pAccountIds.insert(accountId)
          }
        }

        // 订阅单聊在线状态
        if IMKitConfigCenter.shared.enableOnlineStatus {
          self.subscribeOnlineStatus(Array(self.p2pAccountIds))
        }

        self.delegate?.reloadTableView()
        completion(error, finished)

        // 单聊会话主动拉取用户信息，避免用户信息缺失影响会话展示。
        let p2pAccountIds = self.p2pAccountIds
        DispatchQueue.global().async { [weak self] in
          guard let self, !p2pAccountIds.isEmpty else { return }
          ContactRepo.shared.getUserListFromCloud(accountIds: Array(p2pAccountIds)) { [weak self] _, _ in
            guard let self else { return }
            let conversationIds = p2pAccountIds.compactMap { V2NIMConversationIdUtil.p2pConversationId($0) }
            self.conversationRepo.getConversationListByIds(conversationIds) { [weak self] conversations, _ in
              guard let self, let conversations else { return }
              DispatchQueue.main.async {
                conversations.forEach { self.mergeConversationData($0) }
                self.delegate?.reloadTableView()
              }
            }
          }
        }
      }
    }
  }

  /// 添加或者更新会话
  /// - Parameter conversation 会话对象
  open func addOrUpdateConversationData(_ conversation: V2NIMLocalConversation,
                                        _ isAdd: Bool = false) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async { [weak self] in
        self?.addOrUpdateConversationData(conversation, isAdd)
      }
      return
    }
    mergeConversationData(conversation)
  }

  private func mergeConversationData(_ conversation: V2NIMLocalConversation) {
    if let cacheModel = conversationDic[conversation.conversationId] {
      cacheModel.conversation = conversation

      conversationListData.removeAll(where: {
        if let sid = $0.conversation?.conversationId, sid == conversation.conversationId {
          return true
        }
        return false
      })

      compareToInsert(cacheModel)
    } else {
      let model = NELocalConversationListModel()
      model.conversation = conversation
      conversationDic[conversation.conversationId] = model
      compareToInsert(model)
    }
  }

  /// 插入会话
  /// - Parameter cacheModel: 会话模型
  open func compareToInsert(_ cacheModel: NELocalConversationListModel) {
    for (index, model) in conversationListData.enumerated() {
      if shouldInsert(cacheModel, before: model) {
        conversationListData.insert(cacheModel, at: index)
        return
      }
    }

    conversationListData.append(cacheModel)
  }

  @nonobjc
  private func shouldInsert(_ lhsModel: NELocalConversationListModel,
                            before rhsModel: NELocalConversationListModel) -> Bool {
    return (lhsModel.conversation?.sortOrder ?? 0) > (rhsModel.conversation?.sortOrder ?? 0)
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
    addOrUpdateConversationData(conversation)
  }

  open func updateTeamInfo(_ model: NELocalConversationListModel, _ team: V2NIMTeam, _ conversation: V2NIMLocalConversation) {
    addOrUpdateConversationData(conversation)
  }

  // 创建会话回调
  open func onLocalConversationCreated(_ conversation: V2NIMLocalConversation) {
    executeOnMain { [weak self] in
      guard let self else { return }
      NEALog.infoLog(ModuleName + " " + self.className, desc: #function + ", did add session targetId:" + conversation.conversationId)
      if self.checkDismissTeamNoti(conversation) {
        return
      }

      self.mergeConversationData(conversation)

      // 订阅单聊在线状态
      if IMKitConfigCenter.shared.enableOnlineStatus,
         let accountId = V2NIMConversationIdUtil.conversationTargetId(conversation.conversationId) {
        self.p2pAccountIds.insert(accountId)
        self.subscribeOnlineStatus([accountId])
      }

      self.delegate?.reloadTableView()
      self.refreshConversationNameIfNeeded(conversation)
    }
  }

  /// 新建单聊会话时，首次名称可能暂时为账号 ID。查询用户资料后重新绑定会话数据。
  private func refreshConversationNameIfNeeded(_ conversation: V2NIMLocalConversation) {
    guard conversation.type == .CONVERSATION_TYPE_P2P,
          let accountId = V2NIMConversationIdUtil.conversationTargetId(conversation.conversationId),
          conversation.name == accountId else {
      return
    }

    NEFriendUserCache.shared.loadShowName([accountId]) { [weak self] users in
      guard let self,
            users?.contains(where: { $0.user?.accountId == accountId }) == true else {
        return
      }

      self.conversationRepo.getConversationListByIds([conversation.conversationId]) { [weak self] conversations, _ in
        guard let self,
              let refreshedConversation = conversations?.first else {
          return
        }
        DispatchQueue.main.async {
          guard let model = self.conversationDic[refreshedConversation.conversationId] else {
            return
          }
          model.conversation = refreshedConversation
          self.delegate?.reloadTableView()
        }
      }
    }
  }

  /// 会话变更
  /// - Parameter conversations 会话列表
  open func onLocalConversationChanged(_ conversations: [V2NIMLocalConversation]) {
    executeOnMain { [weak self] in
      guard let self else { return }
      for conversation in conversations {
        if let manager = NELocalAtMessageManager.instance {
          if conversation.unreadCount == 0, manager.isAtCurrentUser(conversationId: conversation.conversationId) {
            NELocalAtMessageManager.instance?.clearAtRecord(conversation.conversationId)
          }
        }

        if self.checkDismissTeamNoti(conversation) {
          continue
        }
        self.mergeConversationData(conversation)
      }

      self.delegate?.reloadTableView()
    }
  }

  open func onLocalConversationUnreadCountCleared(_ conversationIds: [String]) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      for conversationId in conversationIds {
        guard let model = self.conversationDic[conversationId] else { continue }
        model.markUnreadCountCleared()
        if model.unreadCount == 0 {
          NELocalAtMessageManager.instance?.clearAtRecord(conversationId)
        }
      }
      self.delegate?.reloadTableView()
    }
  }

  /// 多端同步会话已读时间后，按已读时间覆盖 SDK 缓存中的旧未读数。
  open func onLocalConversationReadTimeUpdated(_ conversationId: String, _ readTime: TimeInterval) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self,
            let model = self.conversationDic[conversationId] else { return }
      model.markUnreadCountCleared(through: readTime)
      if model.unreadCount == 0 {
        NELocalAtMessageManager.instance?.clearAtRecord(conversationId)
      }
      self.delegate?.reloadTableView()
    }
  }

  /// 会话删除
  /// - Parameter conversationIds: 会话id列表
  open func onLocalConversationDeleted(_ conversationIds: [String]) {
    executeOnMain { [weak self] in
      guard let self else { return }
      var removeFlagSet = Set<String>()
      for id in conversationIds {
        removeFlagSet.insert(id)
        self.conversationDic.removeValue(forKey: id)
      }
      self.conversationListData.removeAll(where: {
        if let sid = $0.conversation?.conversationId, removeFlagSet.contains(sid) {
          return true
        }
        return false
      })
      self.delegate?.reloadTableView()
    }
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
          conversationListData.removeAll { model in
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
        NEALog.infoLog(LocalConversationViewModel.className(), desc: "onTeamDismissed delete conversation error : \(err.localizedDescription)")
      } else {
        self?.executeOnMain { [weak self] in
          guard let self else { return }
          self.conversationDic.removeValue(forKey: cid)
          self.conversationListData.removeAll { model in
            if model.conversation?.conversationId == cid {
              return true
            }
            return false
          }
          self.delegate?.reloadTableView()
        }
      }
    }
  }

  open func onLocalConversationSyncFinished() {
    executeOnMain { [weak self] in
      guard let self else { return }
      NEALog.infoLog(self.className() + "[Performance]", desc: #function + " timestamp: \(Date().timeIntervalSince1970)")
      /// 设置同步完成标识
      self.syncFinished = true

      if let completion = self.callBack {
        NEALog.infoLog(self.className() + "[Performance]", desc: #function + " getConversationListByPage again")
        /// 取数据
        self.getConversationListByPage(completion)
        /// 回调置空
        self.callBack = nil
      }
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
          NEALog.infoLog(LocalConversationViewModel.className(), desc: #function + " retrieveConversationDatas")
          self?.retrieveConversationDatas()
        }
      }))
    }
  }

  /// 登录状态变更回调
  /// - Parameter status: 登录状态
  open func onLoginStatus(_ status: V2NIMLoginStatus) {
    // 账号切换（退出登录）时清空在线状态缓存，防止旧账号的离线状态数据污染新账号的会话列表
    if status == .LOGIN_STATUS_LOGOUT {
      executeOnMain { [weak self] in
        self?.p2pAccountIds.removeAll()
        self?.onlineStatusDic.removeAll()
      }
    }
  }

  /// 发生重连的情况重新获取数据
  open func retrieveConversationDatas() {
    guard Thread.isMainThread else {
      DispatchQueue.main.async { [weak self] in
        self?.retrieveConversationDatas()
      }
      return
    }

    var limit = 0
    if conversationDic.count > page {
      limit = conversationDic.count
    } else {
      limit = page
    }
    conversationRepo.getConversationList(0, limit) { [weak self] conversations, offset, finished, error in
      guard let self else { return }
      DispatchQueue.main.async {
        if error == nil {
          if let set = offset {
            // 更新索引
            self.offset = set
          }
          // 清理之前数据
          self.conversationListData.removeAll()
          self.conversationDic.removeAll()
          // 会话列表统一按 sortOrder 降序插入。
          conversations?.forEach { conversation in
            self.mergeConversationData(conversation)
          }
          self.delegate?.reloadTableView()
          if let complete = finished {
            self.delegate?.loadMoreStateChange(complete)
          }
        }
      }
    }
  }

  open func onFriendDeleted(_ accountId: String, deletionType: V2NIMFriendDeletionType) {
    if conversationDic.keys.contains(accountId) {
      delegate?.reloadTableView()
    }
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
    if let accountId = friendInfo.accountId,
       conversationDic.keys.contains(accountId) {
      delegate?.reloadTableView()
    }
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
      // AI 数字人（V2NIMAIUser，非机器人）跳过订阅，不展示在线状态
      if NEAIUserManager.shared.isAIUser(accountId) {
        continue
      }

      // 普通用户和机器人均走正常订阅流程
      if let event = NESubscribeManager.shared.getSubscribeStatus(accountId),
         let conversationId = V2NIMConversationIdUtil.p2pConversationId(accountId) {
        onlineStatusDic[conversationId] = NESubscribeManager.isOnline(event)
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
      // 遍历所有状态变更，不能 break，否则一批事件中只处理第一条
      if p2pAccountIds.contains(d.accountId),
         let conversationId = V2NIMConversationIdUtil.p2pConversationId(d.accountId) {
        onlineStatusDic[conversationId] = NESubscribeManager.isOnline(d)
        needRefresh = true
      }
    }

    if needRefresh {
      delegate?.reloadTableView()
    }
  }
}
