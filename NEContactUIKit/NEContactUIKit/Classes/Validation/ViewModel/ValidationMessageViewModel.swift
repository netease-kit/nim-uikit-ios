// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit
import NECoreKit

@objcMembers
open class ValidationMessageViewModel: NSObject, NEContactListener {
  let contactRepo = ContactRepo.shared
  var datas = [NENotification]()
  var dataRefresh: (() -> Void)?
  var offset: UInt = 0 // 查询的偏移量
  var pageMaxLimit: UInt = 100 // 查询的每页数量

  override init() {
    super.init()
    contactRepo.addContactListener(self)
  }

  deinit {
    contactRepo.removeContactListener(self)
  }

  /// 加载(更多)好友申请消息
  /// - Parameter firstLoad: 是否是首次加载
  /// - Parameter completin: 完成回调，(是否还有数据，错误信息)
  func loadApplicationList(_ firstLoad: Bool, _ completin: @escaping (Bool, Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)

    let offset = firstLoad ? 0 : offset
    if firstLoad {
      datas.removeAll()
    }
    getValidationMessage(offset) { [weak self] offset, finished, error in
      if let err = error {
        completin(finished, err)
      } else {
        self?.offset = offset
        completin(finished, nil)
      }
    }
  }

  /// 分页查询好友验证消息
  /// - Parameters:
  ///   - offset: 偏移量
  ///   - completin: 完成回调（验证消息列表，下一次偏移量，是否还有数据，错误信息）
  func getValidationMessage(_ offset: UInt, _ completin: @escaping (UInt, Bool, Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)

    let option = V2NIMFriendAddApplicationQueryOption()
    option.offset = offset
    option.limit = pageMaxLimit

    contactRepo.getAddApplicationList(option: option) { [weak self] result, error in
      if let err = error {
        completin(0, false, err)
      } else if let result = result, let infos = result.infos {
        let dateNow = Date().timeIntervalSince1970
        let group = DispatchGroup()

        for info in infos {
          var noti = NENotification(info: info)

          // 过期事件：7天（604800s）
          if noti.handleStatus == .HandleTypePending,
             dateNow - (noti.timestamp ?? 0) > 604_800 {
            noti.handleStatus = .HandleTypeOutOfDate
          }

          // 查询用户信息
          var uid: String?
          // 自己申请添加别人，则存储操作者的信息
          if noti.applicantAccid == IMKitClient.instance.account() {
            uid = noti.operatorAccid
          } else {
            // 别人申请添加自己，则存储申请者的信息
            uid = noti.applicantAccid
          }

          if let uid = uid {
            group.enter()
            self?.contactRepo.getUserWithFriend(accountIds: [uid]) { users, error in
              noti.userInfo = users?.first
              if var datas = self?.datas, self?.isExist(xNoti: &noti, list: &datas) == false {
                self?.datas.append(noti)
              }
              group.leave()
            }
          }
        }

        group.notify(queue: .main) { [weak self] in
          self?.datas.sort { xNoti1, xNoti2 in
            (xNoti1.timestamp ?? 0) > (xNoti2.timestamp ?? 0)
          }
          completin(result.offset, result.finished, nil)
        }
      }
    }
  }

  /// 判断该条申请是否已存在（是否可以聚合）
  /// - Parameters:
  ///   - xNoti: 申请
  ///   - list: 聚合列表
  /// - Returns: 是否已存在
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

  /// 设置所有好友申请已读
  /// - Parameter completion: 完成回调
  func setAddApplicationRead(_ completion: ((Bool, NSError?) -> Void)?) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    contactRepo.setAddApplicationRead { success, error in
      completion?(success, error as? NSError)
      DispatchQueue.main.async {
        NotificationCenter.default.post(name: NENotificationName.clearValidationUnreadCount, object: nil)
      }
    }
  }

  /// 同意好友申请
  /// - Parameters:
  ///   - application: 好友申请
  ///   - completion: 完成回调
  func agreeRequest(application: V2NIMFriendAddApplication,
                    _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", operatorAccountId:\(String(describing: application.operatorAccountId))")
    contactRepo.acceptAddApplication(application: application, completion)
  }

  /// 拒绝好友申请
  /// - Parameters:
  ///   - application: 好友申请
  ///   - completion: 完成回调
  func refuseRequest(application: V2NIMFriendAddApplication,
                     _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", operatorAccountId:\(String(describing: application.operatorAccountId))")
    contactRepo.rejectAddApplication(application: application, completion)
  }

  /// 清空好友申请通知
  func clearNotification() {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    contactRepo.clearNotification()
    datas.removeAll()
    dataRefresh?()
  }

  // MARK: - NEContactListener

  /// 好友添加申请变更
  /// - Parameter application: 申请添加好友信息
  func applicationChanged(_ application: V2NIMFriendAddApplication) {
    var noti = NENotification(info: application)
    let group = DispatchGroup()

    // 查询用户信息
    var uid: String?
    // 自己申请添加别人，则存储操作者的信息
    if noti.applicantAccid == IMKitClient.instance.account() {
      uid = noti.operatorAccid
    } else {
      // 别人申请添加自己，则存储申请者的信息
      uid = noti.applicantAccid
    }

    if let uid = uid {
      group.enter()
      contactRepo.getUserWithFriend(accountIds: [uid]) { [self] users, error in
        noti.userInfo = users?.first
        if !isExist(xNoti: &noti, list: &datas) {
          datas.insert(noti, at: 0)
        }
        datas.sort { xNoti1, xNoti2 in
          (xNoti1.timestamp ?? 0) > (xNoti2.timestamp ?? 0)
        }
        group.leave()
      }
    }

    group.notify(queue: .main) { [weak self] in
      self?.dataRefresh?()
    }
  }

  /// 收到好友添加申请回调
  /// - Parameter application: 申请添加好友信息
  public func onFriendAddApplication(_ application: V2NIMFriendAddApplication) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    applicationChanged(application)
  }

  /// 好友添加申请被拒绝回调
  /// - Parameter rejectionInfo: 申请添加好友拒绝信息
  public func onFriendAddRejected(_ rejectionInfo: V2NIMFriendAddApplication) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    applicationChanged(rejectionInfo)
  }
}
