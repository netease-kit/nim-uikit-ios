// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit
import NECoreKit

@objc
public protocol TeamJoinActionViewModelDelegate: NSObjectProtocol {
  func tableviewReload()
}

@objcMembers
open class TeamJoinActionViewModel: NSObject, NETeamListener {
  let teamRepo = TeamRepo.shared
  public weak var delegate: TeamJoinActionViewModelDelegate?
  var teamJoinActions = [NETeamJoinAction]()
  var offset: Int = 0 // 查询的偏移量
  var finished: Bool = false // 是否还有数据
  var pageMaxLimit: Int = 100 // 查询的每页数量

  override public init() {
    super.init()
    teamRepo.addTeamListener(self)
  }

  deinit {
    teamRepo.removeTeamListener(self)
  }

  /// 加载(更多)入群申请消息
  /// - Parameter firstLoad: 是否是首次加载
  /// - Parameter completin: 完成回调
  open func loadTeamJoinActionList(_ firstLoad: Bool, _ completin: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)

    let offset = firstLoad ? 0 : offset
    if firstLoad {
      finished = false
      teamJoinActions.removeAll()
    }

    if finished {
      completin(nil)
      return
    }

    let option = V2NIMTeamJoinActionInfoQueryOption()
    option.offset = offset
    option.limit = pageMaxLimit

    teamRepo.getTeamJoinActionInfoList(option) { [weak self] result, error in
      if let err = error {
        completin(err)
      } else if let result = result {
//        self?.offset = result.offset
        self?.finished = result.finished

        for item in result.infos ?? [] {
          self?.convertToNETeamJoinAction(item) { _ in
          }
        }

        completin(nil)
      }
    }
  }

  /// 转换（聚合）入群申请
  /// - Parameters:
  ///   - item: 入群申请
  ///   - move: 是否移动到最前
  ///   - completin: 完成回调
  open func convertToNETeamJoinAction(_ item: V2NIMTeamJoinActionInfo,
                                      _ move: Bool = false,
                                      _ completin: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    var isExist = false
    for (index, neItem) in teamJoinActions.enumerated() {
      if neItem.isEqualTo(item) {
        isExist = true

        // 未读数
        if item.timestamp > neTeamJoinActionReadTime {
          neItem.unreadCount += 1
        }

        // 移动到最前
        if move, index != 0 {
          teamJoinActions.remove(at: index)
          teamJoinActions.insert(neItem, at: 0)
        }
        delegate?.tableviewReload()
        break
      }
    }

    if isExist {
      completin(nil)
      return
    }

    let teamJoinActionInfo = NETeamJoinAction(item)
    let teamJoinActionsCount = teamJoinActions.count
    let insertIndex = move ? 0 : teamJoinActions.isEmpty ? 0 : teamJoinActionsCount
    teamJoinActions.insert(teamJoinActionInfo, at: insertIndex)

    let teamId = teamJoinActionInfo.nimTeamJoinAction.teamId
    teamRepo.getTeamInfo(teamId, .TEAM_TYPE_NORMAL) { [weak self] team, error in
      teamJoinActionInfo.displayTeam = team
      let teamName = team?.name ?? teamId
      switch teamJoinActionInfo.nimTeamJoinAction.actionType {
      case .TEAM_JOIN_ACTION_TYPE_APPLICATION:
        teamJoinActionInfo.detail = localizable("apply_to_the_team_of") + " \(teamName)"
      case .TEAM_JOIN_ACTION_TYPE_INVITATION:
        teamJoinActionInfo.detail = localizable("invite_to_join_the_team_of") + " \(teamName)"
      case .TEAM_JOIN_ACTION_TYPE_REJECT_APPLICATION:
        teamJoinActionInfo.detail = localizable("rejected_the_apply") + " \(teamName)"
      case .TEAM_JOIN_ACTION_TYPE_REJECT_INVITATION:
        teamJoinActionInfo.detail = localizable("refused_the_invitation") + " \(teamName)"
      default:
        teamJoinActionInfo.detail = ""
      }
      self?.delegate?.tableviewReload()
    }

    // 查询操作者信息
    ContactRepo.shared.getUserWithFriend(accountIds: [teamJoinActionInfo.displayUserId]) { [weak self] users, error in
      if let user = users?.first {
        teamJoinActionInfo.displayUserWithFriend = user
        self?.delegate?.tableviewReload()
      }
    }
  }

  /// 设置所有入群申请已读
  /// - Parameter completion: 完成回调
  open func setTeamJoinActionRead() {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)

    neTeamJoinActionReadTime = Date().timeIntervalSince1970
    UserDefaults.standard.setValue(neTeamJoinActionReadTime, forKey: keyTeamJoinActionReadTime)
    for application in teamJoinActions {
      application.unreadCount = 0
    }

    DispatchQueue.main.async {
      NotificationCenter.default.post(name: NENotificationName.clearValidationMessageUnreadCount, object: nil)
    }
  }

  /// 接受/拒绝入群申请
  /// - Parameters:
  ///   - action: 申请添加入群的相关信息
  ///   - status: 入群申请的处理状态
  open func changeTeamJoinActionStatus(_ action: V2NIMTeamJoinActionInfo,
                                       _ status: V2NIMTeamJoinActionStatus) {
    var changedIndex = -1
    for (index, item) in teamJoinActions.enumerated() {
      if item.isEqualTo(action, false) {
        item.handleStatus = status
        item.unreadCount = 0
        changedIndex = index
        break
      }
    }

    if changedIndex > -1 {
      var index = changedIndex + 1
      while index < teamJoinActions.count {
        if teamJoinActions[index].isEqualTo(action, true) {
          teamJoinActions.remove(at: index)
        } else {
          index += 1
        }
      }
    }
  }

  /// 同意入群申请
  /// - Parameters:
  ///   - action: 入群申请
  ///   - completion: 完成回调
  open func agreeRequest(action: V2NIMTeamJoinActionInfo,
                         _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", operatorAccountId:\(String(describing: action.operatorAccountId))")
    if action.actionType == .TEAM_JOIN_ACTION_TYPE_APPLICATION {
      teamRepo.acceptJoinApplication(action) { [weak self] error in
        if let err = error {
          print(err.localizedDescription)
        } else {
          self?.changeTeamJoinActionStatus(action, .TEAM_JOIN_ACTION_STATUS_AGREED)
        }
        completion(error)
      }
    } else if action.actionType == .TEAM_JOIN_ACTION_TYPE_INVITATION {
      teamRepo.acceptInvitation(invitationInfo: action) { [weak self] team, error in
        if let err = error {
          print(err.localizedDescription)
        } else {
          self?.changeTeamJoinActionStatus(action, .TEAM_JOIN_ACTION_STATUS_AGREED)
        }
        completion(error)
      }
    }
  }

  /// 拒绝入群申请
  /// - Parameters:
  ///   - action: 入群申请
  ///   - completion: 完成回调
  open func refuseRequest(action: V2NIMTeamJoinActionInfo,
                          _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", operatorAccountId:\(String(describing: action.operatorAccountId))")
    if action.actionType == .TEAM_JOIN_ACTION_TYPE_APPLICATION {
      teamRepo.rejectJoinApplication(action, nil) { [weak self] error in
        if let err = error {
          print(err.localizedDescription)
        } else {
          self?.changeTeamJoinActionStatus(action, .TEAM_JOIN_ACTION_STATUS_REJECTED)
        }
        completion(error)
      }
    } else if action.actionType == .TEAM_JOIN_ACTION_TYPE_INVITATION {
      teamRepo.rejectInvitation(invitationInfo: action, postscript: nil) { [weak self] error in
        if let err = error {
          print(err.localizedDescription)
        } else {
          self?.changeTeamJoinActionStatus(action, .TEAM_JOIN_ACTION_STATUS_REJECTED)
        }
        completion(error)
      }
    }
  }

  /// 清空入群申请通知
  open func clearNotification(_ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    teamRepo.clearAllTeamJoinActionInfo { [weak self] error in
      if let err = error {
        print(err.localizedDescription)
      }
      self?.teamJoinActions.removeAll()
      completion(error)
    }
  }

  // MARK: - NETeamListener

  /// 入群操作回调
  /// - Parameter joinActionInfo： 群信息
  public func onReceive(_ joinActionInfo: V2NIMTeamJoinActionInfo) {
    convertToNETeamJoinAction(joinActionInfo, true) { error in
    }
  }
}
