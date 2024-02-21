// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIMKit
import NIMSDK

let revokeLocalMessage = "revoke_message_local"
let revokeLocalMessageContent = "revoke_message_local_content"

@objc
public protocol ConversationViewModelDelegate: NSObjectProtocol {
  func didAddRecentSession()
  func didUpdateRecentSession(index: Int)
  func reloadData()
  func reloadTableView()
}

@objcMembers
open class ConversationViewModel: NSObject, ConversationRepoDelegate,
  NIMConversationManagerDelegate, NIMTeamManagerDelegate, NIMUserManagerDelegate, NIMChatManagerDelegate {
  public var conversationListArray: [ConversationListModel]?
  public var stickTopInfos = [NIMSession: NIMStickTopSessionInfo]()
  public weak var delegate: ConversationViewModelDelegate?
  private let className = "ConversationViewModel"
  public let repo = ConversationRepo.shared

  var cacheUpdateSessionDic = [String: NIMRecentSession]()
  var cacheAddSessionDic = [String: ConversationListModel]()

  override public init() {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    super.init()
    repo.delegate = self
    repo.addSessionDelegate(delegate: self)
    repo.addChatDelegate(delegate: self)
    repo.addTeamDelegate(delegate: self)
    stickTopInfos = repo.getStickTopInfos()
    NIMSDK.shared().userManager.add(self)
    NotificationCenter.default.addObserver(self, selector: #selector(atMessageChange), name: Notification.Name(AtMessageChangeNoti), object: nil)
  }

  deinit {
    NELog.infoLog(ModuleName + className(), desc: #function)
    repo.removeSessionDelegate(delegate: self)
    repo.removeChatDelegate(delegate: self)
    repo.removeTeamDelegate(delegate: self)
    NIMSDK.shared().userManager.remove(self)
    NotificationCenter.default.removeObserver(self)
  }

  func atMessageChange() {
    NELog.infoLog(className(), desc: "atMessageChange")
    delegate?.reloadTableView()
  }

  open func fetchServerSessions(option: NIMFetchServerSessionOption,
                                _ completion: @escaping (NSError?, [ConversationListModel]?)
                                  -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    weak var weakSelf = self
    repo.getSessionList { error, conversaitonList in
      DispatchQueue.main.async {
        weakSelf?.conversationListArray = conversaitonList
        NELog.infoLog(ModuleName, desc: "get session list : \(conversaitonList?.count ?? 0)")
        var set = Set<String>()
        conversaitonList?.forEach { model in
          NELog.infoLog(ModuleName, desc: "get session sid : \(model.recentSession?.session?.sessionId ?? "nil")")
          if let recentSession = model.recentSession, let sid = recentSession.session?.sessionId {
            set.insert(sid)
            if let recent = weakSelf?.cacheUpdateSessionDic[sid] {
              NELog.infoLog(ModuleName, desc: "cacheUpdateSessionDic fitler sid: \(recent.session?.sessionId ?? "nil")")
              if let time1 = recentSession.lastMessage?.timestamp, let time2 = recent.lastMessage?.timestamp, time1 < time2 {
                model.recentSession = recent
              }
            }

            if let recent = weakSelf?.cacheAddSessionDic[sid]?.recentSession {
              NELog.infoLog(ModuleName, desc: "cacheAddSessionDic fitler sid: \(recent.session?.sessionId ?? "nil")")
              if let time1 = recentSession.lastMessage?.timestamp, let time2 = recent.lastMessage?.timestamp, time1 < time2 {
                model.recentSession = recent
              }
            }
          }
        }
        NELog.infoLog(ModuleName, desc: "cacheAddSessionDic count: \(weakSelf?.cacheAddSessionDic.count ?? 0)")
        weakSelf?.cacheAddSessionDic.forEach { (key: String, value: ConversationListModel) in
          NELog.infoLog(ModuleName, desc: "cacheAddSessionDic  key: \(key)")
          if set.contains(key) == false {
            if let recent = weakSelf?.cacheUpdateSessionDic[key] {
              if let time1 = value.recentSession?.lastMessage?.timestamp, let time2 = recent.lastMessage?.timestamp, time1 < time2 {
                value.recentSession = recent
              }
            }
            NELog.infoLog(ModuleName, desc: "cacheAddSessionDic : \(key)")
            weakSelf?.conversationListArray?.append(value)
          }
        }
        weakSelf?.cacheAddSessionDic.removeAll()

        // 可在此处对会话列表进行过滤

        NELog.infoLog(ModuleName, desc: "conversationListArray count : \(weakSelf?.conversationListArray?.count ?? 0)")
        completion(error, weakSelf?.conversationListArray)

        // 拉取好友信息
        ChatUserCache.removeAllUserInfo()
        ContactRepo.shared.getFriendList(true, local: false) { friends, error in
          if let friends = friends {
            friends.forEach { user in
              ChatUserCache.updateUserInfo(user)
            }
          }
        }
      }
    }
  }

  open func deleteRecentSession(recentSession: NIMRecentSession) {
    NELog.infoLog(
      ModuleName + " " + className,
      desc: #function + ", sessionId:" + (recentSession.session?.sessionId ?? "nil")
    )
    weak var weakSelf = self
    let option = NIMDeleteRecentSessionOption()
    option.isDeleteRoamMessage = true
    option.shouldMarkAllMessagesReadInSessions = true
    repo.deleteRecentConversation(recentSession, option) { error in
      weakSelf?.repo.deleteLocalSession(recentSession: recentSession)
    }
  }

  open func stickTopInfoForSession(session: NIMSession) -> NIMStickTopSessionInfo? {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", sessionId:" + session.sessionId)
    return repo.getStickTopSessionInfo(session: session)
  }

  open func addStickTopSession(session: NIMSession,
                               _ completion: @escaping (NSError?, NIMStickTopSessionInfo?)
                                 -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", sessionId:" + session.sessionId)
    let params = NIMAddStickTopSessionParams(session: session)
    repo.addStickTop(params: params) { error, stickTopSessionInfo in
      completion(error as NSError?, stickTopSessionInfo)
    }
  }

  open func removeStickTopSession(params: NIMStickTopSessionInfo,
                                  _ completion: @escaping (NSError?, NIMStickTopSessionInfo?)
                                    -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", sessionId:" + params.session.sessionId)
    repo.removeStickTop(params: params) { error, stickTopSessionInfo in
      completion(error as NSError?, stickTopSessionInfo)
    }
  }

  open func loadStickTopSessionInfos(_ completion:
    @escaping (NSError?, [NIMSession: NIMStickTopSessionInfo]?)
      -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    repo.getStickTopSessionList(completion)
  }

  open func notifyForNewMsg(userId: String?) -> Bool {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", userId:" + (userId ?? "nil"))
    return repo.isNeedNotify(userId: userId)
  }

  open func notifyStateForNewMsg(teamId: String?) -> NIMTeamNotifyState {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", teamId:" + (teamId ?? "nil"))
    return repo.isNeedNotifyForTeam(teamId: teamId)
  }

  // MARK: ======================== private method ==============================

  open func sortRecentSession() {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    var tempArr = [NIMRecentSession]()
    var dic = [String: ConversationListModel]()
    conversationListArray?.forEach { listModel in
      if let session = listModel.recentSession {
        tempArr.append(session)
        if let sessionId = session.session?.sessionId {
          dic[sessionId] = listModel
        }
      }
    }

    let resultArr = repo.sortSessionList(recentSessions: tempArr, stickTopInfo: stickTopInfos)
    var sortResultArr = [ConversationListModel]()
    resultArr.forEach { recentSession in
      let listModel = ConversationListModel()
      listModel.recentSession = recentSession
      if recentSession.session?.sessionType == .P2P {
        if let sessionId = recentSession.session?.sessionId,
           let userInfo = dic[sessionId]?.userInfo {
          listModel.userInfo = userInfo
        }

      } else if recentSession.session?.sessionType == .team {
        if let sessionId = recentSession.session?.sessionId,
           let teamInfo = dic[sessionId]?.teamInfo {
          listModel.teamInfo = teamInfo
        }
      }
      sortResultArr.append(listModel)
    }
    conversationListArray = sortResultArr
  }

  // 本地排序 在didUpdate的时候如有需要在打开
  func findInsertPlace(recentSession: NIMRecentSession) -> NSInteger {
    NELog.infoLog(
      ModuleName + " " + className,
      desc: #function + ", sessionId:" + (recentSession.session?.sessionId ?? "nil")
    )
    var matchIndex = 0
    var find = false
    if let conversationArr = conversationListArray {
      for (i, listModel) in conversationArr.enumerated() {
        if let enumTime = listModel.recentSession?.lastMessage?.timestamp,
           let targetTime = recentSession.lastMessage?.timestamp {
          if enumTime <= targetTime {
            find = true
            matchIndex = i
            break
          }
        }
      }
    }

    if find {
      return matchIndex
    } else {
      return conversationListArray?.count ?? 0
    }
  }

  // MARK: ==================== NIMChatManagerDelegate ==========================

  open func onRecvMessageReceipts(_ receipts: [NIMMessageReceipt]) {
    receipts.forEach { receipt in
      if receipt.session?.sessionType == .P2P {
        if let listArr = conversationListArray {
          for (i, listModel) in listArr.enumerated() {
            if listModel.recentSession?.session?.sessionType == .P2P,
               receipt.session?.sessionId == listModel.recentSession?.session?.sessionId {
              delegate?.didUpdateRecentSession(index: i)
            }
          }
        }
      }
    }
  }

  // MARK: ==================== ConversationRepoDelegate ==========================

  open func onNotifyAddStickTopSession(_ newInfo: NIMStickTopSessionInfo) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ",onNotifyAddStickTopSession sessionId:" + newInfo.session.sessionId)
    stickTopInfos[newInfo.session] = newInfo
    if repo.getRecentSession(newInfo.session) == nil {
      repo.addRecentSession(newInfo.session)
    }
    delegate?.reloadTableView()
  }

  open func onNotifyRemoveStickTopSession(_ removedInfo: NIMStickTopSessionInfo) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ",onNotifyRemoveStickTopSession  sessionId:" + removedInfo.session.sessionId)
    stickTopInfos[removedInfo.session] = nil
    delegate?.reloadTableView()
  }

  open func onNotifySyncStickTopSessions(_ response: NIMSyncStickTopSessionResponse) {
    loadStickTopSessionInfos { [weak self] error, sessionInfos in
      NELog.infoLog(
        ModuleName + " " + (self?.className ?? "ConversationViewModel"),
        desc: "CALLBACK loadStickTopSessionInfos " + (error?.localizedDescription ?? "no error")
      )
      if error != nil {
        if let infos = self?.repo.getStickTopInfos() {
          self?.stickTopInfos = infos
        }
      } else if let infos = sessionInfos {
        self?.stickTopInfos = infos
      }
      self?.delegate?.reloadTableView()
      self?.delegate?.reloadData()
    }
  }

  open func didServerSessionUpdated(_ recentSession: NIMRecentSession?) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ",didServerSessionUpdated:" + (recentSession?.session?.sessionId ?? ""))
  }

  // MARK: ====================NIMConversationManagerDelegate=====================

  open func didAdd(_ recentSession: NIMRecentSession, totalUnreadCount: Int) {
    guard let targetId = recentSession.session?.sessionId else {
      NELog.errorLog(ModuleName + " " + className, desc: "❌sessionId is nil")
      return
    }
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", did add session targetId:" + targetId)

    // 解散、退出群聊
    if let object = recentSession.lastMessage?.messageObject as? NIMNotificationObject, object.notificationType == .team {
      if let content = object.content as? NIMTeamNotificationContent {
        if content.operationType == .dismiss ||
          (content.operationType == .kick &&
            content.targetIDs?.contains(IMKitClient.instance.imAccid()) == true) ||
          (content.operationType == .leave &&
            IMKitClient.instance.isMySelf(content.sourceID)) {
          // 群聊被解散
          // 被踢出群聊
          // 主动退出群聊
          NELog.infoLog(
            ModuleName + " " + className,
            desc: #function + "didAdd team dismiss or leave noti" + (recentSession.session?.sessionId ?? "nil")
          )
          repo.deleteLocalSession(recentSession: recentSession)

          // 移除置顶
          if let session = recentSession.session {
            if let param = stickTopInfos[session] {
              removeStickTopSession(params: param) { error, _ in
                if let err = error {
                  NELog.errorLog(
                    ModuleName + " ConversationViewModel",
                    desc: "CALLBACK removeStickTopSession failed，error = \(err)"
                  )
                }
              }
            }
            stickTopInfos.removeValue(forKey: session)
          }
          return
        }
      }
    }

    weak var weakSelf = self
    var listModel = ConversationListModel()
    if let sid = recentSession.session?.sessionId {
      print("session session id : ", sid)
      if let model = cacheAddSessionDic[sid] {
        listModel = model
        NELog.infoLog(
          ModuleName + " " + className,
          desc: #function + "didAdd team has added" + (recentSession.session?.sessionId ?? "nil")
        )
      }
      cacheAddSessionDic[sid] = listModel
    }
    listModel.recentSession = recentSession

    if recentSession.session?.sessionType == .P2P {
      repo.fetchUserInfo(accountList: [targetId]) { users, error in
        if error == nil {
          listModel.userInfo = users?.first
          if let model = weakSelf?.sessionIsExist(listModel) {
            model.userInfo = users?.first
          } else {
            weakSelf?.conversationListArray?.append(listModel)
          }
          weakSelf?.delegate?.didAddRecentSession()
        }
      }

    } else if recentSession.session?.sessionType == .team {
      if !repo.isMyTeam(teamId: targetId) {
        // 自己不在群内，不新增该群聊会话
        return
      }

      repo.getTeamInfo(teamId: targetId) { error, teamInfo in
        listModel.teamInfo = teamInfo
        if let model = weakSelf?.sessionIsExist(listModel) {
          model.teamInfo = teamInfo
          weakSelf?.delegate?.didAddRecentSession()
        } else {
          if listModel.teamInfo != nil {
            // 会话列表新增一项
            weakSelf?.conversationListArray?.append(listModel)
            weakSelf?.delegate?.didAddRecentSession()
          }
        }
      }
    }
  }

  open func didUpdate(_ recentSession: NIMRecentSession, totalUnreadCount: Int) {
    guard let targetId = recentSession.session?.sessionId else {
      NELog.errorLog(ModuleName + " " + className, desc: "❌sessionId is nil")
      return
    }

    NELog.infoLog(
      ModuleName + " " + className,
      desc: #function + "recentSession, didUpdate sessionId: \(targetId), unread count : \(totalUnreadCount)"
    )

    if recentSession.unreadCount <= 0 {
      if NEAtMessageManager.instance?.isAtCurrentUser(sessionId: targetId) == true {
        NEAtMessageManager.instance?.clearAtRecord(targetId)
      }
    }

    if let object = recentSession.lastMessage?.messageObject as? NIMNotificationObject, object.notificationType == .team {
      if let content = object.content as? NIMTeamNotificationContent {
        if content.operationType == .dismiss ||
          (content.operationType == .kick &&
            content.targetIDs?.contains(IMKitClient.instance.imAccid()) == true) ||
          (content.operationType == .leave &&
            IMKitClient.instance.isMySelf(content.sourceID)) {
          // 群聊被解散
          // 被踢出群聊
          // 主动退出群聊
          NELog.infoLog(
            ModuleName + " " + className,
            desc: #function + "didUpdate team dismiss or leave noti: \(targetId)"
          )
          repo.deleteLocalSession(recentSession: recentSession)

          // 移除置顶
          if let session = recentSession.session {
            if let param = stickTopInfos[session] {
              removeStickTopSession(params: param) { error, _ in
                if let err = error {
                  NELog.errorLog(
                    ModuleName + " ConversationViewModel",
                    desc: "CALLBACK removeStickTopSession failed，error = \(err)"
                  )
                }
              }
            }
            stickTopInfos.removeValue(forKey: session)
          }
          return
        }
      }
    }

    cacheUpdateSessionDic[targetId] = recentSession
    if let model = cacheAddSessionDic[targetId], let recent = model.recentSession {
      if let time1 = recentSession.lastMessage?.timestamp, let time2 = recent.lastMessage?.timestamp, time1 > time2 {
        model.recentSession = recentSession
      }
    }

    weak var weakSelf = self
    if let _ = conversationListArray {
      for i in 0 ..< conversationListArray!.count {
        let listModel = conversationListArray![i]
        NELog.infoLog(
          ModuleName + " " + className,
          desc: #function + "update session id : " + (listModel.recentSession?.session?.sessionId ?? "nil")
        )
        if targetId == listModel.recentSession?.session?.sessionId {
          listModel.recentSession = recentSession
          if recentSession.session?.sessionType == .P2P {
            repo.fetchUserInfo(accountList: [targetId]) { users, error in
              if error == nil {
                listModel.userInfo = users?.first
              }
            }
          } else if recentSession.session?.sessionType == .team {
            repo.getTeamInfo(teamId: targetId) { error, teamInfo in
              listModel.teamInfo = teamInfo
            }
          }
          weakSelf?.delegate?.reloadTableView()
          return
        }
      }

      // 会话列表中没有该回话则添加
      didAdd(recentSession, totalUnreadCount: totalUnreadCount)
    }
  }

  open func didRemove(_ recentSession: NIMRecentSession, totalUnreadCount: Int) {
    guard let targetId = recentSession.session?.sessionId else {
      NELog.errorLog(ModuleName + " " + className, desc: "❌sessionId is nil")
      return
    }

    NELog.infoLog(
      ModuleName + " " + className,
      desc: #function + ",didRemove recentSession  sessionId: \(targetId)"
    )

    cacheUpdateSessionDic.removeValue(forKey: targetId)

    if let conversationArr = conversationListArray {
      for i in 0 ..< conversationArr.count {
        if conversationArr[i].recentSession?.session?.sessionId.count ?? 0 <= 0 {
          NELog.infoLog(
            ModuleName + " " + className,
            desc: #function + ",didRemove recentSession  sessionId is empty  user: \(conversationArr[i].userInfo?.userId ?? "") team: \(conversationArr[i].teamInfo?.teamId ?? "")"
          )
        }
        if conversationArr[i].recentSession?.session?.sessionId == recentSession.session?
          .sessionId {
          NELog.infoLog(
            ModuleName + " " + className,
            desc: #function + ",remove session list at index : \(i) sessionid : \(targetId)"
          )

          conversationListArray?.remove(at: i)
          break
        }
      }
    }
    delegate?.reloadTableView()
  }

  // 收到多端登录单向删除通知，手动更新会话最后一条消息
  open func onRecvMessagesDeleted(_ messages: [NIMMessage], exts: [String: String]?) {
    for message in messages {
      guard let session = message.session else { return }

      for listModel in conversationListArray ?? [] {
        if session.sessionId == listModel.recentSession?.session?.sessionId {
          NELog.infoLog(ModuleName + " " + className, desc: #function + "onRecvMessagesDeleted sessionid: \(session.sessionId) message text: \(message.text ?? "")")

          // 手动查询最后一条消息
          let param = NIMGetMessagesDynamicallyParam()
          param.session = session
          param.limit = 1
          ChatRepo.shared.getMessagesDynamically(param) { [weak self] _, _, messages in
            listModel.recentSession?.lastMessage = messages?.first
            self?.delegate?.reloadTableView()
          }
          break
        }
      }
    }
  }

  // MARK: ========================NIMUserManagerDelegate=========================

  open func onFriendChanged(_ user: NIMUser) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", userId:" + (user.userId ?? "nil"))
    if let listArr = conversationListArray {
      for (i, listModel) in listArr.enumerated() {
        if listModel.recentSession?.session?.sessionType == .P2P {
          if listModel.userInfo?.userId == user.userId {
            let u = NEKitUser(user: user)
            listModel.userInfo = u
            ChatUserCache.updateUserInfo(u)
            delegate?.didUpdateRecentSession(index: i)
            break
          }
        }
      }
    }
  }

  // MARK: =========================NIMTeamManagerDelegate========================

  open func onTeamUpdated(_ team: NIMTeam) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", teamId:" + (team.teamId ?? "nil"))
    guard let conversationArr = conversationListArray else {
      return
    }
    for (i, listModel) in conversationArr.enumerated() {
      if listModel.recentSession?.session?.sessionId == team.teamId {
        listModel.teamInfo = team
        delegate?.didUpdateRecentSession(index: i)
        break
      }
    }
  }

  open func onTeamAdded(_ team: NIMTeam) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + "onTeamAdded, teamId:" + (team.teamId ?? "nil"))
    guard let tid = team.teamId else {
      return
    }
    let _ = repo.createTeamSession(tid)
    delegate?.didAddRecentSession()
  }

  open func onTeamRemoved(_ team: NIMTeam) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", teamId:" + (team.teamId ?? "nil"))
    // 做删除会话操作(自己退出群聊会触发)
    guard let conversationArr = conversationListArray else {
      return
    }

    DispatchQueue.main.async {
      for listModel in conversationArr {
        if let teamInfo = listModel.teamInfo, teamInfo.teamId == team.teamId {
          if let recentSession = listModel.recentSession {
            self.deleteRecentSession(recentSession: recentSession)
            break
          }
        }
      }
    }
  }

  open func onTeamMemberChanged(_ team: NIMTeam) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", teamId:" + (team.teamId ?? "nil"))
    guard let conversationArr = conversationListArray else {
      return
    }
    for (i, listModel) in conversationArr.enumerated() {
      if listModel.recentSession?.session?.sessionId == team.teamId {
        listModel.teamInfo = team
        delegate?.didUpdateRecentSession(index: i)
        break
      }
    }
  }

  private func sessionIsExist(_ model: ConversationListModel) -> ConversationListModel? {
    if let array = conversationListArray {
      for index in 0 ..< array.count {
        let m = array[index]
        if m.recentSession?.session?.sessionId == model.recentSession?.session?.sessionId {
          return m
        }
      }
    }
    return nil
  }

  open func onMuteListChanged() {
    delegate?.reloadTableView()
  }
}
