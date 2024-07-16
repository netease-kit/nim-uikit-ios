// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIM2Kit
import NIMSDK
import UIKit

public protocol TeamSettingViewModelDelegate: NSObjectProtocol {
  func didClickChangeNick()
  func didChangeInviteModeClick(_ model: SettingCellModel)
  func didUpdateTeamInfoClick(_ model: SettingCellModel)
  func didClickHistoryMessage()
  func didNeedRefreshUI()
  func didError(_ error: NSError)
  func didClickMark()
  func didClickTeamManage()
  func didShowNoNetworkToast()
}

@objcMembers
open class TeamSettingViewModel: NSObject, NETeamListener, NEConversationListener {
  /// 分区区域数据
  public var sectionData = [SettingSectionModel]()

  public var searchResultInfos: [HistoryMessageModel]?
  /// 群信息(包含群成员列表)
  public var teamInfoModel: NETeamInfoModel?
  /// 群模块接口单例
  public let teamRepo = TeamRepo.shared
  /// 通讯录接口单例
  public let contactRepo = ContactRepo.shared
  /// 当前用户的群成员信息
  public var memberInTeam: V2NIMTeamMember?
  /// 群设置代理
  public weak var delegate: TeamSettingViewModelDelegate?

  private let className = "TeamSettingViewModel"
  /// 群类型
  public var teamSettingType: TeamSettingType = .Discuss
  /// 群对应的会话信息
  public var conversation: V2NIMConversation?
  /// 会话API单例
  public var conversationRepo = ConversationRepo.shared
  /// 是否获取过群设置数据
  public var isRequestSettingData = false

  /// 群成员
  public var allMembersDic = [String: V2NIMTeamMember]()

  override public init() {
    super.init()
    teamRepo.addTeamListener(self)
    conversationRepo.addConversationListener(self)
    NotificationCenter.default.addObserver(self, selector: #selector(didTapHeader), name: NENotificationName.didTapHeader, object: nil)
  }

  /// 点击消息发送者头像
  /// 拉取最新用户信息后刷新消息发送者信息
  /// - Parameter noti: 通知对象
  func didTapHeader(_ noti: Notification) {
    if let user = noti.object as? NEUserWithFriend,
       let accid = user.user?.accountId {
      if NETeamMemberCache.shared.isCurrentMember(accid) {
        var isDidFind = false
        teamInfoModel?.users.forEach { model in
          if let accountId = model.nimUser?.user?.accountId, accountId == accid {
            model.nimUser = user
            isDidFind = true
          }
        }
        if isDidFind == true {
          delegate?.didNeedRefreshUI()
        }
      }
    }
  }

  func clear() {
    teamRepo.removeTeamListener(self)
    conversationRepo.removeConversationListener(self)
    NETeamMemberCache.shared.trigerTimer()
  }

  func getData() {
    NEALog.infoLog(ModuleName + " " + className, desc: #function)
    sectionData.removeAll()
    sectionData.append(getTwoSection())
    print("current team type : ", teamInfoModel?.team?.teamType.rawValue as Any)
    if let type = teamInfoModel?.team?.teamType, type == .TEAM_TYPE_NORMAL {
      if teamInfoModel?.team?.serverExtension?.contains(discussTeamKey) == true {
        return
      }
      sectionData.append(getThreeSection())
    }
  }

  // 头像 成员列表
  private func getOneSection() -> SettingSectionModel {
    NEALog.infoLog(ModuleName + " " + className, desc: #function)
    let model = SettingSectionModel()
    let cellModel = SettingCellModel()
    cellModel.type = SettingCellType.SettingHeaderCell.rawValue
    cellModel.rowHeight = 160
    cellModel.cornerType = .topLeft.union(.topRight).union(.bottomLeft).union(.bottomRight)
    model.cellModels.append(cellModel)
    return model
  }

  // 标记 历史记录 消息提醒
  private func getTwoSection() -> SettingSectionModel {
    NEALog.infoLog(ModuleName + " " + className, desc: #function)

    let model = SettingSectionModel()

    guard let tid = teamInfoModel?.team?.teamId else {
      NEALog.infoLog(ModuleName + " " + className, desc: #function + " teamId is nil")
      return model
    }

    weak var weakSelf = self

    // 标记 置顶 昵称
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

    let mode = teamRepo.getTeamMuteStatus(tid)
    if mode == .TEAM_MESSAGE_MUTE_MODE_OFF {
      remind.switchOpen = true
    }

    remind.swichChange = { isOpen in
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        remind.switchOpen = !isOpen
        weakSelf?.delegate?.didShowNoNetworkToast()
        weakSelf?.delegate?.didNeedRefreshUI()
        return
      }
      if let tid = weakSelf?.teamInfoModel?.team?.teamId {
        if isOpen == true {
          weakSelf?.teamRepo.setTeamMuteStatus(tid, .TEAM_TYPE_NORMAL, .TEAM_MESSAGE_MUTE_MODE_OFF) { error in
            if let err = error {
              weakSelf?.delegate?.didNeedRefreshUI()
              weakSelf?.delegate?.didError(err)
            } else {
              remind.switchOpen = false
            }
          }
        } else {
          weakSelf?.teamRepo.setTeamMuteStatus(tid, .TEAM_TYPE_NORMAL, .TEAM_MESSAGE_MUTE_MODE_ON) { error in
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

    // 聊天置顶
    let setTop = SettingCellModel()
    setTop.cellName = localizable("session_set_top")
    setTop.type = SettingCellType.SettingSwitchCell.rawValue

    if let currentConversation = conversation {
      setTop.switchOpen = currentConversation.stickTop
    }

    // 置顶
    setTop.swichChange = { isOpen in
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        setTop.switchOpen = !isOpen
        weakSelf?.delegate?.didShowNoNetworkToast()
        weakSelf?.delegate?.didNeedRefreshUI()
        return
      }
      if isOpen {
        if let teamId = weakSelf?.teamInfoModel?.team?.teamId, let conversationId = V2NIMConversationIdUtil.teamConversationId(teamId) {
          weakSelf?.conversationRepo.setStickTop(conversationId, true) { error in
            NEALog.infoLog(weakSelf?.className() ?? "", desc: #function + "addStickTop error : \(error?.localizedDescription ?? "") ")
            if let err = error {
              weakSelf?.delegate?.didNeedRefreshUI()
              weakSelf?.delegate?.didError(err)
            } else {
              setTop.switchOpen = true
            }
          }
        }
      } else {
        if let teamId = weakSelf?.teamInfoModel?.team?.teamId, let conversationId = V2NIMConversationIdUtil.teamConversationId(teamId) {
          weakSelf?.conversationRepo.setStickTop(conversationId, false) { error in
            NEALog.infoLog(weakSelf?.className() ?? "", desc: #function + "removeStickTop error : \(error?.localizedDescription ?? "") ")
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

    // 群昵称
    let nick = SettingCellModel()
    nick.cellName = localizable("team_nick")
    nick.type = SettingCellType.SettingArrowCell.rawValue
    nick.cellClick = {
      weakSelf?.delegate?.didClickChangeNick()
    }
    if IMKitConfigCenter.shared.enablePinMessage {
      model.cellModels.append(mark)
    }
    model.cellModels.append(history)
    model.cellModels.append(remind)
    model.cellModels.append(setTop)
    if isNormalTeam() == false {
      model.cellModels.append(nick)
    }

    model.setCornerType()
    return model
  }

  // 群昵称 群禁言
  private func getThreeSection() -> SettingSectionModel {
    NEALog.infoLog(ModuleName + " " + className, desc: #function)
    let model = SettingSectionModel()
    weak var weakSelf = self

    let forbiddenWords = SettingCellModel()
    forbiddenWords.cellName = localizable("team_no_speak")
    forbiddenWords.type = SettingCellType.SettingSwitchCell.rawValue

    if let chatBanndedMode = teamInfoModel?.team?.chatBannedMode {
      if chatBanndedMode == .TEAM_CHAT_BANNED_MODE_BANNED_ALL || chatBanndedMode == .TEAM_CHAT_BANNED_MODE_BANNED_NORMAL {
        forbiddenWords.switchOpen = true
      } else {
        forbiddenWords.switchOpen = false
      }
    }

    forbiddenWords.swichChange = { isOpen in
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        forbiddenWords.switchOpen = !isOpen
        weakSelf?.delegate?.didShowNoNetworkToast()
        weakSelf?.delegate?.didNeedRefreshUI()
        return
      }
      if let tid = weakSelf?.teamInfoModel?.team?.teamId {
        weakSelf?.teamRepo.setTeamChatBannedMode(tid, .TEAM_TYPE_NORMAL, isOpen ? .TEAM_CHAT_BANNED_MODE_BANNED_NORMAL : .TEAM_CHAT_BANNED_MODE_NONE) { error in
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

  // 邀请 修改群信息
  private func getFourSection() -> SettingSectionModel {
    NEALog.infoLog(ModuleName + " " + className, desc: #function)
    weak var weakSelf = self
    let model = SettingSectionModel()

    let invitePermission = SettingCellModel()
    invitePermission.cellName = localizable("invite_permission")
    invitePermission.type = SettingCellType.SettingSelectCell.rawValue
    invitePermission.rowHeight = 73

    if let inviteMode = teamInfoModel?.team?.inviteMode, inviteMode == .TEAM_INVITE_MODE_ALL {
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
    if let updateMode = teamInfoModel?.team?.updateInfoMode, updateMode == .TEAM_UPDATE_INFO_MODE_ALL {
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

  /// 获取群(内部获取群成员)
  /// - Parameter teamId: 群id
  /// - Parameter completion: 回调
  func getTeamWithMembers(_ teamId: String, _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", teamId:\(teamId)")
    weak var weakSelf = self
    if isRequestSettingData == true {
      return
    }
    getTeamInfoWithSomeMembers(teamId) { error, finished in
      weakSelf?.isRequestSettingData = false
      if error == nil {
        weakSelf?.getData()
      }
      completion(error)
    }
  }

  /// 获取所有群成员信息并缓存
  /// - Parameter teamId:  群id
  /// - Parameter queryType:  查询类型
  /// - Parameter completion:  完成后的回调
  public func getAllTeamMemberInfos(_ teamId: String,
                                    _ queryType: V2NIMTeamMemberRoleQueryType,
                                    _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamid:\(teamId)")
    if NETeamMemberCache.shared.getTeamMemberCache(teamId) != nil {
      NETeamMemberCache.shared.endTimer()
      NEALog.infoLog(className(), desc: "load team member from cache success.")
      completion(nil)
      return
    }
    weak var weakSelf = self
    NETeamMemberCache.shared.getAllTeamMemberInfos(teamId, queryType) { error, teamInfo in
      if let err = error {
        completion(err)
      } else {
        if let members = teamInfo?.users {
          NEALog.infoLog(weakSelf?.className() ?? "", desc: "set team member cache success.")
          NETeamMemberCache.shared.setCacheMembers(teamId, members)
        }
      }
    }
  }

  /// 获取群信息(只获取第一页群成员)
  func getTeamInfoWithSomeMembers(_ teamId: String, _ completion: @escaping (NSError?, Bool?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", teamId:\(teamId)")
    weak var weakSelf = self
    if let cid = V2NIMConversationIdUtil.teamConversationId(teamId) {
      conversationRepo.getConversation(cid) { conversation, error in
        if error == nil {
          weakSelf?.conversation = conversation
        }
        weakSelf?.teamRepo.getTeamInfo(teamId) { team, error in
          if let err = error {
            completion(err, false)
          } else {
            let teamInfo = NETeamInfoModel()
            teamInfo.team = team
            weakSelf?.teamInfoModel = teamInfo
            let option = V2NIMTeamMemberQueryOption()
            option.nextToken = ""
            option.limit = 20
            option.direction = .QUERY_DIRECTION_ASC
            option.onlyChatBanned = false
            option.roleQueryType = .TEAM_MEMBER_ROLE_QUERY_TYPE_ALL

            weakSelf?.teamRepo.getTeamMemberList(teamId, .TEAM_TYPE_NORMAL, option) { result, error in
              if let members = result?.memberList {
                weakSelf?.getUserInfo(members) { error, models in

                  if let err = error {
                    completion(err, result?.finished)
                  } else {
                    if let users = models {
                      weakSelf?.teamInfoModel?.users = users
                    }
                    completion(nil, result?.finished)
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  /// 根据成员信息获取用户信息
  public func getUserInfo(_ members: [V2NIMTeamMember], _ completion: @escaping (NSError?, [NETeamMemberInfoModel]?) -> Void) {
    var accids = [String]()
    var memberModels = [NETeamMemberInfoModel]()
    for member in members {
      accids.append(member.accountId)
      let model = NETeamMemberInfoModel()
      model.teamMember = member
      memberModels.append(model)
    }

    ContactRepo.shared.getUserWithFriend(accountIds: accids) { users, v2Error in

      if v2Error != nil {
        completion(nil, memberModels)
      } else {
        var dic = [String: NEUserWithFriend]()
        if let us = users {
          for user in us {
            if let accid = user.user?.accountId {
              dic[accid] = user
            }
          }
          for model in memberModels {
            if let accid = model.teamMember?.accountId {
              if let user = dic[accid] {
                model.nimUser = user
              }
            }
          }
          completion(nil, memberModels)
        }
      }
    }
  }

  /// 解散群聊
  /// - Parameter teamId : 群id
  /// - Parameter completion: 完成回调
  public func dismissTeam(_ teamId: String, _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", teamId:\(teamId)")
    teamRepo.dismissTeam(teamId, .TEAM_TYPE_NORMAL, completion)
  }

  /// 退出群
  /// - Parameter teamId: 群id
  /// - Parameter completion: 完成回调
  open func leaveTeam(_ teamId: String, _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", teamId:\(teamId)")
    teamRepo.leaveTeam(teamId, .TEAM_TYPE_NORMAL, completion)
  }

  /// 取消置顶
  /// - Parameter completion: 完成回调
  open func removeStickTop(_ completion: @escaping (NSError?)
    -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function)
    if let teamId = teamInfoModel?.team?.teamId, let conversationId = V2NIMConversationIdUtil.teamConversationId(teamId) {
      conversationRepo.setStickTop(conversationId, true) { error in
        completion(error)
      }
    }
  }

  /// 获取当前用户在群中的信息
  /// - Parameter userId: 用户id
  /// - Parameter teamId: 群id
  /// - Parameter completion: 完成回调
  func getCurrentMember(_ userId: String, _ teamId: String?, completion: @escaping (V2NIMTeamMember?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", userId:\(userId)")
    if let tid = teamId {
      teamRepo.getTeamMember(tid, .TEAM_TYPE_NORMAL, userId) { [weak self] member, error in
        if let currentMember = member {
          self?.memberInTeam = currentMember
          completion(currentMember, nil)
        } else {
          completion(member, error)
        }
      }
    }
  }

  /// 判断是不是创建者
  func isOwner() -> Bool {
    NEALog.infoLog(ModuleName + " " + className, desc: #function)

    if let accid = teamInfoModel?.team?.ownerAccountId {
      if IMKitClient.instance.isMe(accid) {
        return true
      }
    }
    return false
  }

  /// 是不是管理员
  func isManager() -> Bool {
    if let currentTeamMebmer = memberInTeam {
      if currentTeamMebmer.memberRole == .TEAM_MEMBER_ROLE_MANAGER {
        return true
      }
    }
    return false
  }

  private func sampleMemberId(arr: [NETeamMemberInfoModel], owner: String) -> String? {
    let sortArr = arr.sorted { model1, model2 in
      (model1.teamMember?.joinTime ?? 0) < (model2.teamMember?.joinTime ?? 0)
    }

    for model in sortArr {
      if let accid = model.teamMember?.accountId,
         accid != owner,
         !NEAIUserManager.shared.isAIUser(accid) {
        return model.teamMember?.accountId
      }
    }
    return owner
  }

  /// 移交群主
  /// - Parameter completion: 完成回调
  func transferTeamOwner(_ completion: @escaping (Error?) -> Void) {
    if isOwner() == false {
      completion(NSError(domain: "imuikit", code: -1, userInfo: [NSLocalizedDescriptionKey: "not team manager"]))
      return
    }

    guard var members = teamInfoModel?.users, let teamId = teamInfoModel?.team?.teamId else {
      completion(NSError(domain: "imuikit", code: -1, userInfo: [NSLocalizedDescriptionKey: "team info error"]))
      return
    }
    // 移除数字人
    members.removeAll { model in
      if let accountId = model.nimUser?.user?.accountId {
        if NEAIUserManager.shared.isAIUser(accountId) {
          return true
        }
      }
      return false
    }
    var userId = IMKitClient.instance.account()
    if members.count == 1 {
      dismissTeam(teamId, completion)
      return
    } else if let sampleOwnerId = sampleMemberId(arr: members, owner: userId) {
      userId = sampleOwnerId
    }

    if userId == IMKitClient.instance.account() {
      dismissTeam(teamId, completion)
      return
    }
    teamRepo.transferTeam(teamId, .TEAM_TYPE_NORMAL, userId, true) { error in
      completion(error)
    }
  }

  /// 是不是普通群
  open func isNormalTeam() -> Bool {
    NEALog.infoLog(ModuleName + " " + className, desc: #function)
    if teamInfoModel?.team?.serverExtension?.contains(discussTeamKey) == true {
      return true
    }
    return false
  }

  /// 群信息更改回调
  /// - Parameter team: 群信息类
  public func onTeamInfoUpdated(_ team: V2NIMTeam) {
    if let tid = teamInfoModel?.team?.teamId, tid == team.teamId {
      teamInfoModel?.team = team
      getData()
      delegate?.didNeedRefreshUI()
    }
  }

  /// 群成员离开回调
  /// - Parameter teamMembers: 群成员
  public func onTeamMemberLeft(_ teamMembers: [V2NIMTeamMember]) {
    onTeamMemberChanged(teamMembers)
  }

  /// 群成员被踢回调
  /// - Parameter operatorAccountId: 操作者id
  /// - Parameter teamMembers: 群成员
  public func onTeamMemberKicked(_ operatorAccountId: String, teamMembers: [V2NIMTeamMember]) {
    onTeamMemberChanged(teamMembers)
  }

  /// 群成员加入回调
  /// - Parameter teamMembers: 群成员
  public func onTeamMemberJoined(_ teamMembers: [V2NIMTeamMember]) {
    onTeamMemberChanged(teamMembers)
  }

  /// 群信息同步完成回调
  public func onTeamSyncFinished() {
    NEALog.infoLog(className(), desc: #function + " team setting viewmo model onTeamSyncFinished ")
    if let tid = teamInfoModel?.team?.teamId {
      weak var weakSelf = self
      getCurrentMember(IMKitClient.instance.account(), tid) { member, error in
        weakSelf?.getTeamInfoWithSomeMembers(tid) { error, finished in
          if error == nil {
            weakSelf?.getData()
            weakSelf?.delegate?.didNeedRefreshUI()
          }
        }
      }
    }
  }

  /// 群成员更新回调
  /// - Parameter teamMembers: 群成员列表
  public func onTeamMemberInfoUpdated(_ teamMembers: [V2NIMTeamMember]) {
    weak var weakSelf = self
    for member in teamMembers {
      if let currentTid = teamInfoModel?.team?.teamId, currentTid == member.teamId, member.accountId == IMKitClient.instance.account() {
        weakSelf?.memberInTeam = member
        break
      }
    }

    onTeamMemberChanged(teamMembers)
  }

  /// 离开群回调
  /// - Parameter teamMembers: 群成员
  /// - Parameter team: 群信息
  public func onTeamLeft(_ team: V2NIMTeam, isKicked: Bool) {}

  /// 群成员变更统一处理
  /// - Parameter teamMembers: 群成员
  private func onTeamMemberChanged(_ members: [V2NIMTeamMember]) {
    var isCurrentTeam = false
    for member in members {
      if let currentTid = teamInfoModel?.team?.teamId, currentTid == member.teamId {
        isCurrentTeam = true
      }

      if member.accountId == IMKitClient.instance.account(), let teamId = teamInfoModel?.team?.teamId {
        getCurrentMember(IMKitClient.instance.account(), teamId) { [weak self] member, error in
          NEALog.infoLog(self?.className() ?? "", desc: "current member : \(self?.memberInTeam?.yx_modelToJSONString() ?? "")")
        }
      }
    }

    if isCurrentTeam == true {
      guard let tid = teamInfoModel?.team?.teamId else {
        return
      }
      weak var weakSelf = self
      getTeamWithMembers(tid) { error in
        if error == nil {
          weakSelf?.delegate?.didNeedRefreshUI()
        }
      }
    }
  }

  /// 邀请用户
  /// - Parameter members: 用户id数组
  /// - Parameter teamId: 群id
  /// - Parameter completion: 完成回调
  open func inviteUsers(_ members: [String], _ teamId: String, _ completion: @escaping (NSError?, [V2NIMTeamMember]?) -> Void) {
    teamRepo.inviteTeamMembers(teamId, .TEAM_TYPE_NORMAL, members) { error, members in
      completion(error, members)
    }
  }

  /// 会话变更
  /// - Parameter conversations: 会话
  public func onConversationChanged(_ conversations: [V2NIMConversation]) {
    if let currentConversation = conversation {
      for changeConversation in conversations {
        if currentConversation.conversationId == changeConversation.conversationId {
          conversation = changeConversation
          getData()
          delegate?.didNeedRefreshUI()
          break
        }
      }
    }
  }
}
