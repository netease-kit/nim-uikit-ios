// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIMKit
import NIMSDK
import UIKit

protocol TeamSettingViewModelDelegate: NSObjectProtocol {
  func didClickChangeNick()
  func didChangeInviteModeClick(_ model: SettingCellModel)
  func didUpdateTeamInfoClick(_ model: SettingCellModel)
  func didClickHistoryMessage()
  func didNeedRefreshUI()
  func didError(_ error: NSError)
  func didClickMark()
  func didClickTeamManage()
}

@objcMembers
open class TeamSettingViewModel: NSObject, NIMTeamManagerDelegate {
  public var sectionData = [SettingSectionModel]()

  public var searchResultInfos: [HistoryMessageModel]?

  public var teamInfoModel: TeamInfoModel?

  public let repo = TeamRepo.shared

  public var memberInTeam: NIMTeamMember?

  weak var delegate: TeamSettingViewModelDelegate?

  private let className = "TeamSettingViewModel"

  public var teamSettingType: TeamSettingType = .Discuss

  override public init() {
    super.init()
    NIMSDK.shared().teamManager.add(self)
  }

  deinit {
    NIMSDK.shared().teamManager.remove(self)
  }

  func getData() {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    sectionData.removeAll()
    sectionData.append(getTwoSection())
    print("current team type : ", teamInfoModel?.team?.type.rawValue as Any)
    if let type = teamInfoModel?.team?.type, type == .advanced {
      if teamInfoModel?.team?.clientCustomInfo?.contains(discussTeamKey) == true {
        return
      }
      sectionData.append(getThreeSection())
    }
  }

  private func getOneSection() -> SettingSectionModel {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    let model = SettingSectionModel()
    let cellModel = SettingCellModel()
    cellModel.type = SettingCellType.SettingHeaderCell.rawValue
    cellModel.rowHeight = 160
    cellModel.cornerType = .topLeft.union(.topRight).union(.bottomLeft).union(.bottomRight)
    model.cellModels.append(cellModel)
    return model
  }

  private func getTwoSection() -> SettingSectionModel {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    let model = SettingSectionModel()

    weak var weakSelf = self

    // 标记
    let mark = SettingCellModel()
    mark.cellName = localizable("mark")
    mark.type = SettingCellType.SettingArrowCell.rawValue
    mark.cellClick = {
      weakSelf?.delegate?.didClickMark()
    }

    // 历史记录
    let history = SettingCellModel()
    history.cellName = localizable("historical_record")
    history.type = SettingCellType.SettingArrowCell.rawValue
    history.cellClick = {
      weakSelf?.delegate?.didClickHistoryMessage()
    }

    // 开启消息提醒
    let remind = SettingCellModel()
    remind.cellName = localizable("message_remind")
    remind.type = SettingCellType.SettingSwitchCell.rawValue

    if let noti = teamInfoModel?.team?.notifyStateForNewMsg, noti == .all {
      remind.switchOpen = true
    }
    remind.swichChange = { isOpen in
      if let tid = weakSelf?.teamInfoModel?.team?.teamId {
        if isOpen == true {
          // weakSelf?.repo.updateNoti(.all, tid)
          weakSelf?.repo.setTeamNotify(.all, tid) { error in
            if let err = error as? NSError {
              weakSelf?.delegate?.didNeedRefreshUI()
              weakSelf?.delegate?.didError(err)
            } else {
              remind.switchOpen = false
            }
          }
        } else {
          //                    weakSelf?.repo.updateNoti(.none, tid)
          weakSelf?.repo.setTeamNotify(.none, tid) { error in
            if let err = error as? NSError {
              weakSelf?.delegate?.didNeedRefreshUI()
              weakSelf?.delegate?.didError(err)
            } else {
              remind.switchOpen = true
            }
          }
        }
      }
    }

    // 聊天置顶
    let setTop = SettingCellModel()
    setTop.cellName = localizable("session_set_top")
    setTop.type = SettingCellType.SettingSwitchCell.rawValue

    if let tid = teamInfoModel?.team?.teamId {
      let session = NIMSession(tid, type: .team)
      setTop.switchOpen = repo.isStickTop(session)
    }

    setTop.swichChange = { isOpen in
      if let tid = weakSelf?.teamInfoModel?.team?.teamId {
        let session = NIMSession(tid, type: .team)
        if isOpen {
          // 不存在最近会话的置顶，先创建最近会话
          if weakSelf?.getRecenterSession() == nil {
            NELog.infoLog(weakSelf?.className() ?? "", desc: #function + "addRecentetSession")
            weakSelf?.addRecentetSession()
          }
          let params = NIMAddStickTopSessionParams(session: session)
          weakSelf?.repo.addStickTop(params: params) { error, info in
            NELog.infoLog(weakSelf?.className() ?? "", desc: #function + "addStickTop error : \(error?.localizedDescription ?? "") ")
            if let err = error {
              weakSelf?.delegate?.didNeedRefreshUI()
              weakSelf?.delegate?.didError(err)
            } else {
              setTop.switchOpen = true
            }
          }
        } else {
          if let info = weakSelf?.repo.getTopSessionInfo(session) {
            weakSelf?.repo.removeStickTop(params: info) { error, info in
              NELog.infoLog(weakSelf?.className() ?? "", desc: #function + "removeStickTop error : \(error?.localizedDescription ?? "") ")
              if let err = error {
                weakSelf?.delegate?.didNeedRefreshUI()
                weakSelf?.delegate?.didError(err)
              } else {
                setTop.switchOpen = false
              }
            }
          }
        }
      }
    }

    let nick = SettingCellModel()
    nick.cellName = localizable("team_nick")
    nick.type = SettingCellType.SettingArrowCell.rawValue
    nick.cellClick = {
      weakSelf?.delegate?.didClickChangeNick()
    }

    model.cellModels.append(mark)
    model.cellModels.append(history)
    model.cellModels.append(remind)
    model.cellModels.append(setTop)
    if isNormalTeam() == false {
      model.cellModels.append(nick)
    }

    model.setCornerType()
    return model
  }

  // 群昵称/群禁言
  private func getThreeSection() -> SettingSectionModel {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    let model = SettingSectionModel()
    weak var weakSelf = self

    let forbiddenWords = SettingCellModel()
    forbiddenWords.cellName = localizable("team_no_speak")
    forbiddenWords.type = SettingCellType.SettingSwitchCell.rawValue

    if let mute = teamInfoModel?.team?.inAllMuteMode() {
      forbiddenWords.switchOpen = mute
    }
    forbiddenWords.swichChange = { isOpen in
      if let tid = weakSelf?.teamInfoModel?.team?.teamId {
        weakSelf?.repo.muteAllMembers(isOpen, tid) { error in
          print("update mute error : ", error as Any)
          if let err = error as? NSError {
            forbiddenWords.switchOpen = !isOpen
            weakSelf?.delegate?.didNeedRefreshUI()
            weakSelf?.delegate?.didError(err)
          } else {
            forbiddenWords.switchOpen = isOpen
          }
        }
      }
    }

    // 群管理
    let teamManager = SettingCellModel()
    teamManager.cellName = localizable("manage_team")
    teamManager.type = SettingCellType.SettingArrowCell.rawValue
    teamManager.cellClick = {
      weakSelf?.delegate?.didClickTeamManage()
    }

    if isOwner() {
      model.cellModels.append(forbiddenWords)
    }

    if isOwner() || isManager() {
      model.cellModels.append(teamManager)
    }
    model.setCornerType()
    return model
  }

  private func getFourSection() -> SettingSectionModel {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    weak var weakSelf = self
    let model = SettingSectionModel()

    let invitePermission = SettingCellModel()
    invitePermission.cellName = localizable("invite_permission")
    invitePermission.type = SettingCellType.SettingSelectCell.rawValue
    invitePermission.rowHeight = 73

    if let inviteMode = teamInfoModel?.team?.inviteMode, inviteMode == .all {
      invitePermission.subTitle = localizable("team_all")
    } else {
      invitePermission.subTitle = localizable("team_owner")
    }

    invitePermission.cellClick = {
      weakSelf?.delegate?.didChangeInviteModeClick(invitePermission)
    }

    let modifyPermission = SettingCellModel()
    modifyPermission.cellName = localizable("modify_team_info_permission")
    modifyPermission.type = SettingCellType.SettingSelectCell.rawValue
    modifyPermission.rowHeight = 73
    if let updateMode = teamInfoModel?.team?.updateInfoMode, updateMode == .all {
      modifyPermission.subTitle = localizable("team_all")
    } else {
      modifyPermission.subTitle = localizable("team_owner")
    }

    modifyPermission.cellClick = {
      weakSelf?.delegate?.didUpdateTeamInfoClick(modifyPermission)
    }

    if isOwner() {
      model.cellModels.append(contentsOf: [invitePermission, modifyPermission])
      model.setCornerType()
    }

    return model
  }

  func getTeamInfo(_ teamId: String, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", teamId:\(teamId)")
    weak var weakSelf = self
    repo.fetchTeamInfo(teamId) { error, teamInfo in
      weakSelf?.teamInfoModel = teamInfo
      if error == nil {
        weakSelf?.getData()
        weakSelf?.getCurrentMember(IMKitClient.instance.imAccid(), teamId)
      }
      completion(error)
    }
  }

  public func dismissTeam(_ teamId: String, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", teamId:\(teamId)")
    repo.dismissTeam(teamId, completion)
  }

  open func quitTeam(_ teamId: String, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", teamId:\(teamId)")
    repo.quitTeam(teamId, completion)
  }

  open func getTopSessionInfo(_ session: NIMSession) -> NIMStickTopSessionInfo {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", teamId:\(session.sessionId)")
    return repo.getTopSessionInfo(session)
  }

  open func removeStickTop(params: NIMStickTopSessionInfo,
                           _ completion: @escaping (NSError?, NIMStickTopSessionInfo?)
                             -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", teamId:\(params.session.sessionId)")
    repo.removeStickTop(params: params, completion)
  }

  @discardableResult
  func getCurrentMember(_ userId: String, _ teamId: String?) -> NIMTeamMember? {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", userId:\(userId)")
    if memberInTeam == nil, let tid = teamId {
      memberInTeam = repo.getMemberInfo(userId, tid)
    }
    return memberInTeam
  }

  func isOwner() -> Bool {
    NELog.infoLog(ModuleName + " " + className, desc: #function)

    if let accid = teamInfoModel?.team?.owner {
      if IMKitClient.instance.isMySelf(accid) {
        return true
      }
    }
    return false
  }

  func isManager() -> Bool {
    if let tid = teamInfoModel?.team?.teamId, let currentTeamMebmer = repo.getMemberInfo(IMKitClient.instance.imAccid(), tid) {
      if currentTeamMebmer.type == .manager {
        return true
      }
    }
    return false
  }

  private func sampleMemberId(arr: [TeamMemberInfoModel], owner: String) -> String? {
    var index = arc4random_uniform(UInt32(arr.count))
    while arr[Int(index)].teamMember?.userId == owner {
      if arr.count == 1 {
        return owner
      }
      index = arc4random_uniform(UInt32(arr.count))
    }
    return arr[Int(index)].teamMember?.userId
  }

  func transferTeamOwner(_ completion: @escaping (Error?) -> Void) {
    if isOwner() == false {
      completion(NSError(domain: "imuikit", code: -1, userInfo: [NSLocalizedDescriptionKey: "not team manager"]))
      return
    }

    guard let members = teamInfoModel?.users, let teamId = teamInfoModel?.team?.teamId else {
      completion(NSError(domain: "imuikit", code: -1, userInfo: [NSLocalizedDescriptionKey: "team info error"]))
      return
    }

    var userId = NIMSDK.shared().loginManager.currentAccount()
    if members.count == 1 {
      dismissTeam(teamId, completion)
      return
    } else if let sampleOwnerId = sampleMemberId(arr: members, owner: userId) {
      userId = sampleOwnerId
    }

    if userId == NIMSDK.shared().loginManager.currentAccount() {
      dismissTeam(teamId, completion)
      return
    }

    NIMSDK.shared().teamManager.transferManager(withTeam: teamId, newOwnerId: userId, isLeave: true) { error in
      completion(error)
    }
  }

  open func updateInfoMode(_ mode: NIMTeamUpdateInfoMode, _ teamId: String,
                           _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", mode:\(mode.rawValue)")
    repo.updateTeamInfoPrivilege(mode, teamId, completion)
  }

  open func updateInviteMode(_ mode: NIMTeamInviteMode, _ teamId: String,
                             _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", mode:\(mode.rawValue)")
    repo.updateInviteMode(mode, teamId, completion)
  }

  open func isNormalTeam() -> Bool {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    if let type = teamInfoModel?.team?.type, type == .normal {
      return true
    }
    if teamInfoModel?.team?.clientCustomInfo?.contains(discussTeamKey) == true {
      return true
    }
    return false
  }

  open func searchMessages(_ session: NIMSession, option: NIMMessageSearchOption,
                           _ completion: @escaping (NSError?, [HistoryMessageModel]?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", session:\(session.sessionId)")
    weak var weakSelf = self
    repo.searchMessages(session, option: option) { error, messages in
      if error == nil {
        weakSelf?.searchResultInfos = messages
        completion(nil, weakSelf?.searchResultInfos)
      } else {
        completion(error, nil)
      }
    }
  }

  open func onTeamMemberRemoved(_ team: NIMTeam, withMembers memberIDs: [String]?) {
    if let accids = memberIDs {
      accids.forEach { accid in
        if let users = teamInfoModel?.users {
          for (i, m) in users.enumerated() {
            if m.nimUser?.userId == accid {
              teamInfoModel?.users.remove(at: i)
            }
          }
        }
      }
      delegate?.didNeedRefreshUI()
    }
  }

  public func onTeamMemberChanged(_ team: NIMTeam) {
    if let tid = teamInfoModel?.team?.teamId, tid != team.teamId {
      return
    }
    teamInfoModel?.team = team
    getCurrentMember(IMKitClient.instance.imAccid(), teamInfoModel?.team?.teamId)
    getData()
    delegate?.didNeedRefreshUI()
  }

  open func onTeamUpdated(_ team: NIMTeam) {
    if let teamId = teamInfoModel?.team?.teamId, teamId != team.teamId {
      return
    }
    teamInfoModel?.team = team
  }

  open func inviterUsers(_ accids: [String], _ tid: String, _ completion: @escaping (NSError?, [NIMTeamMember]?) -> Void) {
    repo.inviteUser(accids, tid, nil, nil) { error, members in
      completion(error as NSError?, members)
    }
  }

  public func addRecentetSession() {
    if let tid = teamInfoModel?.team?.teamId {
      let currentSession = NIMSession(tid, type: .team)
      repo.addRecentSession(currentSession)
    }
  }

  public func getRecenterSession() -> NIMRecentSession? {
    if let tid = teamInfoModel?.team?.teamId {
      let currentSession = NIMSession(tid, type: .team)
      return repo.getRecentSession(currentSession)
    }
    return nil
  }
}
