// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit

@objc
public protocol AddApplicationViewModelDelegate: NSObjectProtocol {
  func tableviewReload()
}

@objcMembers
open class AddApplicationViewModel: NSObject, NEContactListener {
  private static let clearTimestampKeyPrefix = "NEContactUIKit.friendAddApplication.clearTimestamp."
  private static let pendingClearTimestampKeyPrefix = "NEContactUIKit.friendAddApplication.pendingClearTimestamp."

  let contactRepo = ContactRepo.shared
  public weak var delegate: AddApplicationViewModelDelegate?
  var friendAddApplications = [NEAddApplication]()
  var offset: UInt = 0 // 查询的偏移量
  var finished: Bool = false // 是否还有数据
  var pageMaxLimit: UInt = 100 // 查询的每页数量
  private var loadingApplicationList = false
  private var shouldReloadApplicationList = false

  override public init() {
    super.init()
    contactRepo.addContactListener(self)
  }

  deinit {
    contactRepo.removeContactListener(self)
  }

  /// 加载(更多)好友申请消息
  /// - Parameter firstLoad: 是否是首次加载
  /// - Parameter completin: 完成回调
  open func loadApplicationList(_ firstLoad: Bool, _ completin: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)

    let offset = firstLoad ? 0 : offset
    if firstLoad {
      finished = false
      loadingApplicationList = true
      friendAddApplications.removeAll()
      retryPendingClearIfNeeded()
    }

    if finished {
      finishLoadingApplicationList()
      completin(nil)
      reloadApplicationListIfNeeded()
      return
    }

    let option = V2NIMFriendAddApplicationQueryOption()
    option.offset = offset
    option.limit = pageMaxLimit

    contactRepo.getAddApplicationList(option: option) { [weak self] result, error in
      if let err = error {
        self?.finishLoadingApplicationList()
        completin(err)
        self?.reloadApplicationListIfNeeded()
      } else if let result = result {
        self?.offset = result.offset
        self?.finished = result.finished

        for item in result.infos ?? [] {
          self?.convertToNEAddApplication(item) { _ in
          }
        }

        self?.loadApplicationList(false, completin)
      }
    }
  }

  /// 转换（聚合）好友申请
  /// - Parameters:
  ///   - item: 好友申请
  ///   - move: 是否移动到最前
  ///   - completin: 完成回调
  open func convertToNEAddApplication(_ item: V2NIMFriendAddApplication,
                                      _ move: Bool = false,
                                      _ completin: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    guard !isLocallyCleared(item) else {
      completin(nil)
      return
    }

    var isExist = false
    for (index, neItem) in friendAddApplications.enumerated() {
      if neItem.isEqualTo(item) {
        isExist = true

        // 只有未处理的申请参与未读聚合，已处理记录可能仍保留 SDK 的未读标记。
        if shouldCountUnread(item) {
          neItem.unreadCount += 1
        }

        // 移动到最前
        if move, index != 0 {
          friendAddApplications.remove(at: index)
          friendAddApplications.insert(neItem, at: 0)
        }
        delegate?.tableviewReload()
        break
      }
    }

    if isExist {
      completin(nil)
      return
    }

    let friendAddApplication = NEAddApplication(item)
    friendAddApplication.unreadCount = shouldCountUnread(item) ? 1 : 0
    var applicationAccid = friendAddApplication.v2Notification.applicantAccountId

    // 申请添加他人为好友
    if friendAddApplication.v2Notification.applicantAccountId == IMKitClient.instance.account() {
      applicationAccid = friendAddApplication.v2Notification.recipientAccountId
      // 同意
      if friendAddApplication.v2Notification.status == .FRIEND_ADD_APPLICATION_STATUS_AGREED {
        friendAddApplication.detail = localizable("agreed_request")
      }

      // 拒绝
      if friendAddApplication.v2Notification.status == .FRIEND_ADD_APPLICATION_STATUS_REJECED {
        friendAddApplication.detail = localizable("refused_request")
      }
    }

    friendAddApplication.displayUserId = applicationAccid
    let friendAddApplicationsCount = friendAddApplications.count
    let insertIndex = move ? 0 : friendAddApplications.isEmpty ? 0 : friendAddApplicationsCount
    friendAddApplications.insert(friendAddApplication, at: insertIndex)

    if let accountId = applicationAccid {
      contactRepo.getUserWithFriend(accountIds: [accountId]) { [weak self] users, error in
        if let user = users?.first {
          friendAddApplication.displayUserWithFriend = user
          self?.delegate?.tableviewReload()
        }
      }
    }
  }

  /// 设置所有好友申请已读
  /// - Parameter completion: 完成回调
  open func setAddApplicationRead(_ completion: ((Bool, NSError?) -> Void)?) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    contactRepo.setAddApplicationRead { [weak self] success, error in
      self?.friendAddApplications.forEach { application in
        application.unreadCount = 0
      }

      completion?(success, error)

      DispatchQueue.main.async {
        NotificationCenter.default.post(name: NENotificationName.clearValidationMessageUnreadCount, object: nil)
      }
    }
  }

  /// 接受/拒绝好友申请
  /// - Parameters:
  ///   - application: 申请添加好友的相关信息
  ///   - status: 好友申请的处理状态
  open func changeApplicationStatus(_ application: V2NIMFriendAddApplication,
                                    _ status: V2NIMFriendAddApplicationStatus) {
    var changedIndex = -1
    for (index, item) in friendAddApplications.enumerated() {
      if item.isEqualTo(application, false) {
        item.handleStatus = status
        item.unreadCount = 0
        changedIndex = index
        break
      }
    }

    if changedIndex > -1 {
      var index = changedIndex + 1
      while index < friendAddApplications.count {
        if friendAddApplications[index].isEqualTo(application, true) {
          friendAddApplications.remove(at: index)
        } else {
          index += 1
        }
      }
    }
  }

  /// 同意好友申请
  /// - Parameters:
  ///   - application: 好友申请
  ///   - completion: 完成回调
  open func agreeRequest(application: V2NIMFriendAddApplication,
                         _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", operatorAccountId:\(String(describing: application.operatorAccountId))")
    contactRepo.acceptAddApplication(application: application) { [weak self] error in
      if let err = error {
        print(err.localizedDescription)
      } else {
        if let accid = application.applicantAccountId, let conversationId = V2NIMConversationIdUtil.p2pConversationId(accid) {
          Router.shared.use(ChatAddFriendRouter, parameters: ["text": localizable("let_us_chat"),
                                                              "conversationId": conversationId as Any])
        }
        self?.changeApplicationStatus(application, .FRIEND_ADD_APPLICATION_STATUS_AGREED)
      }
      completion(error)
    }
  }

  /// 拒绝好友申请
  /// - Parameters:
  ///   - application: 好友申请
  ///   - completion: 完成回调
  open func refuseRequest(application: V2NIMFriendAddApplication,
                          _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", operatorAccountId:\(String(describing: application.operatorAccountId))")
    contactRepo.rejectAddApplication(application: application) { [weak self] error in
      if let err = error {
        print(err.localizedDescription)
      } else {
        self?.changeApplicationStatus(application, .FRIEND_ADD_APPLICATION_STATUS_REJECED)
      }
      completion(error)
    }
  }

  /// 清空好友申请通知
  open func clearNotification(_ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    // The SDK leaves local records untouched when its server request fails, so retain the cutoff for filtering and retry.
    let timestamp = max(V2NIMFriendClearAddApplicationOption().timestamp, locallyClearedTimestamp)
    locallyClearedTimestamp = timestamp
    pendingClearTimestamp = timestamp
    friendAddApplications.removeAll()
    delegate?.tableviewReload()

    clearApplications(before: timestamp) { [weak self] error in
      if let err = error {
        print(err.localizedDescription)
      } else {
        self?.markPendingClearCompleted(timestamp)
        self?.notifyValidationUnreadCleared()
      }
      completion(error)
    }
  }

  private func notifyValidationUnreadCleared() {
    DispatchQueue.main.async {
      NotificationCenter.default.post(name: NENotificationName.clearValidationMessageUnreadCount, object: nil)
    }
  }

  private func finishLoadingApplicationList() {
    loadingApplicationList = false
  }

  private func refreshApplicationListForNewEvent() {
    if loadingApplicationList {
      shouldReloadApplicationList = true
      return
    }

    loadApplicationList(true) { [weak self] error in
      if let error {
        NEALog.errorLog(
          ModuleName + " " + AddApplicationViewModel.className(),
          desc: "refreshApplicationListForNewEvent CALLBACK error: \(error.localizedDescription)"
        )
      }
      self?.delegate?.tableviewReload()
    }
  }

  private func reloadApplicationListIfNeeded() {
    guard shouldReloadApplicationList else {
      return
    }
    shouldReloadApplicationList = false
    refreshApplicationListForNewEvent()
  }

  private var localClearTimestampKey: String {
    AddApplicationViewModel.clearTimestampKeyPrefix + IMKitClient.instance.account()
  }

  private var pendingClearTimestampKey: String {
    AddApplicationViewModel.pendingClearTimestampKeyPrefix + IMKitClient.instance.account()
  }

  private var locallyClearedTimestamp: TimeInterval {
    get { UserDefaults.standard.double(forKey: localClearTimestampKey) }
    set { UserDefaults.standard.set(newValue, forKey: localClearTimestampKey) }
  }

  private var pendingClearTimestamp: TimeInterval {
    get { UserDefaults.standard.double(forKey: pendingClearTimestampKey) }
    set { UserDefaults.standard.set(newValue, forKey: pendingClearTimestampKey) }
  }

  private func isLocallyCleared(_ application: V2NIMFriendAddApplication) -> Bool {
    let clearTimestamp = locallyClearedTimestamp
    guard clearTimestamp > 0 else {
      return false
    }

    let latestPostscriptTimestamp = application.postscriptHistory.last?.time ?? 0
    let eventTimestamp = max(application.timestamp, application.updateTimestamp, latestPostscriptTimestamp)
    return eventTimestamp == 0 || eventTimestamp <= clearTimestamp
  }

  private func shouldCountUnread(_ application: V2NIMFriendAddApplication) -> Bool {
    application.status == .FRIEND_ADD_APPLICATION_STATUS_INIT && application.read == false
  }

  private func retryPendingClearIfNeeded() {
    let timestamp = pendingClearTimestamp
    guard timestamp > 0 else {
      return
    }
    clearApplications(before: timestamp) { [weak self] error in
      if error == nil {
        self?.markPendingClearCompleted(timestamp)
      }
    }
  }

  private func clearApplications(before timestamp: TimeInterval,
                                 _ completion: @escaping (NSError?) -> Void) {
    let option = V2NIMFriendClearAddApplicationOption()
    option.timestamp = timestamp
    option.type = .FRIEND_ADD_APPLICATION_TYPE_ALL
    contactRepo.clearAllAddApplicationEx(option: option, completion)
  }

  private func markPendingClearCompleted(_ timestamp: TimeInterval) {
    if pendingClearTimestamp <= timestamp {
      UserDefaults.standard.removeObject(forKey: pendingClearTimestampKey)
    }
  }

  // MARK: - NEContactListener

  /// 收到好友添加申请回调
  /// - Parameter application: 申请添加好友信息
  open func onFriendAddApplication(_ application: V2NIMFriendAddApplication) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    DispatchQueue.main.async { [weak self] in
      self?.refreshApplicationListForNewEvent()
    }
  }

  /// 好友添加申请被拒绝回调
  /// - Parameter rejectionInfo: 申请添加好友拒绝信息
  open func onFriendAddRejected(_ rejectionInfo: V2NIMFriendAddApplication) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)

    for item in friendAddApplications {
      if item.v2Notification.applicantAccountId == IMKitClient.instance.account(),
         item.v2Notification.recipientAccountId == rejectionInfo.operatorAccountId {
        item.handleStatus = .FRIEND_ADD_APPLICATION_STATUS_REJECED
        item.unreadCount = 0
      }
    }
    delegate?.tableviewReload()
  }
}
