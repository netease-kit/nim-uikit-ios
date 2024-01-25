//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonKit
import NIMSDK
import UIKit

public protocol TeamManageViewModelDelegate: NSObjectProtocol {
  func didChangeInviteModeClick(_ model: SettingCellModel)
  func didUpdateTeamInfoClick(_ model: SettingCellModel)
  func didAtPermissionClick(_ model: SettingCellModel)
  func didManagerClick()
  func didRefreshData()
}

@objc
@objcMembers
open class TeamManageViewModel: NSObject, NIMTeamManagerDelegate {
  let repo = TeamRepo.shared

  let chatRepo = ChatRepo.shared

  public var teamInfoModel: TeamInfoModel?

  var sectionData = [SettingSectionModel]()

  public var managerUsers = [TeamMemberInfoModel]()

  var isRequestData = false

  weak var delegate: TeamManageViewModelDelegate?

  override public init() {
    super.init()
    NIMSDK.shared().teamManager.add(self)
  }

  open func getSectionData() {
    sectionData.removeAll()
    if teamInfoModel?.team?.owner == IMKitClient.instance.imAccid() {
      sectionData.append(getTopSection())
    }
    sectionData.append(getMidSection())
  }

  open func getTeamInfo(_ tid: String, _ completion: @escaping (Error?) -> Void) {
    if isRequestData == true {
      return
    }
    weak var weakSelf = self
    isRequestData = true
    repo.fetchTeamInfo(tid) { error, teamInfo in
      weakSelf?.isRequestData = false
      if error == nil {
        weakSelf?.managerUsers.removeAll()
      }
      teamInfo?.users.forEach { model in
        if model.teamMember?.type == .manager {
          weakSelf?.managerUsers.append(model)
        }
      }
      weakSelf?.teamInfoModel = teamInfo
      weakSelf?.getSectionData()
      completion(error)
    }
  }

  open func getTopSection() -> SettingSectionModel {
    NELog.infoLog(ModuleName + " " + className(), desc: #function)
    weak var weakSelf = self
    let model = SettingSectionModel()
    let manager = SettingCellLabelArrowModel()
    manager.cellName = localizable("manage_manger")
    manager.type = SettingCellType.SettingArrowCell.rawValue
    manager.rowHeight = 56
    manager.arrowLabelText = "\(managerUsers.count)"
    model.cellModels.append(contentsOf: [manager])
    model.setCornerType()
    manager.cellClick = {
      weakSelf?.delegate?.didManagerClick()
    }
    return model
  }

  open func getMidSection() -> SettingSectionModel {
    NELog.infoLog(ModuleName + " " + className(), desc: #function)
    weak var weakSelf = self
    let model = SettingSectionModel()

    let editTeam = SettingCellModel()
    editTeam.cellName = localizable("who_edit_team_info")
    editTeam.type = SettingCellType.SettingSelectCell.rawValue
    editTeam.rowHeight = 73

    if let updateMode = teamInfoModel?.team?.updateInfoMode, updateMode == .all {
      editTeam.subTitle = localizable("team_all")
    } else {
      editTeam.subTitle = localizable("team_owner_and_manager")
    }

    editTeam.cellClick = {
      weakSelf?.delegate?.didUpdateTeamInfoClick(editTeam)
    }

    let invitePermission = SettingCellModel()
    invitePermission.cellName = localizable("who_edit_user_info")
    invitePermission.type = SettingCellType.SettingSelectCell.rawValue
    invitePermission.rowHeight = 73
    if let inviteMode = teamInfoModel?.team?.inviteMode, inviteMode == .all {
      invitePermission.subTitle = localizable("team_all")
    } else {
      invitePermission.subTitle = localizable("team_owner_and_manager")
    }

    invitePermission.cellClick = {
      weakSelf?.delegate?.didChangeInviteModeClick(invitePermission)
    }

    let atAll = SettingCellModel()
    atAll.cellName = localizable("who_at_all")
    atAll.type = SettingCellType.SettingSelectCell.rawValue
    atAll.rowHeight = 73
    atAll.subTitle = localizable("team_owner_and_manager")
    atAll.subTitle = getTeamAtPermissionValue()

    atAll.cellClick = {
      weakSelf?.delegate?.didAtPermissionClick(atAll)
    }

    model.cellModels.append(contentsOf: [editTeam, invitePermission, atAll])
    model.setCornerType()

    return model
  }

  open func updateTeamAtPermission(_ isManager: Bool, _ completion: @escaping (Error?) -> Void) {
    let value = isManager == true ? allowAtManagerValue : allowAtAllValue
    guard let tid = teamInfoModel?.team?.teamId else {
      return
    }
    let latestTeam = repo.getTeam(tid)
    if let custom = latestTeam?.clientCustomInfo {
      if var dic = NECommonUtil.getDictionaryFromJSONString(custom) as? [String: Any] {
        dic[keyAllowAtAll] = value
        let info = NECommonUtil.getJSONStringFromDictionary(dic)
        repo.updateTeamCustomInfo(info, tid) { error in
          completion(error)
        }
      }
    } else {
      var dic = [String: Any]()
      dic[keyAllowAtAll] = value
      let info = NECommonUtil.getJSONStringFromDictionary(dic)
      repo.updateTeamCustomInfo(info, tid) { error in
        completion(error)
      }
    }
  }

  func getTeamAtPermissionValue() -> String {
    if let custom = teamInfoModel?.team?.clientCustomInfo {
      if let dic = NECommonUtil.getDictionaryFromJSONString(custom) as? [String: Any] {
        if let value = dic[keyAllowAtAll] as? String {
          if value == allowAtManagerValue {
            return localizable("team_owner_and_manager")
          }
        }
      }
    }
    return localizable("team_all")
  }

  open func onTeamMemberChanged(_ team: NIMTeam) {
    updateTeamInfo(team)
  }

  open func onTeamUpdated(_ team: NIMTeam) {
    updateTeamInfo(team)
  }

  func sendTipNoti(_ isManagerPermission: Bool, _ completion: @escaping (Error?) -> Void) {
    guard let teamId = teamInfoModel?.team?.teamId else {
      return
    }
    let session = NIMSession(teamId, type: .team)
    let tipContent = isManagerPermission ? localizable("team_tip_noti_at_manager") : localizable("team_tip_noti_at_all")
    let tipMessage = NIMMessage()
    let object = NIMTipObject(attach: nil, callbackExt: nil)
    tipMessage.messageObject = object
    tipMessage.text = tipContent
    let setting = NIMMessageSetting()
    setting.shouldBeCounted = false
    setting.apnsEnabled = false
    tipMessage.setting = setting
    chatRepo.sendMessage(message: tipMessage, session: session) { error in
      completion(error)
    }
  }

  private func updateTeamInfo(_ team: NIMTeam) {
    guard let tid = teamInfoModel?.team?.teamId else {
      return
    }

    if isRequestData == true {
      return
    }
    isRequestData = true
    repo.fetchTeamInfo(tid) { [weak self] error, info in
      if error == nil, info != nil {
        self?.teamInfoModel = info
        self?.managerUsers.removeAll()
        info?.users.forEach { userInfo in
          if userInfo.teamMember?.type == .manager {
            self?.managerUsers.append(userInfo)
          }
        }

        self?.sectionData.removeAll()
        self?.getSectionData()
        self?.delegate?.didRefreshData()

        print("onTeamMemberChanged managers count : ", self?.managerUsers.count as Any)
      }
      self?.isRequestData = false
    }
  }
}
