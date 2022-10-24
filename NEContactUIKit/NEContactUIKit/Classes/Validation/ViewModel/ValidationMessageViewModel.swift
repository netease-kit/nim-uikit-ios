// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEContactKit
import NECoreIMKit
import NECoreKit

@objcMembers
public class ValidationMessageViewModel: NSObject, ContactRepoSystemNotiDelegate {
  typealias DataRefresh = () -> Void

  var dataRefresh: DataRefresh?
  private let className = "ValidationMessageViewModel"
  let contactRepo = ContactRepo()
  var datas = [XNotification]()

  override init() {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    super.init()
    contactRepo.notiDelegate = self
  }

  public func onNotificationUnreadCountChanged(_ count: Int) {}

  // 内容待完善
//  public func onRecieveNotification(_ notification: XNotification) {
//    NELog.infoLog(className, desc: #function)
//    var isInsert = true
//    for notify in datas {
//      if notify.sourceID == notification.sourceID, notify.type == notification.type {
//        isInsert = false
//        break
//      }
//    }
//    if isInsert {
//      datas.insert(notification, at: 0)
//    }
//    contactRepo.clearNotificationUnreadCount()
//    if let block = dataRefresh {
//      block()
//    }
//  }
  // 内容待完善
//  func getValidationMessage(_ completin: @escaping () -> Void) {
//    NELog.infoLog(className, desc: #function)
//    weak var weakSelf = self
//    contactRepo.getNotificationList(limit: 500) { notifications in
//      weakSelf?.datas = notifications
//      if let count = weakSelf?.datas.count, count > 0 {
//        completin()
//      } else {
//        NELog.warn(weakSelf?.className ?? "ValidationMessageViewModel", desc: "⚠️NotificationList is empty")
//      }
//    }
//  }

  public func onRecieveNotification(_ notification: XNotification) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
//        if notification.type == .addFriendDirectly {
//            datas.insert(notification, at: 0)
//        }
    datas.insert(notification, at: 0)
    contactRepo.clearNotificationUnreadCount()
    if let block = dataRefresh {
      block()
    }
  }

  func getValidationMessage(_ completin: () -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    let data = contactRepo.getNotificationList(limit: 500)
    datas = data
    if datas.count > 0 {
      completin()
    } else {
      NELog.warn(ModuleName + " " + className, desc: "⚠️NotificationList is empty")
    }
  }

  func clearAllNoti(_ completion: () -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    contactRepo.clearNotification()
    datas.removeAll()
    completion()
  }

  public func acceptInviteWithTeam(_ teamId: String, _ invitorId: String,
                                   _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", teamId:\(teamId)")
    contactRepo.acceptTeamInvite(teamId, invitorId, completion)
  }

  public func rejectInviteWithTeam(_ teamId: String, _ invitorId: String,
                                   _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", teamId:\(teamId)")
    contactRepo.rejectTeamInvite(teamId, invitorId, completion)
  }

  func agreeRequest(_ account: String, _ completion: @escaping (NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", account:\(account)")
    let request = AddFriendRequest()
    request.account = account
    request.operationType = .verify
    contactRepo.addFriend(request: request, completion)
  }

  func refuseRequest(_ account: String, _ completion: @escaping (NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", account:\(account)")
    print("account : ", account)
    let request = AddFriendRequest()
    request.account = account
    request.operationType = .reject
    contactRepo.addFriend(request: request, completion)
  }
}
