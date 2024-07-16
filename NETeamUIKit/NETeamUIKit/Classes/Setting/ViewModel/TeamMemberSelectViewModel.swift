//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import NIMSDK
import UIKit

public protocol TeamMemberSelectViewModelDelegate: NSObject {
  func didNeedRefresh()
}

@objcMembers
class TeamMemberSelectViewModel: NSObject, NETeamListener, NETeamMemberCacheListener {
  /// 群API单例
  let teamRepo = TeamRepo.shared
  /// 选中成员数据
  var datas = [NESelectTeamMember]()

  var showDatas = [NESelectTeamMember]()
  /// 群信息
  var teamInfoModel: NETeamInfoModel?
  /// 代理
  weak var delegate: TeamMemberSelectViewModelDelegate?
  /// 当前选中的数据
  var selectDic = [String: NETeamMemberInfoModel]() // key 值为用户 id
  /// 是否正在发送请求
  var isRequest = false
  /// 管理员account id 存放
  var managerSet = Set<String>()

  override init() {
    super.init()
    teamRepo.addTeamListener(self)
    NETeamMemberCache.shared.addTeamCacheListener(self)
    NotificationCenter.default.addObserver(self, selector: #selector(didTapHeader), name: NENotificationName.didTapHeader, object: nil)
  }

  deinit {
    teamRepo.removeTeamListener(self)
    NETeamMemberCache.shared.removeTeamCacheListener(self)
  }

  // 点击消息发送者头像
  /// 拉取最新用户信息后刷新消息发送者信息
  /// - Parameter noti: 通知对象
  func didTapHeader(_ noti: Notification) {
    if let user = noti.object as? NEUserWithFriend,
       let accid = user.user?.accountId {
      if NETeamMemberCache.shared.isCurrentMember(accid) {
        var isDidFind = false
        for model in showDatas {
          if let accountId = model.member?.nimUser?.user?.accountId, accountId == accid {
            model.member?.nimUser = user
            isDidFind = true
          }
        }
        if isDidFind == true {
          delegate?.didNeedRefresh()
        }
      }
    }
  }

  /// 群信息(包含群成员)
  /// - Parameter teamId: 群id
  /// - Parameter completion: 完成回调
  func getTeamInfo(_ teamId: String, _ completion: @escaping (NSError?) -> Void) {
    if isRequest == true {
      return
    }
    weak var weakSelf = self
    isRequest = true
    teamRepo.getTeamInfo(teamId) { team, error in
      if let err = error {
        weakSelf?.isRequest = false
        completion(err)
      } else {
        let teamInfo = NETeamInfoModel()
        teamInfo.team = team
        if var members = NETeamMemberCache.shared.getTeamMemberCache(teamId), team?.memberCount == members.count {
          members.removeAll { model in
            if let account = model.nimUser?.user?.accountId {
              if NEAIUserManager.shared.isAIUser(account) {
                return true
              }
            }
            return false
          }
          teamInfo.users = members
          weakSelf?.teamInfoModel = teamInfo
          weakSelf?.datas.removeAll()
          weakSelf?.showDatas.removeAll()
          weakSelf?.getData()
          weakSelf?.isRequest = false
          completion(nil)
        } else {
          var memberLists = [V2NIMTeamMember]()

          weakSelf?.getSelectMemberInfos(teamId, nil, &memberLists, .TEAM_MEMBER_ROLE_QUERY_TYPE_ALL) { ms, error in
            if error != nil {
              NEALog.infoLog(ModuleName + " " + (weakSelf?.className() ?? ""), desc: "CALLBACK fetchTeamMember \(String(describing: error))")
              weakSelf?.isRequest = false
              completion(nil)
            } else {
              if let members = ms {
                weakSelf?.splitSelectMembers(members, teamInfo, 150) { error, model in
                  if var users = model?.users, users.count > 0 {
                    NEALog.infoLog(weakSelf?.className() ?? "", desc: "set team member cache success.")
                    NETeamMemberCache.shared.setCacheMembers(teamId, users)

                    users.removeAll { model in
                      if let account = model.nimUser?.user?.accountId {
                        if NEAIUserManager.shared.isAIUser(account) {
                          return true
                        }
                      }
                      return false
                    }
                    model?.users = users
                  }
                  weakSelf?.teamInfoModel = model
                  weakSelf?.isRequest = false
                  weakSelf?.getData()
                  completion(error)
                }
              } else {
                weakSelf?.isRequest = false
                completion(error)
              }
            }
          }
        }
      }
    }
  }

  /// 获取选择器数据
  func getData() {
    var temFilters = Set<String>()
    for (key, _) in selectDic {
      temFilters.insert(key)
    }
    managerSet.removeAll()

    teamInfoModel?.users.forEach { [weak self] userModel in
      if let uid = userModel.nimUser?.user?.accountId {
        temFilters.remove(uid)
        if uid == IMKitClient.instance.account() {
          return
        }
        if uid == self?.teamInfoModel?.team?.ownerAccountId {
          return
        }
        if userModel.teamMember?.memberRole == .TEAM_MEMBER_ROLE_MANAGER {
          self?.managerSet.insert(uid)
          self?.selectDic.removeValue(forKey: uid)
          return
        }
      }
      let selectMember = NESelectTeamMember()
      selectMember.member = userModel
      self?.datas.append(selectMember)
      self?.showDatas.append(selectMember)
    }
    for uid in temFilters {
      selectDic.removeValue(forKey: uid)
    }
    for member in datas {
      if let accid = member.member?.nimUser?.user?.accountId {
        if selectDic.contains(where: { (key: String, value: NETeamMemberInfoModel) in
          key == accid
        }) {
          member.isSelected = true
        }
      }
    }
  }

  /// 数据缓存变更
  func memberCacheDidChange() {
    if let tid = teamInfoModel?.team?.teamId {
      print("memberCacheDidChange tid \(tid)")
      weak var weakSelf = self
      getTeamInfo(tid) { error in
        if error == nil {
          self.delegate?.didNeedRefresh()
        } else {
          NEALog.infoLog(weakSelf?.className() ?? "", desc: #function + "memberCacheDidChange get team info error \(error?.localizedDescription ?? ""))")
        }
      }
    }
  }

  /// 搜索所有数据
  /// - Parameter searchText: 搜索关键字
  func searchAllData(_ searchText: String) -> [NESelectTeamMember] {
    let result = datas.filter { findContainStr(searchText, $0) }
    return result
  }

  /// 所有展示数据
  /// - Parameter searchText: 搜索关键字
  func searchShowData(_ searchText: String) -> [NESelectTeamMember] {
    let result = showDatas.filter { findContainStr(searchText, $0) }
    return result
  }

  /// 判断选择器对象是否包含搜索字段
  func findContainStr(_ text: String, _ selectModel: NESelectTeamMember) -> Bool {
    if let uid = selectModel.member?.nimUser?.user?.accountId, uid.contains(text) {
      return true
    } else if let nick = selectModel.member?.nimUser?.user?.name, nick.contains(text) {
      return true
    } else if let alias = selectModel.member?.nimUser?.friend?.alias, alias.contains(text) {
      return true
    } else if let tNick = selectModel.member?.teamMember?.teamNick, tNick.contains(text) {
      return true
    }
    return false
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

  /// 群成员更新回调
  /// - Parameter teamMembers: 群成员列表
  public func onTeamMemberInfoUpdated(_ teamMembers: [V2NIMTeamMember]) {
    onTeamMemberChanged(teamMembers)
  }

  /// 群成员变更统一处理
  /// - Parameter teamMembers: 群成员
  private func onTeamMemberChanged(_ members: [V2NIMTeamMember]) {
    var isCurrentTeam = false
    for member in members {
      if let currentTid = teamInfoModel?.team?.teamId, currentTid == member.teamId {
        isCurrentTeam = true
        break
      }
    }

    if isCurrentTeam == true {
      if let tid = teamInfoModel?.team?.teamId {
        getTeamInfo(tid) { [weak self] error in
          if error == nil {
            self?.delegate?.didNeedRefresh()
          }
        }
      }
    }
  }

  /// 获取群成员
  /// - Parameter queryType:  查询类型
  /// - Parameter teamModel：群信息对象
  /// - Parameter completion:  完成后的回调
  private func getTeamMembers(_ teamInfo: NETeamInfoModel,
                              _ queryType: V2NIMTeamMemberRoleQueryType,
                              _ completion: @escaping (NSError?, NETeamInfoModel?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamid:\(teamInfo.team?.teamId ?? "")")
    guard let teamId = teamInfo.team?.teamId else {
      return
    }

    weak var weakSelf = self

    if let members = NETeamMemberCache.shared.getTeamMemberCache(teamId) {
      teamInfo.users = members
      completion(nil, teamInfo)
      NEALog.infoLog(weakSelf?.className() ?? "", desc: "load team member from cache success.")
      return
    }

    var memberLists = [V2NIMTeamMember]()

    weakSelf?.getSelectMemberInfos(teamId, nil, &memberLists, queryType) { ms, error in
      if let e = error {
        NEALog.infoLog(ModuleName + " " + (weakSelf?.className() ?? ""), desc: "CALLBACK fetchTeamMember \(String(describing: error))")
        completion(e, nil)
      } else {
        if let members = ms {
          weakSelf?.splitSelectMembers(members, teamInfo, 150) { error, model in
            if let users = model?.users, users.count > 0 {
              NEALog.infoLog(weakSelf?.className() ?? "", desc: "set team member cache success.")
              NETeamMemberCache.shared.setCacheMembers(teamId, users)
            }
            completion(error, model)
          }
        } else {
          completion(error, teamInfo)
        }
      }
    }
  }

  /// 分页查询群成员信息
  /// - Parameter members:          要查询的群成员列表
  /// - Parameter model :           群信息
  /// - Parameter maxSizeByPage:    单页最大查询数量
  /// - Parameter completion:       完成后的回调
  private func splitSelectMembers(_ members: [V2NIMTeamMember],
                                  _ model: NETeamInfoModel,
                                  _ maxSizeByPage: Int = 150,
                                  _ completion: @escaping (NSError?, NETeamInfoModel?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", members.count:\(members.count)")
    var remaind = [[V2NIMTeamMember]]()
    remaind.append(contentsOf: members.chunk(maxSizeByPage))
    fetchSelectUsersInfo(&remaind, model, completion)
  }

  /// 从云信服务器批量获取用户资料
  ///   - Parameter remainUserIds: 用户集合
  ///   - Parameter model： 群信息
  ///   - Parameter completion: 成功回调
  private func fetchSelectUsersInfo(_ remainUserIds: inout [[V2NIMTeamMember]],
                                    _ model: NETeamInfoModel,
                                    _ completion: @escaping (NSError?, NETeamInfoModel?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", remainUserIds.count:\(remainUserIds.count)")
    guard let members = remainUserIds.first else {
      completion(nil, model)
      return
    }

    let accids = members.map(\.accountId)
    var temArray = remainUserIds
    weak var weakSelf = self

    ContactRepo.shared.getUserWithFriend(accountIds: accids) { infos, v2Error in
      if let err = v2Error {
        completion(err as NSError, model)
      } else {
        if let users = infos {
          for index in 0 ..< members.count {
            let memberInfoModel = NETeamMemberInfoModel()
            memberInfoModel.teamMember = members[index]
            if users.count > index {
              let user = users[index]
              memberInfoModel.nimUser = user
            }
            model.users.append(memberInfoModel)
          }
        }
        temArray.removeFirst()
        weakSelf?.fetchSelectUsersInfo(&temArray, model, completion)
      }
    }
  }

  /// 获取群成员
  /// - Parameter teamId:  群ID
  /// - Parameter completion:  完成回调
  private func getSelectMemberInfos(_ teamId: String, _ nextToken: String? = nil, _ memberList: inout [V2NIMTeamMember], _ queryType: V2NIMTeamMemberRoleQueryType, _ completion: @escaping ([V2NIMTeamMember]?, NSError?) -> Void) {
    let option = V2NIMTeamMemberQueryOption()
    option.limit = 1000
    option.onlyChatBanned = false
    option.direction = .QUERY_DIRECTION_ASC
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
            self?.getSelectMemberInfos(teamId, result?.nextToken, &temMemberLists, queryType, completion)
          }
        }
      }
    }
  }
}
