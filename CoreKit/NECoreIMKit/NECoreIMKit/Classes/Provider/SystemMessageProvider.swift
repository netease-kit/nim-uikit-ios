
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public protocol SystemMessageProviderDelegate: NSObjectProtocol {
  func onRecieveNotification(notification: XNotification)
  func onNotificationUnreadCountChanged(count: Int)
  func onReceive(_ notification: NIMCustomSystemNotification)
}

@objcMembers
public class SystemMessageProvider: NSObject, NIMSystemNotificationManagerDelegate {
  public static let shared = SystemMessageProvider()
  private let mutiDelegate = MultiDelegate<SystemMessageProviderDelegate>(strongReferences: false)
  override private init() {
    super.init()
    NIMSDK.shared().systemNotificationManager.add(self)
  }

  /// Gets system notifications stored locally
  /// - Parameter limit: The maximum number of notifications
  /// - Returns: List of notification
  public func getNotificationList(limit: Int) -> [XNotification] {
    var list: [XNotification] = []
    guard let notifications = NIMSDK.shared().systemNotificationManager
      .fetchSystemNotifications(nil, limit: limit) else {
      return list
    }
    for notification in notifications {
      list.append(detailNotification(notification: notification))
    }
    return list
  }

  public func getNotificationList(limit: Int, completion: @escaping ([XNotification]) -> Void) {
    var xNotiList: [XNotification] = []
    var listNoTeamInfo: [String] = []
    var listNoUserInfo: [String] = []
    guard let notifications = NIMSDK.shared().systemNotificationManager
      .fetchSystemNotifications(nil, limit: limit) else {
      return
    }
    for notification in notifications {
      let noti = detailNotification(notification: notification)
      switch noti.type {
      case .teamApply, .teamInvite, .teamApplyReject, .teamInviteReject:
        if noti.teamInfo == nil {
          if let uid = noti.targetID {
            listNoTeamInfo.append(uid)
          }
        }

      case .addFriendDirectly, .addFriendRequest, .addFriendVerify, .addFriendReject:
        if noti.userInfo == nil {
          if let uid = noti.sourceID {
            listNoUserInfo.append(uid)
          }
        }

      default: break
      }
      xNotiList.append(noti)
    }

    let signal = DispatchGroup()

    signal.enter()
    TeamProvider.shared.fetchTeamInfoList(teamIds: listNoTeamInfo) { error, teams in
      if let teamList = teams {
        for team in teamList {
          for xNoti in xNotiList {
            if let tid = team.teamId,
               let targetID = xNoti.targetID,
               tid == targetID {
              xNoti.teamInfo = Team(teamInfo: team)
            }
          }
        }
      }
      signal.leave()
    }

    signal.enter()
    UserInfoProvider.shared.fetchUserInfo(listNoUserInfo) { error, users in
      if let userList = users {
        for user in userList {
          for xNoti in xNotiList {
            if let uid = user.userId,
               let sourceId = xNoti.sourceID,
               uid == sourceId {
              xNoti.userInfo = user
            }
          }
        }
      }
      signal.leave()
    }

    signal.notify(queue: .main, work: DispatchWorkItem(block: {
      completion(xNotiList)
    }))
  }

  private func detailNotification(notification: NIMSystemNotification?) -> XNotification {
    let noti = XNotification(notification: notification)
    switch noti.type {
    case .teamApply, .teamInvite, .teamApplyReject, .teamInviteReject:
      // team
      let targetTeam = TeamProvider.shared.teamInfo(teamId: noti.targetID)
      noti.targetName = targetTeam?.teamName
      noti.teamInfo = targetTeam

    case .superTeamApply, .superTeamInvite, .superTeamApplyReject, .superTeamInviteReject:
      // super team
      let targetTeam = TeamProvider.shared.superTeamInfo(teamId: noti.targetID)
      noti.targetName = targetTeam?.teamName
      noti.teamInfo = targetTeam

    case .addFriendDirectly, .addFriendRequest, .addFriendVerify, .addFriendReject:
      guard let source = noti.sourceID else {
        break
      }

      if let user = UserInfoProvider.shared.getUserInfo(userId: source) {
        noti.userInfo = user
      }
    default: break
    }
    return noti
  }

  private func detailNotification(notification: NIMSystemNotification?, completion: @escaping (XNotification) -> Void) {
    let noti = XNotification(notification: notification)
    switch noti.type {
    case .teamApply, .teamInvite, .teamApplyReject, .teamInviteReject:
      // team
      guard let targetID = noti.targetID else {
        break
      }
      TeamProvider.shared.fetchTeamInfo(teamId: targetID) { error, team in
        if let targetTeam = team {
          noti.targetName = targetTeam.teamName
          noti.teamInfo = Team(teamInfo: targetTeam)
          completion(noti)
        }
      }
    case .superTeamApply, .superTeamInvite, .superTeamApplyReject, .superTeamInviteReject:
      // super team
      guard let targetID = noti.targetID else {
        break
      }
      NIMSDK.shared().superTeamManager.fetchTeamInfo(targetID) { error, team in
        if let targetTeam = team {
          noti.targetName = targetTeam.teamName
          noti.teamInfo = Team(teamInfo: targetTeam)
          completion(noti)
        }
      }
    case .addFriendDirectly, .addFriendRequest, .addFriendVerify, .addFriendReject:
      guard let source = noti.sourceID else {
        break
      }

      UserInfoProvider.shared.fetchUserInfo([source]) { error, users in
        if let user = users?.first {
          noti.userInfo = user
          completion(noti)
        }
      }
    default: break
    }
  }

  // MARK: systemNotificationManagerDelegate

  public func onReceive(_ notification: NIMSystemNotification) {
    print("onReceive:\(notification)")
    //        invoke {
    //            $0.onRecieveNotification(notification:detailNotification(notification: notification))
    //        }
    detailNotification(notification: notification) { [weak self] xNoti in
      (self?.mutiDelegate ?? MultiDelegate<SystemMessageProviderDelegate>(strongReferences: false)) |> { delegate in
        delegate
          .onRecieveNotification(
            notification: xNoti
          )
      }
    }
  }

  public func onSystemNotificationCountChanged(_ unreadCount: Int) {
    print("unreadCount:\(unreadCount)")
    mutiDelegate |> { delegate in
      delegate.onNotificationUnreadCountChanged(count: unreadCount)
    }
    //        invoke {
    //            $0.onNotificationUnreadCountChanged(count: unreadCount)
    //        }
  }

  public func deleteNoti() {
    NIMSDK.shared().systemNotificationManager.deleteAllNotifications()
  }

  public func getUnreadCount() -> Int {
    NIMSDK.shared().systemNotificationManager.allUnreadCount()
  }

  public func clearUnreadCount() {
    NIMSDK.shared().systemNotificationManager.markAllNotificationsAsRead()
  }

  /// 标记单条系统消息已读
  /// - Parameter notification: 系统消息
  public func clearSingleUnreadCount(_ notification: NIMSystemNotification) {
    NIMSDK.shared().systemNotificationManager.markNotifications(asRead: notification)
  }

  public func sendNotificationMessage(_ noti: NIMCustomSystemNotification, _ session: NIMSession,
                                      _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().systemNotificationManager
      .sendCustomNotification(noti, to: session) { error in
        completion(error)
      }
  }

  // MARK: Delegate

  public func addDelegate(delegate: SystemMessageProviderDelegate) {
    mutiDelegate.addDelegate(delegate)
  }

  public func removeDelegate(delegate: SystemMessageProviderDelegate) {
    mutiDelegate.removeDelegate(delegate)
  }

  public func onReceive(_ notification: NIMCustomSystemNotification) {
    mutiDelegate |> { delegate in
      delegate.onReceive(notification)
    }
  }
}
