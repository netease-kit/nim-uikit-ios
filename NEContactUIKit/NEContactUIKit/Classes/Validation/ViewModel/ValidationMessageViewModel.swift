// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit
import NECoreKit

@objc
public protocol ValidationMessageViewModelDelegate: NSObjectProtocol {
  func tableviewReload()
}

@objcMembers
open class ValidationMessageViewModel: NSObject, NEContactListener {
  let contactRepo = ContactRepo.shared
  public weak var delegate: ValidationMessageViewModelDelegate?
  var friendAddApplications = [NENotification]()
  var offset: UInt = 0 // 查询的偏移量
  var finished: Bool = false // 是否还有数据
  var pageMaxLimit: UInt = 100 // 查询的每页数量

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
      friendAddApplications.removeAll()
    }

    if finished {
      completin(nil)
      return
    }

    let option = V2NIMFriendAddApplicationQueryOption()
    option.offset = offset
    option.limit = pageMaxLimit

    contactRepo.getAddApplicationList(option: option) { [weak self] result, error in
      if let err = error {
        completin(err)
      } else if let result = result {
        self?.offset = result.offset
        self?.finished = result.finished

        for item in result.infos ?? [] {
          self?.convertToValidationMessage(item) { _ in
          }
        }

        self?.loadApplicationList(false, completin)
      }
    }
  }

  /// 转换（聚合）验证消息
  /// - Parameters:
  ///   - item: 验证消息
  ///   - move: 是否移动到最前
  ///   - completin: 完成回调
  open func convertToValidationMessage(_ item: V2NIMFriendAddApplication,
                                       _ move: Bool = false,
                                       _ completin: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    var isExist = false
    for (index, neItem) in friendAddApplications.enumerated() {
      if neItem.isEqualTo(item) {
        isExist = true

        // 未读数
        if item.read == false {
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

    let friendAddApplication = NENotification(item)
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

      DispatchQueue.main.async {
        NotificationCenter.default.post(name: NENotificationName.clearValidationUnreadCount, object: nil)
      }
      completion?(success, error)
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
    contactRepo.clearNotification { [weak self] error in
      if let err = error {
        print(err.localizedDescription)
      }
      self?.friendAddApplications.removeAll()
      completion(error)
    }
  }

  // MARK: - NEContactListener

  /// 收到好友添加申请回调
  /// - Parameter application: 申请添加好友信息
  open func onFriendAddApplication(_ application: V2NIMFriendAddApplication) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    convertToValidationMessage(application, true) { error in
      if let err = error {
        print(err.localizedDescription)
      }
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
