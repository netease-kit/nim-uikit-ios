// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIMKit
import NECoreKit

@objcMembers
open class ValidationMessageViewModel: NSObject, ContactRepoSystemNotiDelegate {
  typealias DataRefresh = () -> Void

  var dataRefresh: DataRefresh?
  private let className = "ValidationMessageViewModel"
  let contactRepo = ContactRepo.shared
  var datas = [NENotification]()

  override init() {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    super.init()
    contactRepo.notiDelegate = self
  }

  open func onNotificationUnreadCountChanged(_ count: Int) {}

  // 内容待完善
//  open func onRecieveNotification(_ notification: XNotification) {
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

  func isExist(xNoti: inout NENotification, list: inout [NENotification]) -> Bool {
    for loopList in list {
      if xNoti.isEqualTo(noti: loopList) {
        if loopList.msgList == nil {
          loopList.msgList = [xNoti]
        } else {
          loopList.msgList!.append(xNoti)
        }
        loopList.teamInfo = xNoti.teamInfo
        loopList.userInfo = xNoti.userInfo
        if let loopTime = loopList.timestamp,
           let xNotiTime = xNoti.timestamp,
           loopTime < xNotiTime {
          loopList.timestamp = xNoti.timestamp
        }
        if !(xNoti.read ?? false) {
          loopList.unReadCount += 1
        }
        return true
      }
    }
    if !(xNoti.read ?? false) {
      xNoti.unReadCount += 1
    }
    return false
  }

  open func onRecieveNotification(_ notification: NENotification) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    var noti = notification
    if !isExist(xNoti: &noti, list: &datas) {
      datas.insert(notification, at: 0)
    }
    datas.sort { xNoti1, xNoti2 in
      (xNoti1.timestamp ?? 0) > (xNoti2.timestamp ?? 0)
    }
    if let block = dataRefresh {
      block()
    }
  }

  func getValidationMessage(_ completin: @escaping () -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    contactRepo.getNotificationList(limit: 500) { [weak self] xNotiList in
      var data = [NENotification]()
      let dateNow = Date().timeIntervalSince1970
      for xNoti in xNotiList {
        var noti = xNoti

        // 过期事件：7天（604800s）
        if noti.handleStatus == .HandleTypePending,
           dateNow - (noti.timestamp ?? 0) > 604_800 {
          noti.handleStatus = .HandleTypeOutOfDate
        }

        if !self!.isExist(xNoti: &noti, list: &data) {
          data.append(xNoti)
        }
      }
      self!.datas = data.sorted(by: { xNoti1, xNoti2 in
        (xNoti1.timestamp ?? 0) > (xNoti2.timestamp ?? 0)
      })
      if self!.datas.count <= 0 {
        NELog.warn(ModuleName + " " + self!.className, desc: "⚠️NotificationList is empty")
      }
      completin()
    }
  }

  func clearNotiUnreadCount() {
    contactRepo.clearNotificationUnreadCount()
  }

  func clearSingleNotifyUnreadCount(notification: NIMSystemNotification) {
    contactRepo.clearSingleNotifyUnreadCount(notification: notification)
  }

  func clearAllNoti(_ completion: () -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    contactRepo.clearNotification()
    datas.removeAll()
    completion()
  }

  open func acceptInviteWithTeam(_ teamId: String, _ invitorId: String,
                                 _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", teamId:\(teamId)")
    contactRepo.acceptTeamInvite(teamId, invitorId, completion)
  }

  open func rejectInviteWithTeam(_ teamId: String, _ invitorId: String,
                                 _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", teamId:\(teamId)")
    contactRepo.rejectTeamInvite(teamId, invitorId, completion)
  }

  func agreeRequest(_ account: String, _ completion: @escaping (NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", account:\(account)")
    let request = NEAddFriendRequest()
    request.account = account
    request.operationType = .verify
    contactRepo.addFriend(request: request, completion)
  }

  func refuseRequest(_ account: String, _ completion: @escaping (NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", account:\(account)")
    print("account : ", account)
    let request = NEAddFriendRequest()
    request.account = account
    request.operationType = .reject
    contactRepo.addFriend(request: request, completion)
  }
}
