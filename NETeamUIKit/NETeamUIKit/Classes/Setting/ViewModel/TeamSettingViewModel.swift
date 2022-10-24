// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NETeamKit
import NIMSDK
import UIKit

protocol TeamSettingViewModelDelegate: NSObjectProtocol {
  func didClickChangeNick()
  func didChangeInviteModeClick(_ model: SettingCellModel)
  func didUpdateTeamInfoClick(_ model: SettingCellModel)
  func didClickHistoryMessage()
  func didNeedRefreshUI()
  func didError(_ error: Error)
}

@objcMembers
public class TeamSettingViewModel: NSObject {
  var sectionData = [SettingSectionModel]()

  var searchResultInfos: [HistoryMessageModel]?

  var teamInfoModel: TeamInfoModel?

  let repo = TeamRepo()

  var memberInTeam: NIMTeamMember?

  weak var delegate: TeamSettingViewModelDelegate?

  private let className = "TeamSettingViewModel"

  override public init() {}

  func getData() {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    sectionData.removeAll()
    sectionData.append(getTwoSection())
    print("current team type : ", teamInfoModel?.team?.type.rawValue as Any)
    if let type = teamInfoModel?.team?.type, type == .advanced {
      sectionData.append(getThreeSection())
      sectionData.append(getFourSection())
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

    /*
     let mark = SettingCellModel()
     mark.cellName = localizable("mark")
     mark.type = SettingCellType.SettingArrowCell.rawValue
     mark.cornerType = .topLeft.union(.topRight)
      */
    weak var weakSelf = self
    let history = SettingCellModel()
    history.cellName = localizable("history")
    history.type = SettingCellType.SettingArrowCell.rawValue
    history.cornerType = .topLeft.union(.topRight)
    history.cellClick = {
      weakSelf?.delegate?.didClickHistoryMessage()
    }

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
            if let err = error {
              weakSelf?.delegate?.didNeedRefreshUI()
              weakSelf?.delegate?.didError(err)
            } else {
              remind.switchOpen = false
            }
          }
        } else {
//                    weakSelf?.repo.updateNoti(.none, tid)
          weakSelf?.repo.setTeamNotify(.none, tid) { error in
            if let err = error {
              weakSelf?.delegate?.didNeedRefreshUI()
              weakSelf?.delegate?.didError(err)
            } else {
              remind.switchOpen = true
            }
          }
        }
      }
    }

    let setTop = SettingCellModel()
    setTop.cellName = localizable("session_set_top")
    setTop.type = SettingCellType.SettingSwitchCell.rawValue
    setTop.cornerType = .bottomLeft.union(.bottomRight)

    if let tid = teamInfoModel?.team?.teamId {
      let session = NIMSession(tid, type: .team)
      setTop.switchOpen = repo.isStickTop(session)
    }

    setTop.swichChange = { isOpen in
      if let tid = weakSelf?.teamInfoModel?.team?.teamId {
        let session = NIMSession(tid, type: .team)
        if isOpen {
          let params = NIMAddStickTopSessionParams(session: session)
          weakSelf?.repo.addStickTop(params: params) { error, info in
            print("add stick : ", error as Any)
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
              print("remote stick : ", error as Any)
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

    model.cellModels.append(contentsOf: [history, remind, setTop])

    return model
  }

  private func getThreeSection() -> SettingSectionModel {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    let model = SettingSectionModel()

    weak var weakSelf = self
    let nick = SettingCellModel()
    nick.cellName = localizable("team_nick")
    nick.type = SettingCellType.SettingArrowCell.rawValue
    nick.cellClick = {
      weakSelf?.delegate?.didClickChangeNick()
    }

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
          if let err = error {
            forbiddenWords.switchOpen = !isOpen
            weakSelf?.delegate?.didNeedRefreshUI()
            weakSelf?.delegate?.didError(err)
          } else {
            forbiddenWords.switchOpen = isOpen
          }
        }
      }
    }

    if isOwner() {
      nick.cornerType = .topLeft.union(.topRight)
      forbiddenWords.cornerType = .bottomLeft.union(.bottomRight)
      model.cellModels.append(contentsOf: [nick, forbiddenWords])
    } else {
      nick.cornerType = .topLeft.union(.topRight).union(.bottomLeft).union(.topRight)
      model.cellModels.append(contentsOf: [nick])
    }

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

    invitePermission.cornerType = .topLeft.union(.topRight)

    let modifyPermission = SettingCellModel()
    modifyPermission.cellName = localizable("modify_team_info_permission")
    modifyPermission.type = SettingCellType.SettingSelectCell.rawValue
    modifyPermission.cornerType = .bottomLeft.union(.bottomRight)
    modifyPermission.rowHeight = 73
    if let updateMode = teamInfoModel?.team?.updateInfoMode, updateMode == .all {
      modifyPermission.subTitle = localizable("team_all")
    } else {
      modifyPermission.subTitle = localizable("team_owner")
    }

    modifyPermission.cellClick = {
      weakSelf?.delegate?.didUpdateTeamInfoClick(modifyPermission)
    }
    // 产品策略调整，暂时移除该功能
    /*
     let agreePermission = SettingCellModel()
       agreePermission.cellName = localizable("agree")
       agreePermission.type = SettingCellType.SettingSwitchCell.rawValue
       agreePermission.cornerType = .bottomLeft.union(.bottomRight)
     if let inviteMode = teamInfoModel?.team?.beInviteMode, inviteMode == .needAuth {
         agreePermission.switchOpen = true
     }
       agreePermission.swichChange = { isOpen in
       if let tid = weakSelf?.teamInfoModel?.team?.teamId {
         if isOpen == true {
           weakSelf?.repo.updateBeInviteMode(.needAuth, tid) { error in
             print("join mode : ", error as Any)
             if let err = error {
                 agreePermission.switchOpen = false
               weakSelf?.delegate?.didNeedRefreshUI()
               weakSelf?.delegate?.didError(err)
             } else {
               weakSelf?.teamInfoModel?.team?.joinMode = .needAuth
                 agreePermission.switchOpen = true
             }
           }

         } else {
           weakSelf?.repo.updateBeInviteMode(.noAuth, tid) { error in
             print("join mode : ", error as Any)
             if let err = error {
                 agreePermission.switchOpen = true
               weakSelf?.delegate?.didNeedRefreshUI()
               weakSelf?.delegate?.didError(err)
             } else {
               weakSelf?.teamInfoModel?.team?.joinMode = .noAuth
                 agreePermission.switchOpen = false
             }
           }
         }
       }
     }
     */

    if isOwner() {
      model.cellModels.append(contentsOf: [invitePermission, modifyPermission])
    }

    return model
  }

  func getTeamInfo(_ teamId: String, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", teamId:\(teamId)")
    weak var weakSelf = self
    repo.fetchTeamInfo(teamId) { error, teamInfo in
      weakSelf?.teamInfoModel = teamInfo
      print("get team info user: ", teamInfo?.users as Any)
      print("get team info team: ", teamInfo?.team as Any)
      print("get team info error: ", error as Any)

      if error == nil {
        weakSelf?.getData()
        weakSelf?.getCurrentMember(IMKitEngine.instance.imAccid, teamId)
      }
      completion(error)
    }
  }

  public func dismissTeam(_ teamId: String, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", teamId:\(teamId)")
    repo.dismissTeam(teamId, completion)
  }

  public func quitTeam(_ teamId: String, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", teamId:\(teamId)")
    repo.quitTeam(teamId, completion)
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
      if IMKitEngine.instance.isMySelf(accid) {
        return true
      }
    }
    return false
  }

  public func updateInfoMode(_ mode: NIMTeamUpdateInfoMode, _ teamId: String,
                             _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", mode:\(mode.rawValue)")
    repo.updateTeamInfoPrivilege(mode, teamId, completion)
  }

  public func updateInviteMode(_ mode: NIMTeamInviteMode, _ teamId: String,
                               _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", mode:\(mode.rawValue)")
    repo.updateInviteMode(mode, teamId, completion)
  }

  public func isNormalTeam() -> Bool {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    if let type = teamInfoModel?.team?.type, type == .normal {
      return true
    }
    return false
  }

  public func searchMessages(_ session: NIMSession, option: NIMMessageSearchOption,
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
}
