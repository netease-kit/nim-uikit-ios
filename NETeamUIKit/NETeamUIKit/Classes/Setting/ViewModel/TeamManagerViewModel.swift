//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonKit
import NIMSDK
import UIKit

public protocol TeamManagerViewModelDelegate: NSObjectProtocol {
  /// 邀请权限变更回调
  /// - Parameter model: 设置数据模型
  func didChangeInviteModeClick(_ model: SettingCellModel)
  /// 群信息修改权限变更回调
  /// - Parameter model: 设置数据模型
  func didUpdateTeamInfoClick(_ model: SettingCellModel)
  /// at权限变更回调
  /// - Parameter model: 设置数据模型
  func didAtPermissionClick(_ model: SettingCellModel)
  /// 置顶权限变更回调
  /// - Parameter model: 设置数据模型
  func didTopMessagePermissionClick(_ model: SettingCellModel)
  /// 管理员点击回调
  func didManagerClick()
  /// 通知页面刷新回调
  func didRefreshData()
}

@objc
@objcMembers
open class TeamManagerViewModel: NSObject, NETeamListener {
  /// 群API单例
  public let teamRepo = TeamRepo.shared
  /// 聊天API单例
  public let chatRepo = ChatRepo.shared
  /// 群信息
  public var teamInfoModel: NETeamInfoModel?
  /// UI 分区数据
  public var sectionData = [SettingSectionModel]()
  /// 管理员数据
  public var managerUsers = [V2NIMTeamMember]()

  var isRequestData = false

  public weak var delegate: TeamManagerViewModelDelegate?

  /// 当前用户的群成员对象
  public var teamMember: V2NIMTeamMember?

  override public init() {
    super.init()
    teamRepo.addTeamListener(self)
  }

  deinit {
    teamRepo.removeTeamListener(self)
  }

  /// 获取UI分组数据
  open func getSectionData() {
    sectionData.removeAll()
    if teamInfoModel?.team?.ownerAccountId == IMKitClient.instance.account() {
      sectionData.append(getFirstSection())
    }
    sectionData.append(getSecondSection())
  }

  /// 获取当前用户在群中的信息
  /// - Parameter userId: 用户id
  /// - Parameter teamId: 群id
  /// - Parameter completion: 完成回调
  func getCurrentUserTeamMember(_ userId: String, _ teamId: String?, completion: @escaping (V2NIMTeamMember?, NSError?) -> Void) {
    if let tid = teamId {
      teamRepo.getTeamMember(tid, .TEAM_TYPE_NORMAL, userId) { [weak self] member, error in
        if let currentMember = member {
          self?.teamMember = currentMember
          completion(currentMember, nil)
        } else {
          completion(member, error)
        }
      }
    }
  }

  /// 获取管理员信息

  /// 群信息(包含群成员)
  /// - Parameter teamId: 群id
  /// - Parameter completion: 完成回调
  open func getTeamWithMembers(_ teamId: String, _ completion: @escaping (Error?) -> Void) {
    if isRequestData == true {
      return
    }
    weak var weakSelf = self
    isRequestData = true

    teamRepo.getTeamInfo(teamId) { team, error in
      if let err = error {
        weakSelf?.isRequestData = false
        completion(err)
      } else {
        var memberList = [V2NIMTeamMember]()
        weakSelf?.getAllTeamManagers(teamId, nil, &memberList, .TEAM_MEMBER_ROLE_QUERY_TYPE_MANAGER) { members, error in
          if let err = error {
            weakSelf?.isRequestData = false
            completion(err)
          } else {
            weakSelf?.isRequestData = false
            let model = NETeamInfoModel()
            model.team = team
            weakSelf?.teamInfoModel = model
            weakSelf?.managerUsers.removeAll()
            if let managers = members {
              for member in managers {
                if member.memberRole != .TEAM_MEMBER_ROLE_OWNER {
                  weakSelf?.managerUsers.append(member)
                }
              }
            }
            weakSelf?.sectionData.removeAll()
            weakSelf?.getSectionData()
            completion(nil)
          }
        }
      }
    }
  }

  /// 获取顶部section(管理员数量)
  open func getFirstSection() -> SettingSectionModel {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
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

  /// 获取中间section数据(权限)
  open func getSecondSection() -> SettingSectionModel {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    weak var weakSelf = self
    let model = SettingSectionModel()

    // 谁可以编辑群信息
    let editTeamPermission = SettingCellModel()
    editTeamPermission.cellName = localizable("who_edit_team_info")
    editTeamPermission.type = SettingCellType.SettingSelectCell.rawValue
    editTeamPermission.rowHeight = 73

    if let updateMode = teamInfoModel?.team?.updateInfoMode, updateMode == .TEAM_UPDATE_INFO_MODE_ALL {
      editTeamPermission.subTitle = localizable("team_all")
    } else {
      editTeamPermission.subTitle = localizable("team_owner_and_manager")
    }

    editTeamPermission.cellClick = {
      weakSelf?.delegate?.didUpdateTeamInfoClick(editTeamPermission)
    }

    // 谁可以添加群成员
    let invitePermission = SettingCellModel()
    invitePermission.cellName = localizable("who_edit_user_info")
    invitePermission.type = SettingCellType.SettingSelectCell.rawValue
    invitePermission.rowHeight = 73
    if let inviteMode = teamInfoModel?.team?.inviteMode, inviteMode == .TEAM_INVITE_MODE_ALL {
      invitePermission.subTitle = localizable("team_all")
    } else {
      invitePermission.subTitle = localizable("team_owner_and_manager")
    }

    invitePermission.cellClick = {
      weakSelf?.delegate?.didChangeInviteModeClick(invitePermission)
    }

    // 谁可以 @所有人
    let atAllPermission = SettingCellModel()
    atAllPermission.cellName = localizable("who_at_all")
    atAllPermission.type = SettingCellType.SettingSelectCell.rawValue
    atAllPermission.rowHeight = 73
    atAllPermission.subTitle = localizable("team_owner_and_manager")
    atAllPermission.subTitle = getTeamAtAllPermissionValue()

    atAllPermission.cellClick = {
      weakSelf?.delegate?.didAtPermissionClick(atAllPermission)
    }

    model.cellModels.append(contentsOf: [editTeamPermission, invitePermission, atAllPermission])

    if IMKitConfigCenter.shared.enableTopMessage {
      // 谁可以置顶消息
      let topMessagePermission = SettingCellModel()
      topMessagePermission.cellName = localizable("who_can_top_message")
      topMessagePermission.type = SettingCellType.SettingSelectCell.rawValue
      topMessagePermission.rowHeight = 73
      topMessagePermission.subTitle = localizable("team_owner_and_manager")
      topMessagePermission.subTitle = getTeamTopMessagePermissionValue()

      topMessagePermission.cellClick = {
        weakSelf?.delegate?.didTopMessagePermissionClick(topMessagePermission)
      }

      model.cellModels.append(topMessagePermission)
    }

    // 设置 section 圆角
    model.setCornerType()

    return model
  }

  /// 更新at权限
  ///  - Parameter  isManager: 是否只有管理员能at，false 允许所有人发送at消息
  ///  - Parameter completion: 完成回调
  open func updateTeamAtAllPermission(_ isManager: Bool, _ completion: @escaping (Error?) -> Void) {
    let value = isManager == true ? allowAtManagerValue : allowAtAllValue
    guard let tid = teamInfoModel?.team?.teamId else {
      return
    }
    weak var weakSelf = self
    teamRepo.getTeamInfo(tid) { team, error in
      if let custom = team?.serverExtension {
        if var dic = NECommonUtil.getDictionaryFromJSONString(custom) as? [String: Any] {
          dic[keyAllowAtAll] = value
          dic["lastOpt"] = keyAllowAtAll
          let info = NECommonUtil.getJSONStringFromDictionary(dic)
          weakSelf?.teamRepo.updateTeamExtension(tid, .TEAM_TYPE_NORMAL, info) { error in
            completion(error)
          }
        }
      } else {
        var dic = [String: Any]()
        dic[keyAllowAtAll] = value
        dic["lastOpt"] = keyAllowAtAll
        let info = NECommonUtil.getJSONStringFromDictionary(dic)
        weakSelf?.teamRepo.updateTeamExtension(tid, .TEAM_TYPE_NORMAL, info) { error in
          completion(error)
        }
      }
    }
  }

  /// 获取at权限值
  func getTeamAtAllPermissionValue() -> String {
    if let custom = teamInfoModel?.team?.serverExtension {
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

  /// 获取置顶消息权限值
  func getTeamTopMessagePermissionValue() -> String {
    if let custom = teamInfoModel?.team?.serverExtension {
      if let dic = NECommonUtil.getDictionaryFromJSONString(custom) as? [String: Any] {
        if let value = dic[keyAllowTopMessage] as? String {
          if value == allowAtAllValue {
            return localizable("team_all")
          }
        }
      }
    }
    return localizable("team_owner_and_manager")
  }

  /// 更新置顶权限
  ///  - Parameter  isManager: 是否只有管理员能置顶消息，false 允许所有人置顶消息
  ///  - Parameter completion: 完成回调
  open func updateTeamTopMessagePermission(_ isManager: Bool, _ completion: @escaping (Error?) -> Void) {
    let value = isManager == true ? allowAtManagerValue : allowAtAllValue
    guard let tid = teamInfoModel?.team?.teamId else {
      return
    }
    weak var weakSelf = self
    teamRepo.getTeamInfo(tid) { team, error in
      if let custom = team?.serverExtension {
        if var dic = NECommonUtil.getDictionaryFromJSONString(custom) as? [String: Any] {
          dic[keyAllowTopMessage] = value
          dic["lastOpt"] = keyAllowTopMessage
          let info = NECommonUtil.getJSONStringFromDictionary(dic)
          weakSelf?.teamRepo.updateTeamExtension(tid, .TEAM_TYPE_NORMAL, info, .TEAM_UPDATE_EXTENSION_MODE_ALL) { error in
            completion(error)
          }
        }
      } else {
        var dic = [String: Any]()
        dic[keyAllowTopMessage] = value
        dic["lastOpt"] = keyAllowTopMessage
        let info = NECommonUtil.getJSONStringFromDictionary(dic)
        weakSelf?.teamRepo.updateTeamExtension(tid, .TEAM_TYPE_NORMAL, info, .TEAM_UPDATE_EXTENSION_MODE_ALL) { error in
          completion(error)
        }
      }
    }
  }

  /// 群成员离开
  /// - Parameter teamMembers: 群成员
  public func onTeamMemberLeft(_ teamMembers: [V2NIMTeamMember]) {
    onTeamMemberChanged(teamMembers)
  }

  /// 群成员加入
  /// - Parameter operatorAccountId: 操作者
  /// - Parameter teamMembers: 群成员
  public func onTeamMemberKicked(_ operatorAccountId: String, teamMembers: [V2NIMTeamMember]) {
    onTeamMemberChanged(teamMembers)
  }

  /// 群信息更新
  public func onTeamInfoUpdated(_ team: V2NIMTeam) {
    updateTeamInfo(team.teamId)
  }

  ///  更改群组更新信息的权限
  ///  - Parameter  teamId :        群组ID
  ///  - Parameter  mode :          群信息修改权限
  ///  - Parameter  completion:     完成后的回调
  public func updateTeamInfoPrivilege(_ teamId: String, _ mode: V2NIMTeamUpdateInfoMode,
                                      _ completion: @escaping (NSError?, V2NIMTeam?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", mode:\(mode.rawValue)")
    teamRepo.updateTeamInfoMode(teamId, .TEAM_TYPE_NORMAL, mode) { error, team in
      completion(error, team)
    }
  }

  ///  更新群组邀请他人方式
  ///  - Parameter  teamId:      群组ID
  ///  - Parameter  mode:  邀请模式
  ///  - Parameter  completion:  完成后的回调
  public func updateInviteMode(_ teamId: String, _ mode: V2NIMTeamInviteMode,
                               _ completion: @escaping (NSError?, V2NIMTeam?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", mode:\(mode.rawValue)")
    teamRepo.updateInviteMode(teamId, .TEAM_TYPE_NORMAL, mode) { error, team in
      completion(error, team)
    }
  }

  /// 群信息更新
  /// - Parameter teamId: 群id
  private func updateTeamInfo(_ teamId: String) {
    guard let tid = teamInfoModel?.team?.teamId else {
      return
    }

    if tid != teamId {
      return
    }

    getTeamWithMembers(teamId) { [weak self] error in
      if error == nil {
        self?.delegate?.didRefreshData()
      }
    }
  }

  public func onTeamMemberInfoUpdated(_ teamMembers: [V2NIMTeamMember]) {
    print("team manage onTeamMemberInfoUpdated")
    onTeamMemberChanged(teamMembers)
  }

  /// 处理群成员变更
  /// - Parameter members: 群成员
  private func onTeamMemberChanged(_ members: [V2NIMTeamMember]) {
    var isCurrentTeam = false
    for member in members {
      if let currentTid = teamInfoModel?.team?.teamId, currentTid == member.teamId {
        isCurrentTeam = true
      }
      if member.accountId == IMKitClient.instance.account() {
        teamMember = member
      }
    }

    if isCurrentTeam == true {
      if let currentTid = teamInfoModel?.team?.teamId {
        print("team manage updateTeamInfo")
        updateTeamInfo(currentTid)
      }
    }
  }

  /// 获取群管理员
  /// - Parameter teamId:  群ID
  /// - Parameter nextToken: 下一页标识
  /// - Parameter completion:  完成回调
  private func getAllTeamManagers(_ teamId: String, _ nextToken: String? = nil, _ memberList: inout [V2NIMTeamMember], _ queryType: V2NIMTeamMemberRoleQueryType, _ completion: @escaping ([V2NIMTeamMember]?, NSError?) -> Void) {
    let option = V2NIMTeamMemberQueryOption()
    option.limit = 100
    option.direction = .QUERY_DIRECTION_ASC
    option.onlyChatBanned = false
    option.roleQueryType = queryType
    if let token = nextToken {
      option.nextToken = token
    } else {
      option.nextToken = ""
    }
    var temMemberLists = memberList
    teamRepo.getTeamMemberList(teamId, .TEAM_TYPE_NORMAL, option) { [weak self] result, error in
      if let err = error {
        completion(nil, err)
      } else {
        if let members = result?.memberList {
          temMemberLists.append(contentsOf: members)
        }
        if let finished = result?.finished {
          if finished == true {
            completion(temMemberLists, nil)
          } else {
            self?.getAllTeamManagers(teamId, result?.nextToken, &temMemberLists, queryType, completion)
          }
        }
      }
    }
  }
}
