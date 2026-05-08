// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import NECoreIM2Kit
import NIMSDK

@objc
public protocol NETeamListener: NSObjectProtocol {
  /// 同步开始
  @objc optional func onTeamSyncStarted()

  /// 同步完成回调
  @objc optional func onTeamSyncFinished()

  /// 同步失败回调
  /// - Parameter error: 错误信息
  @objc optional func onTeamSyncFailed(_ error: V2NIMError)

  /// 群组创建回调
  /// - Parameter team: 群组对象
  @objc optional func onTeamCreated(_ team: V2NIMTeam)

  /// 群组解散回调
  /// - Parameter team: 群组对象
  @objc optional func onTeamDismissed(_ team: V2NIMTeam)

  /// 加入群组回调
  /// - Parameter team: 群组对象
  @objc optional func onTeamJoined(_ team: V2NIMTeam)

  /// 离开群组回调
  /// - Parameter team: 群组对象
  /// - Parameter isKicked: 是否是踢出
  @objc optional func onTeamLeft(_ team: V2NIMTeam, isKicked: Bool)

  /// 群组信息更新回调
  /// - Parameter team: 群组对象
  @objc optional func onTeamInfoUpdated(_ team: V2NIMTeam)

  /// 群组成员加入回调
  /// - Parameter teamMembers: 群成员
  @objc optional func onTeamMemberJoined(_ teamMembers: [V2NIMTeamMember])

  /// 群组成员被踢回调
  /// - Parameter operatorAccountId： 操作者用户id
  /// - Parameter teamMembers: 群成员列表
  @objc optional func onTeamMemberKicked(_ operatorAccountId: String, teamMembers: [V2NIMTeamMember])

  /// 群组成员退出回调
  /// - Parameter teamMembers： 群成员列表
  @objc optional func onTeamMemberLeft(_ teamMembers: [V2NIMTeamMember])

  /// 群组成员信息变更回调
  /// - Parameter teamMembers: 群成员
  @objc optional func onTeamMemberInfoUpdated(_ teamMembers: [V2NIMTeamMember])

  /// 入群操作回调
  /// - Parameter joinActionInfo： 群信息
  @objc optional func onReceive(_ joinActionInfo: V2NIMTeamJoinActionInfo)
}

@objcMembers
public class TeamRepo: NSObject, V2NIMTeamListener {
  /// 多代理容器
  private let multiDelegate = MultiDelegate<NETeamListener>(strongReferences: false)

  public static let shared = TeamRepo()

  /// 群组Provider
  public let teamProvider = TeamProvider.shared

  /// 聊天Provider
  public let chatProvider = ChatProvider.shared

  /// 用户信息Provider
  public let userProvider = UserProvider.shared

  override private init() {
    super.init()
    teamProvider.addTeamListener(listener: self)
  }

  /// 添加群监听
  /// - Parameter listener: 监听实现
  open func addTeamListener(_ listener: NETeamListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    multiDelegate.addDelegate(listener)
  }

  /// 移除群监听
  /// - Parameter listener: 监听实现
  open func removeTeamListener(_ listener: NETeamListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    multiDelegate.removeDelegate(listener)
  }

  ///  创建群组
  /// - Parameter params: 创建群选项
  /// - Parameter members: 用户Accid列表
  /// - Parameter postscript: 邀请附言
  /// - Parameter antispamConfig:  反垃圾配置
  /// - Parameter completion: 完成后的回调
  open func createTeam(_ params: V2NIMCreateTeamParams,
                       _ members: [String],
                       _ postscript: String?,
                       _ antispamConfig: V2NIMAntispamConfig?,
                       _ completion: @escaping (V2NIMCreateTeamResult?, Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", accids:\(members.count)")
    teamProvider.createTeam(createTeamParams: params,
                            inviteeAccountIds: members,
                            postscript: postscript,
                            antispamConfig: antispamConfig) { result, error in
      completion(result, error)
    }
  }

  ///  更新群组头像
  /// - Parameter teamId : 群组ID
  /// - Parameter teamType: 群组类型
  /// - Parameter url: 群组头像Url
  /// - Parameter completion: 完成后的回调
  open func updateTeamIcon(_ teamId: String,
                           _ teamType: V2NIMTeamType = .TEAM_TYPE_NORMAL,
                           _ url: String,
                           _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", url:\(url)")
    let param = V2NIMUpdateTeamInfoParams()
    param.avatar = url
    teamProvider.updateTeamInfo(teamId: teamId, teamType: teamType, updateTeamInfoParams: param, antispamConfig: nil) { error in
      completion(error)
    }
  }

  ///  更新群介绍
  /// - Parameter  teamId: 群组ID
  /// - Parameter teamType: 群组类型
  /// - Parameter  introduce: 群介绍
  /// - Parameter  completion: 完成后的回调
  open func updateTeamIntroduce(_ teamId: String,
                                _ teamType: V2NIMTeamType = .TEAM_TYPE_NORMAL,
                                _ introduce: String,
                                _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", intr:\(introduce)")
    let param = V2NIMUpdateTeamInfoParams()
    param.intro = introduce
    teamProvider.updateTeamInfo(teamId: teamId, teamType: teamType, updateTeamInfoParams: param, antispamConfig: nil) { error in
      completion(error)
    }
  }

  ///  更新群组名称
  /// - Parameter teamId: 群组ID
  /// - Parameter teamType: 群组类型
  /// - Parameter name: 群组名称
  /// - Parameter completion: 完成后  的回调
  open func updateTeamName(_ teamId: String,
                           _ teamType: V2NIMTeamType = .TEAM_TYPE_NORMAL,
                           _ name: String,
                           _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", name:\(name)")
    let param = V2NIMUpdateTeamInfoParams()
    param.name = name
    teamProvider.updateTeamInfo(teamId: teamId, teamType: teamType, updateTeamInfoParams: param, antispamConfig: nil) { error in
      completion(error)
    }
  }

  ///  更新成员群昵称
  /// - Parameter teamId: 群组ID
  /// - Parameter teamType: 群组类型
  /// - Parameter accId : 群成员ID
  /// - Parameter nickName: 新的群成员昵称
  /// - Parameter completion: 完成后的回调
  open func updateMemberNick(_ teamId: String,
                             _ teamType: V2NIMTeamType = .TEAM_TYPE_NORMAL,
                             _ accId: String,
                             _ nickName: String,
                             _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", uid:\(accId)")
    teamProvider.updateTeamMemberNick(teamId: teamId, teamType: teamType, accountId: accId, teamNick: nickName) { error in
      completion(error)
    }
  }

  ///  更新群组扩展字段
  /// - Parameter  teamId: 群组ID
  /// - Parameter teamType: 群类型
  /// - Parameter  ext: 群自定义信息
  /// - Parameter  completion: 完成后的回调
  open func updateTeamExtension(_ teamId: String,
                                _ teamType: V2NIMTeamType = .TEAM_TYPE_NORMAL,
                                _ ext: String,
                                _ mode: V2NIMTeamUpdateExtensionMode? = nil,
                                _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamId:\(teamId)")
    let param = V2NIMUpdateTeamInfoParams()
    param.serverExtension = ext

    if let mode = mode {
      param.updateExtensionMode = mode
    }

    teamProvider.updateTeamInfo(teamId: teamId, teamType: teamType, updateTeamInfoParams: param, antispamConfig: nil) { error in
      completion(error)
    }
  }

  ///  解散群组
  ///  - Parameter teamId: 群组ID
  ///  - Parameter teamType: 群类型
  ///  - Parameter completion: 完成后的回调
  open func dismissTeam(_ teamId: String,
                        _ teamType: V2NIMTeamType = .TEAM_TYPE_NORMAL,
                        _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamId:\(teamId)")
    teamProvider.dismissTeam(teamId: teamId, teamType: teamType) { error in
      completion(error)
    }
  }

  ///  退出群组
  ///  - Parameter teamId: 群组ID
  ///  - Parameter teamType: 群类型
  ///  - Parameter completion: 完成后的回调
  open func leaveTeam(_ teamId: String,
                      _ teamType: V2NIMTeamType = .TEAM_TYPE_NORMAL,
                      _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamId:\(teamId)")
    teamProvider.leaveTeam(teamId: teamId, teamType: teamType) { error in
      completion(error)
    }
  }

  /// 获取所有群组
  ///  - Parameter completion: 完成回调
  open func getTeamList(_ completion: @escaping ([NETeam]?, Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    teamProvider.getJoinedTeamList(teamTypes: []) { teams, error in
      let teams = teams?.compactMap { NETeam(v2teamInfo: $0) }
      completion(teams, error)
    }
  }

  /// 获取单个群成员信息
  ///  - Parameter teamId:  群组id
  ///  - Parameter teamType: 群类型
  ///  - Parameter accId:  用户id
  ///  - Parameter completion:  完成后的回调
  open func getTeamMember(_ teamId: String,
                          _ teamType: V2NIMTeamType = .TEAM_TYPE_NORMAL,
                          _ accId: String,
                          _ completion: @escaping (V2NIMTeamMember?, NSError?) -> Void) {
    teamProvider.getTeamMemberList(teamId: teamId, teamType: teamType, accountIds: [accId]) { members, error in
      if let member = members?.first {
        completion(member, nil)
      } else {
        completion(nil, error)
      }
    }
  }

  /// 根据账号id列表获取群组成员列表
  ///  - Parameter teamId:  群组id
  ///  - Parameter teamType: 群类型
  ///  - Parameter accIds:  用户id列表
  ///  - Parameter completion:  完成后的回调
  open func getTeamMemberListByIds(_ teamId: String,
                                   _ teamType: V2NIMTeamType = .TEAM_TYPE_NORMAL,
                                   _ accIds: [String],
                                   _ completion: @escaping ([V2NIMTeamMember]?, NSError?) -> Void) {
    teamProvider.getTeamMemberList(teamId: teamId, teamType: teamType, accountIds: accIds, completion)
  }

  /// 获取群组成员列表
  /// - Parameter teamId:  群组Id
  /// - Parameter teamType:  群组类型
  /// - Parameter queryOption:  查询选项
  /// - Parameter completion:  回调
  open func getTeamMemberList(_ teamId: String,
                              _ teamType: V2NIMTeamType,
                              _ queryOption: V2NIMTeamMemberQueryOption,
                              _ completion: @escaping (V2NIMTeamMemberListResult?, NSError?) -> Void) {
    teamProvider.getTeamMemberList(teamId: teamId, teamType: teamType, queryOption: queryOption) { result, error in
      if let err = error {
        completion(nil, err)
      } else {
        completion(result, nil)
      }
    }
  }

  /// 添加群管理员
  ///   - Parameter teamId :  群Id
  ///   - Parameter teamType: 群类型
  ///   - Parameter members: 成成员id列表
  ///   - Parameter completion : 完成回调
  open func addManagers(_ teamId: String,
                        _ teamType: V2NIMTeamType = .TEAM_TYPE_NORMAL,
                        _ members: [String],
                        _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", uids.count:\(members.count)")
    teamProvider.updateTeamMemberRole(teamId: teamId, teamType: teamType, memberAccountIds: members, memberRole: .TEAM_MEMBER_ROLE_MANAGER) { error in
      completion(error)
    }
  }

  /// 移除群管理员
  ///   - Parameter teamId:  群id
  ///   - Parameter teamType: 群类型
  ///   - Parameter members:  成成员id列表
  ///   - Parameter completion:   完成回调
  open func removeManagers(_ teamId: String,
                           _ teamType: V2NIMTeamType = .TEAM_TYPE_NORMAL,
                           _ members: [String],
                           _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", uids.count:\(members.count)")
    teamProvider.updateTeamMemberRole(teamId: teamId, teamType: teamType, memberAccountIds: members, memberRole: .TEAM_MEMBER_ROLE_NORMAL) { error in
      completion(error)
    }
  }

  /// 移除群成员
  ///  - Parameter teamId:  群Id
  ///  - Parameter teamType: 群类型题
  ///  - Parameter members:  成员id列表
  ///  - Parameter completion:  完成回调，成功返回nil，失败携带error信息
  open func removeTeamMembers(_ teamId: String,
                              _ teamType: V2NIMTeamType = .TEAM_TYPE_NORMAL,
                              _ members: [String],
                              _ completion: @escaping (NSError?) -> Void) {
    teamProvider.kickMember(teamId: teamId, teamType: teamType, memberAccountIds: members) { error in
      completion(error)
    }
  }

  /// 获取群信息
  ///  - Parameter teamId:  群组Id
  ///  - Parameter teamType: 群类型
  ///  - Parameter completion:  回调
  open func getTeamInfo(_ teamId: String,
                        _ teamType: V2NIMTeamType = .TEAM_TYPE_NORMAL,
                        _ completion: @escaping (V2NIMTeam?, NSError?) -> Void) {
    teamProvider.getTeamInfo(teamId, .TEAM_TYPE_NORMAL, completion)
  }

  ///  申请加入群组
  ///  - Parameter  teamId: 群组Id
  ///  - Parameter  teamType: 群组类型
  ///  - Parameter  postscript: 申请入群的附言
  ///  - Parameter  completion:  回调
  open func applyJoinTeam(teamId: String,
                          teamType: V2NIMTeamType,
                          postscript: String?,
                          _ completion: @escaping (V2NIMTeam?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamId:\(teamId)")
    teamProvider.applyJoinTeam(teamId: teamId, teamType: teamType, postscript: postscript, completion)
  }

  ///  邀请用户入群
  /// - Parameter teamId:      群组ID
  /// - Parameter teamType: 群类型题
  /// - Parameter members:    用户ID列表
  /// - Parameter completion:  完成后的回调
  open func inviteTeamMembers(_ teamId: String,
                              _ teamType: V2NIMTeamType = .TEAM_TYPE_NORMAL,
                              _ members: [String],
                              _ completion: @escaping (NSError?, [V2NIMTeamMember]?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", uids.count:\(members.count)")
    teamProvider.inviteMember(teamId: teamId, teamType: .TEAM_TYPE_NORMAL, inviteeAccountIds: members, postscript: nil) { [weak self] accids, error in
      if let err = error {
        completion(err, nil)
      } else {
        if accids.count == 0 {
          self?.teamProvider.getTeamMemberList(teamId: teamId, teamType: .TEAM_TYPE_NORMAL, accountIds: members) { members, error in
            completion(error, members)
          }
        } else {
          var recordSet = Set<String>()
          for uid in members {
            recordSet.insert(uid)
          }
          for failedId in accids {
            recordSet.remove(failedId)
          }
          self?.teamProvider.getTeamMemberList(teamId: teamId, teamType: .TEAM_TYPE_NORMAL, accountIds: Array(recordSet)) { members, error in
            completion(error, members)
          }
        }
      }
    }
  }

  ///  更新群组邀请他人方式
  ///  - Parameter  teamId:      群组ID
  ///  - Parameter teamType: 群类型
  ///  - Parameter  mode:  邀请模式
  ///  - Parameter  completion:  完成后的回调
  open func updateInviteMode(_ teamId: String,
                             _ teamType: V2NIMTeamType = .TEAM_TYPE_NORMAL,
                             _ mode: V2NIMTeamInviteMode,
                             _ completion: @escaping (NSError?, V2NIMTeam?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamId:\(teamId) mode:\(mode.rawValue)")
    let param = V2NIMUpdateTeamInfoParams()
    param.inviteMode = mode
    teamProvider.updateTeamInfo(teamId: teamId, teamType: .TEAM_TYPE_NORMAL, updateTeamInfoParams: param, antispamConfig: nil) { [weak self] error in
      if let err = error {
        completion(err, nil)
      } else {
        self?.teamProvider.getTeamInfo(teamId, .TEAM_TYPE_NORMAL) { team, error in
          completion(error, team)
        }
      }
    }
  }

  ///  更改群组更新信息的权限
  ///  - Parameter  teamId :        群组ID
  ///  - Parameter teamType: 群类型题
  ///  - Parameter  mode :          群信息修改权限
  ///  - Parameter  completion:     完成后的回调
  open func updateTeamInfoMode(_ teamId: String,
                               _ teamType: V2NIMTeamType = .TEAM_TYPE_NORMAL,
                               _ mode: V2NIMTeamUpdateInfoMode,
                               _ completion: @escaping (NSError?, V2NIMTeam?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamId:\(teamId) mode:\(mode.rawValue)")
    let param = V2NIMUpdateTeamInfoParams()
    param.updateInfoMode = mode
    teamProvider.updateTeamInfo(teamId: teamId, teamType: teamType, updateTeamInfoParams: param, antispamConfig: nil) { [weak self] error in
      if let err = error {
        completion(err, nil)
      } else {
        self?.teamProvider.getTeamInfo(teamId, .TEAM_TYPE_NORMAL) { team, error in
          completion(error, team)
        }
      }
    }
  }

  /// 更改群组申请入群模式
  /// - Parameter  teamId :        群组ID
  /// - Parameter teamType: 群类型
  /// - Parameter  mode :          群信息修改权限
  /// - Parameter  completion:     完成后的回调
  open func updateTeamJoinMode(_ teamId: String,
                               _ teamType: V2NIMTeamType = .TEAM_TYPE_NORMAL,
                               _ mode: V2NIMTeamJoinMode,
                               _ completion: @escaping (NSError?, V2NIMTeam?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamId:\(teamId) mode:\(mode.rawValue)")
    let param = V2NIMUpdateTeamInfoParams()
    param.joinMode = mode
    teamProvider.updateTeamInfo(teamId: teamId, teamType: teamType, updateTeamInfoParams: param, antispamConfig: nil) { [weak self] error in
      if let err = error {
        completion(err, nil)
      } else {
        self?.teamProvider.getTeamInfo(teamId, .TEAM_TYPE_NORMAL) { team, error in
          completion(error, team)
        }
      }
    }
  }

  /// 更改群组被邀请人同意入群模式
  /// - Parameter  teamId :        群组ID
  /// - Parameter teamType: 群类型
  /// - Parameter  mode :          群信息修改权限
  /// - Parameter  completion:     完成后的回调
  open func updateTeamAgreeMode(_ teamId: String,
                                _ teamType: V2NIMTeamType = .TEAM_TYPE_NORMAL,
                                _ mode: V2NIMTeamAgreeMode,
                                _ completion: @escaping (NSError?, V2NIMTeam?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamId:\(teamId) mode:\(mode.rawValue)")
    let param = V2NIMUpdateTeamInfoParams()
    param.agreeMode = mode
    teamProvider.updateTeamInfo(teamId: teamId, teamType: teamType, updateTeamInfoParams: param, antispamConfig: nil) { [weak self] error in
      if let err = error {
        completion(err, nil)
      } else {
        self?.teamProvider.getTeamInfo(teamId, .TEAM_TYPE_NORMAL) { team, error in
          completion(error, team)
        }
      }
    }
  }

  ///  移交群主
  ///  - Parameter  teamId : 群组Id
  ///  - Parameter teamType: 群类型
  ///  - Parameter  account:  新群主的账号id
  ///  - Parameter  quit:  转让群主后，是否同时退出该群
  ///  - Parameter  completion:  回调
  open func transferTeam(_ teamId: String,
                         _ teamType: V2NIMTeamType = .TEAM_TYPE_NORMAL,
                         _ account: String,
                         _ quit: Bool,
                         _ completion: @escaping (NSError?) -> Void) {
    teamProvider.transferTeamOwner(teamId: teamId, teamType: .TEAM_TYPE_NORMAL, accountId: account, leave: quit) { error in
      completion(error)
    }
  }

  ///  根据群组id获取群组信息
  ///  - Parameter  teamIds: 群组Id列表
  ///  - Parameter  teamType: 群组类型
  ///  - Parameter  completion:  回调
  open func getTeamListByIds(teamIds: [String],
                             teamType: V2NIMTeamType,
                             _ completion: @escaping ([V2NIMTeam]?, NSError?) -> Void) {
    teamProvider.getTeamInfoByIds(teamIds: teamIds, teamType: teamType) { teams, error in
      completion(teams, error)
    }
  }

  ///  设置群组消息免打扰模式
  ///  - Parameter  teamId: 群组Id
  ///  - Parameter teamType: 群类型
  ///  - Parameter  muteMode: 群组消息免打扰模式
  ///  - Parameter  completion: 成功回调
  open func setTeamMuteStatus(_ teamId: String,
                              _ teamType: V2NIMTeamType = .TEAM_TYPE_NORMAL,
                              _ muteMode: V2NIMTeamMessageMuteMode,
                              _ completion: @escaping (NSError?) -> Void) {
    SettingProvider.shared.setTeamMessageMuteMode(teamId: teamId, teamType: teamType, muteMode: muteMode) { v2Error in
      completion(v2Error?.nserror as? NSError)
    }
  }

  /// 获取群消息免打扰模式
  ///  - Parameter teamId: 群组id
  ///  - Parameter teamType: 群类型
  ///  - Returns   mute模式
  open func getTeamMuteStatus(_ teamId: String,
                              _ teamType: V2NIMTeamType = .TEAM_TYPE_NORMAL) -> V2NIMTeamMessageMuteMode {
    SettingProvider.shared.getTeamMessageMuteMode(teamId: teamId, teamType: teamType)
  }

  /// 设置群组聊天禁言模式
  ///  - Parameter teamId: 群组Id
  ///  - Parameter teamType: 群类型
  ///  - Parameter chatBannedMode: 群组禁言模式
  ///  - Parameter completion: 成功回调
  open func setTeamChatBannedMode(_ teamId: String,
                                  _ teamType: V2NIMTeamType = .TEAM_TYPE_NORMAL,
                                  _ chatBannedMode: V2NIMTeamChatBannedMode,
                                  _ completion: @escaping (NSError?) -> Void) {
    teamProvider.setTeamChatBannedMode(teamId: teamId, teamType: teamType, chatBannedMode: chatBannedMode) { error in
      completion(error)
    }
  }

  /// 获取群加入相关信息
  /// - Parameters:
  ///   - option: 查询参数
  ///   - completion: 回调
  open func getTeamJoinActionInfoList(_ option: V2NIMTeamJoinActionInfoQueryOption,
                                      _ completion: @escaping (V2NIMTeamJoinActionInfoResult?, NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function)
    teamProvider.getTeamJoinActionInfoList(option, completion)
  }

  /// 清空所有入群申请
  /// - Parameters:
  ///   - completion: 回调
  open func clearAllTeamJoinActionInfo(_ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function)
    teamProvider.clearAllTeamJoinActionInfo(completion)
  }

  ///  同意邀请入群
  ///  - Parameter  invitationInfo: 邀请信息
  ///  - Parameter  completion:  回调
  open func acceptInvitation(invitationInfo: V2NIMTeamJoinActionInfo,
                             _ completion: @escaping (V2NIMTeam?, NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function + " operatorAccountId:\(invitationInfo.operatorAccountId) teamId:\(invitationInfo.teamId)")
    teamProvider.acceptInvitation(invitationInfo: invitationInfo, completion)
  }

  ///  拒绝邀请入群请求
  ///  - Parameter  invitationInfo: 邀请信息
  ///  - Parameter  postscript: 拒绝邀请入群的附言
  ///  - Parameter  completion:  回调
  open func rejectInvitation(invitationInfo: V2NIMTeamJoinActionInfo,
                             postscript: String?,
                             _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function + " operatorAccountId:\(invitationInfo.operatorAccountId) teamId:\(invitationInfo.teamId)")
    teamProvider.rejectInvitation(invitationInfo: invitationInfo, postscript: postscript, completion)
  }

  ///  接受入群申请请求
  ///  - Parameter  applicationInfo: 申请信息
  ///  - Parameter  completion:  回调
  open func acceptJoinApplication(_ applicationInfo: V2NIMTeamJoinActionInfo,
                                  _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function + " operatorAccountId:\(applicationInfo.operatorAccountId) teamId:\(applicationInfo.teamId)")
    teamProvider.acceptJoinApplication(applicationInfo, completion)
  }

  ///  拒绝入群申请
  ///  - Parameter  applicationInfo: 申请信息
  ///  - Parameter  postscript: 拒绝申请加入的附言
  ///  - Parameter  completion:  回调
  open func rejectJoinApplication(_ applicationInfo: V2NIMTeamJoinActionInfo,
                                  _ postscript: String?,
                                  _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function + " operatorAccountId:\(applicationInfo.operatorAccountId) teamId:\(applicationInfo.teamId)")
    teamProvider.rejectJoinApplication(applicationInfo, postscript, completion)
  }

  /// 获取本地群信息（不请求云端）
  /// - Parameters:
  ///   - teamId: 群 ID
  ///   - teamType: 群类型
  ///   - error: 错误信息，调用失败时赋值
  /// - Returns: 群信息，不存在则返回 nil
  open func getTeamInfoLocal(teamId: String,
                             teamType: V2NIMTeamType,
                             error: inout NSError?) -> V2NIMTeam? {
    NEALog.infoLog(className(), desc: #function + " teamId:\(teamId)")
    return teamProvider.getTeamInfoLocal(teamId: teamId, teamType: teamType, error: &error)
  }

  /// 按 ID 批量获取群信息（本地缓存，不请求云端）
  /// - Parameters:
  ///   - teamIds: 群 ID 列表
  ///   - teamType: 群类型
  ///   - error: 错误信息，调用失败时赋值
  /// - Returns: 群信息列表
  open func getTeamInfoByIdsLocal(teamIds: [String],
                                  teamType: V2NIMTeamType,
                                  error: inout NSError?) -> [V2NIMTeam]? {
    NEALog.infoLog(className(), desc: #function + " teamIds count:\(teamIds.count)")
    return teamProvider.getTeamInfoByIdsLocal(teamIds: teamIds, teamType: teamType, error: &error)
  }

  /// 获取我拥有的群列表（本地缓存，不请求云端）
  /// - Parameters:
  ///   - teamTypes: 群类型列表
  ///   - error: 错误信息，调用失败时赋值
  /// - Returns: 群列表
  open func getOwnerTeamList(teamTypes: [NSNumber],
                             error: inout NSError?) -> [V2NIMTeam]? {
    NEALog.infoLog(className(), desc: #function)
    return teamProvider.getOwnerTeamList(teamTypes: teamTypes, error: &error)
  }

  /// 从云端获取群信息
  /// - Parameters:
  ///   - teamId: 群 ID
  ///   - teamType: 群类型
  ///   - completion: 完成回调
  open func getTeamInfoFromCloud(teamId: String,
                                 teamType: V2NIMTeamType,
                                 _ completion: @escaping (V2NIMTeam?, NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function + " teamId:\(teamId)")
    teamProvider.getTeamInfoFromCloud(teamId: teamId, teamType: teamType, completion)
  }

  /// 扩展版邀请成员
  /// - Parameters:
  ///   - teamId: 群 ID
  ///   - teamType: 群类型
  ///   - params: 邀请参数（包含被邀请成员账号列表及相关配置）
  ///   - completion: 完成回调，返回邀请失败的账号列表
  open func inviteMemberEx(teamId: String,
                           teamType: V2NIMTeamType,
                           params: V2NIMTeamInviteParams,
                           _ completion: @escaping ([String]?, NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function + " teamId:\(teamId)")
    teamProvider.inviteMemberEx(teamId: teamId, teamType: teamType, params: params, completion)
  }

  /// 扩展版更新群成员昵称
  /// - Parameters:
  ///   - teamId: 群 ID
  ///   - teamType: 群类型
  ///   - accountId: 被修改成员账号
  ///   - params: 更新参数（V2NIMUpdateMemberNickParams）
  ///   - completion: 完成回调
  open func updateTeamMemberNickEx(teamId: String,
                                   teamType: V2NIMTeamType,
                                   accountId: String,
                                   params: V2NIMUpdateMemberNickParams,
                                   _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function + " teamId:\(teamId) accountId:\(accountId)")
    teamProvider.updateTeamMemberNickEx(teamId: teamId, teamType: teamType, accountId: accountId, params: params, completion)
  }

  /// 标记入群申请为已读
  /// - Parameters:
  ///   - applicationInfo: 申请信息，nil 则标记全部
  ///   - completion: 完成回调
  open func setTeamJoinActionInfoRead(applicationInfo: V2NIMTeamJoinActionInfo?,
                                      _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function)
    teamProvider.setTeamJoinActionInfoRead(applicationInfo: applicationInfo, completion)
  }

  /// 获取入群申请未读数
  /// - Parameter completion: 完成回调
  open func getTeamJoinActionInfoUnreadCount(_ completion: @escaping (Int, NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function)
    teamProvider.getTeamJoinActionInfoUnreadCount(completion)
  }

  /// 获取我管理的群列表
  /// - Parameters:
  ///   - teamTypes: 群类型列表
  ///   - completion: 完成回调
  open func getManagerTeamList(teamTypes: [NSNumber],
                               _ completion: @escaping ([V2NIMTeam]?, NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function)
    teamProvider.getManagerTeamList(teamTypes: teamTypes, completion)
  }

  /// 获取已加入群的成员列表
  /// - Parameters:
  ///   - teamTypes: 群类型列表，nil 表示全部
  ///   - completion: 完成回调
  open func getJoinedTeamMembers(teamTypes: [NSNumber]?,
                                 _ completion: @escaping ([V2NIMTeamMember]?, NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function)
    teamProvider.getJoinedTeamMembers(teamTypes: teamTypes, completion)
  }

  /// 获取邀请某成员入群的邀请人信息
  /// - Parameters:
  ///   - teamId: 群 ID
  ///   - teamType: 群类型
  ///   - accountIds: 成员账号列表
  ///   - completion: 完成回调
  open func getTeamMemberInvitor(teamId: String,
                                 teamType: V2NIMTeamType,
                                 accountIds: [String],
                                 _ completion: @escaping ([String: String]?, NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function + " teamId:\(teamId)")
    teamProvider.getTeamMemberInvitor(teamId: teamId, teamType: teamType, accountIds: accountIds, completion)
  }

  /// 按关键词搜索群
  /// - Parameters:
  ///   - keyword: 搜索关键词
  ///   - completion: 完成回调
  open func searchTeamByKeyword(keyword: String,
                                _ completion: @escaping ([V2NIMTeam]?, NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function + " keyword:\(keyword)")
    teamProvider.searchTeamByKeyword(keyword: keyword, completion)
  }

  /// 按选项搜索群成员
  /// - Parameters:
  ///   - option: 搜索选项
  ///   - completion: 完成回调
  open func searchTeamMembers(option: V2NIMTeamMemberSearchOption,
                              _ completion: @escaping (V2NIMTeamMemberSearchResult?, NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function)
    teamProvider.searchTeamMembers(option: option, completion)
  }

  /// 搜索群（扩展版）
  /// - Parameters:
  ///   - params: 搜索参数
  ///   - completion: 完成回调
  open func searchTeams(params: V2NIMTeamSearchParams,
                        _ completion: @escaping ([V2NIMTeam]?, NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function)
    teamProvider.searchTeams(params: params, completion)
  }

  /// 搜索群成员（扩展版）
  /// - Parameters:
  ///   - params: 搜索参数
  ///   - completion: 完成回调
  open func searchTeamMembersEx(params: V2NIMSearchTeamMemberParams,
                                _ completion: @escaping ([V2NIMTeamRefer: [V2NIMTeamMember]]?, NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function)
    teamProvider.searchTeamMembersEx(params: params, completion)
  }

  /// 关注群成员
  /// - Parameters:
  ///   - teamId: 群 ID
  ///   - teamType: 群类型
  ///   - accountIds: 成员账号列表
  ///   - completion: 完成回调
  open func addTeamMembersFollow(teamId: String,
                                 teamType: V2NIMTeamType,
                                 accountIds: [String],
                                 _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function + " teamId:\(teamId)")
    teamProvider.addTeamMembersFollow(teamId: teamId, teamType: teamType, accountIds: accountIds, completion)
  }

  /// 取关群成员
  /// - Parameters:
  ///   - teamId: 群 ID
  ///   - teamType: 群类型
  ///   - accountIds: 成员账号列表
  ///   - completion: 完成回调
  open func removeTeamMembersFollow(teamId: String,
                                    teamType: V2NIMTeamType,
                                    accountIds: [String],
                                    _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function + " teamId:\(teamId)")
    teamProvider.removeTeamMembersFollow(teamId: teamId, teamType: teamType, accountIds: accountIds, completion)
  }

  /// 按选项清除入群申请记录
  /// - Parameters:
  ///   - option: 清除选项
  ///   - completion: 完成回调
  open func clearAllTeamJoinActionInfoEx(option: V2NIMTeamClearJoinActionInfoOption,
                                         _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function)
    teamProvider.clearAllTeamJoinActionInfoEx(option: option, completion)
  }

  /// 删除单条入群申请记录
  /// - Parameters:
  ///   - applicationInfo: 要删除的申请记录
  ///   - completion: 完成回调
  open func deleteTeamJoinActionInfo(applicationInfo: V2NIMTeamJoinActionInfo,
                                     _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(className(), desc: #function)
    teamProvider.deleteTeamJoinActionInfo(applicationInfo: applicationInfo, completion)
  }

  // MARK: - NETeamListener

  /// 同步开始
  open func onSyncStarted() {
    multiDelegate |> { delegate in
      delegate.onTeamSyncStarted?()
    }
  }

  /// 同步完成回调
  open func onSyncFinished() {
    multiDelegate |> { delegate in
      delegate.onTeamSyncFinished?()
    }
  }

  /// 同步失败回调
  /// - Parameter error: 错误信息
  open func onSyncFailed(_ error: V2NIMError) {
    multiDelegate |> { delegate in
      delegate.onTeamSyncFailed?(error)
    }
  }

  /// 群组创建回调
  /// - Parameter team: 群组对象
  open func onTeamCreated(_ team: V2NIMTeam) {
    multiDelegate |> { delegate in
      delegate.onTeamCreated?(team)
    }
  }

  /// 群组解散回调
  /// - Parameter team: 群组对象
  open func onTeamDismissed(_ team: V2NIMTeam) {
    multiDelegate |> { delegate in
      delegate.onTeamDismissed?(team)
    }
  }

  /// 加入群组回调
  /// - Parameter team: 群组对象
  open func onTeamJoined(_ team: V2NIMTeam) {
    multiDelegate |> { delegate in
      delegate.onTeamJoined?(team)
    }
  }

  /// 离开群组回调
  /// - Parameter team: 群组对象
  /// - Parameter isKicked: 是否是踢出
  open func onTeamLeft(_ team: V2NIMTeam, isKicked: Bool) {
    multiDelegate |> { delegate in
      delegate.onTeamLeft?(team, isKicked: isKicked)
    }
  }

  /// 群组信息更新回调
  /// - Parameter team: 群组对象
  open func onTeamInfoUpdated(_ team: V2NIMTeam) {
    multiDelegate |> { delegate in
      delegate.onTeamInfoUpdated?(team)
    }
  }

  /// 群组成员加入回调
  /// - Parameter teamMembers: 群成员
  open func onTeamMemberJoined(_ teamMembers: [V2NIMTeamMember]) {
    multiDelegate |> { delegate in
      delegate.onTeamMemberJoined?(teamMembers)
    }
  }

  /// 群组成员被踢回调
  /// - Parameter operatorAccountId： 操作者用户id
  /// - Parameter teamMembers: 群成员列表
  open func onTeamMemberKicked(_ operatorAccountId: String, teamMembers: [V2NIMTeamMember]) {
    multiDelegate |> { delegate in
      delegate.onTeamMemberKicked?(operatorAccountId, teamMembers: teamMembers)
    }
  }

  /// 群组成员退出回调
  /// - Parameter teamMembers： 群成员列表
  open func onTeamMemberLeft(_ teamMembers: [V2NIMTeamMember]) {
    multiDelegate |> { delegate in
      delegate.onTeamMemberLeft?(teamMembers)
    }
  }

  /// 群组成员信息变更回调
  /// - Parameter teamMembers: 群成员
  open func onTeamMemberInfoUpdated(_ teamMembers: [V2NIMTeamMember]) {
    multiDelegate |> { delegate in
      delegate.onTeamMemberInfoUpdated?(teamMembers)
    }
  }

  /// 入群操作回调
  /// - Parameter joinActionInfo： 群信息
  open func onReceive(_ joinActionInfo: V2NIMTeamJoinActionInfo) {
    multiDelegate |> { delegate in
      delegate.onReceive?(joinActionInfo)
    }
  }
}
