//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import NIMSDK
import UIKit

protocol TeamMembersViewModelDelegate: NSObject {
  func didNeedRefreshUI()
}

class TeamMembersViewModel: NSObject, NETeamListener, NEContactListener {
  /// 是否正在请求数据
  public var isRequest = false
  /// 群id
  var teamId: String?

  weak var delegate: TeamMembersViewModelDelegate?

  var datas = [NETeamMemberInfoModel]()

  /// 搜索结果数据
  public var searchDatas = [NETeamMemberInfoModel]()

  let teamRepo = TeamRepo.shared

  public var currentMember: V2NIMTeamMember?

  override init() {
    super.init()
    teamRepo.addTeamListener(self)
    ContactRepo.shared.addContactListener(self)
  }

  deinit {
    teamRepo.removeTeamListener(self)
    ContactRepo.shared.removeContactListener(self)
  }

  /// 获取群成员信息
  /// - Parameter teamId: 群id
  /// - Parameter completion: 完成回调
  func getMemberInfo(_ teamId: String, _ completion: @escaping (NSError?) -> Void) {
    weak var weakSelf = self
    teamRepo.getTeamMember(teamId, IMKitClient.instance.account()) { member, error in
      weakSelf?.currentMember = member
      completion(error)
    }
  }

  /// 移除群成员
  /// - Parameter teamdId: 群id
  /// - Parameter uids: 用户id
  func removeTeamMember(_ teamdId: String, _ uids: [String], _ completion: @escaping (NSError?) -> Void) {
    teamRepo.removeMembers(teamdId, uids) { error in
      completion(error as NSError?)
    }
  }

  /// 设置成员数据
  /// - Parameter memberDatas: 成员数据
  func setShowDatas(_ memberDatas: [NETeamMemberInfoModel]?) {
    var owner: NETeamMemberInfoModel?
    var managers = [NETeamMemberInfoModel]()
    var normalMembers = [NETeamMemberInfoModel]()

    memberDatas?.forEach { model in
      if model.teamMember?.memberRole == .TEAM_MEMBER_ROLE_OWNER {
        owner = model
      } else if model.teamMember?.memberRole == .TEAM_MEMBER_ROLE_MANAGER {
        managers.append(model)
      } else {
        normalMembers.append(model)
      }
    }

    datas.removeAll()
    if let findOwner = owner {
      datas.append(findOwner)
    }
    // managers 根据 时间排序 排序
    managers.sort { model1, model2 in
      if let time1 = model1.teamMember?.joinTime, let time2 = model2.teamMember?.joinTime {
        return time2 > time1
      }
      return false
    }
    // normalMembers 根据 时间排序 排序
    normalMembers.sort { model1, model2 in
      if let time1 = model1.teamMember?.joinTime, let time2 = model2.teamMember?.joinTime {
        return time2 > time1
      }
      return false
    }
    datas.append(contentsOf: managers)
    datas.append(contentsOf: normalMembers)
    delegate?.didNeedRefreshUI()
  }

  /// 移除成员数据(UI数据源)
  /// - Parameter model: 成员数据
  func removeModel(_ model: NETeamMemberInfoModel?) {
    guard let rmModel = model else {
      return
    }
    datas.removeAll(where: { model in
      if let rmUid = rmModel.nimUser?.user?.accountId, let uid = model.nimUser?.user?.accountId {
        if rmUid == uid {
          return true
        }
      }
      return false
    })
  }

  // MARK: - NEContactListener

  /// 好友信息变更回调
  /// - Parameter friendInfo: 好友信息
  func onFriendInfoChanged(_ friendInfo: V2NIMFriend) {
    datas.forEach { [weak self] model in
      if let accountId = model.nimUser?.user?.accountId, accountId == friendInfo.accountId {
        if let tid = self?.teamId {
          self?.getTeamInfo(tid) { model, error in
            if error == nil {
              self?.delegate?.didNeedRefreshUI()
            }
          }
        }
        return
      }
    }
  }

  /// 群成员信息更新
  /// - Parameter teamMembers: 群成员信息
  func onTeamMemberInfoUpdated(_ teamMembers: [V2NIMTeamMember]) {
    changeMembers(teamMembers)
  }

  /// 群成员离开
  /// - Parameter teamMembers: 群成员信息
  func onTeamMemberLeft(_ teamMembers: [V2NIMTeamMember]) {
    removeSearchData(teamMembers)
    changeMembers(teamMembers)
  }

  /// 判断离开用户是不是当前搜索展示用户
  /// - Parameter teamMembers: 群成员信息
  public func removeSearchData(_ teamMembers: [V2NIMTeamMember]) {
    if searchDatas.count <= 0 {
      return
    }
    var memberSet = Set<String>()
    for member in teamMembers {
      if let tid = teamId, tid == member.teamId {
        memberSet.insert(member.accountId)
      }
    }

    if memberSet.count <= 0 {
      return
    }
    searchDatas.removeAll { model in
      if let accid = model.teamMember?.accountId, memberSet.contains(accid) {
        return true
      }
      return false
    }
  }

  /// 群成员加入
  /// - Parameter teamMembers: 群成员信息
  func onTeamMemberJoined(_ teamMembers: [V2NIMTeamMember]) {
    changeMembers(teamMembers)
  }

  /// 群成员被踢
  /// - Parameter operatorAccountId: 操作者id
  /// - Parameter teamMembers: 群成员信息
  func onTeamMemberKicked(_ operatorAccountId: String, teamMembers: [V2NIMTeamMember]) {
    removeSearchData(teamMembers)
    changeMembers(teamMembers)
  }

  /// 群成员信息更新统一处理方法
  /// - Parameter teamMembers: 群成员信息
  func changeMembers(_ teamMembers: [V2NIMTeamMember]) {
    guard let tid = teamId else {
      return
    }
    var isNeedRefresh = false

    for member in teamMembers {
      if member.teamId == tid {
        isNeedRefresh = true
        break
      }
    }

    if isNeedRefresh == true {
      getTeamInfo(tid) { model, error in
        if error == nil {
          self.delegate?.didNeedRefreshUI()
        }
      }
    }
  }

  /// 获取群信息(包含群成员)
  /// - Parameter teamId: 群id
  /// - Parameter completion: 完成回调
  func getTeamInfo(_ teamId: String, _ completion: @escaping (NETeamInfoModel?, NSError?) -> Void) {
    weak var weakSelf = self
    if isRequest == true {
      return
    }
    isRequest = true

    getMemberInfo(teamId) { error in
      if let err = error {
        weakSelf?.isRequest = false
        completion(nil, err)
      } else {
        weakSelf?.teamRepo.getTeamInfo(teamId) { team, error in
          if let err = error {
            weakSelf?.isRequest = false
            completion(nil, err)
          } else {
            let model = NETeamInfoModel()
            model.team = team
            weakSelf?.getTeamMembers(model, .TEAM_MEMBER_ROLE_QUERY_TYPE_ALL) { error, teamInfo in
              weakSelf?.isRequest = false
              if let err = error {
                completion(nil, err)
              } else {
                if let datas = teamInfo?.users {
                  weakSelf?.setShowDatas(datas)
                }
                completion(teamInfo, error)
              }
            }
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

    weakSelf?.getAllTeamMemberInfos(teamId, nil, &memberLists, queryType) { ms, error in
      if let e = error {
        NEALog.infoLog(ModuleName + " " + (weakSelf?.className() ?? ""), desc: "CALLBACK fetchTeamMember \(String(describing: error))")
        completion(e, nil)
      } else {
        if let members = ms {
          weakSelf?.splitTeamMembers(members, teamInfo, 150) { error, model in
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
  private func splitTeamMembers(_ members: [V2NIMTeamMember],
                                _ model: NETeamInfoModel,
                                _ maxSizeByPage: Int = 150,
                                _ completion: @escaping (NSError?, NETeamInfoModel?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", members.count:\(members.count)")
    var remaind = [[V2NIMTeamMember]]()
    remaind.append(contentsOf: members.chunk(maxSizeByPage))
    fetchUsersInfo(&remaind, model, completion)
  }

  /// 从云信服务器批量获取用户资料
  ///   - Parameter remainUserIds: 用户集合
  ///   - Parameter model： 群信息
  ///   - Parameter completion: 成功回调
  private func fetchUsersInfo(_ remainUserIds: inout [[V2NIMTeamMember]],
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

    ContactRepo.shared.getFriendInfoList(accountIds: accids) { infos, v2Error in
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
        weakSelf?.fetchUsersInfo(&temArray, model, completion)
      }
    }
  }

  /// 获取群成员
  /// - Parameter teamId:  群ID
  /// - Parameter completion:  完成回调
  private func getAllTeamMemberInfos(_ teamId: String, _ nextToken: String? = nil, _ memberList: inout [V2NIMTeamMember], _ queryType: V2NIMTeamMemberRoleQueryType, _ completion: @escaping ([V2NIMTeamMember]?, NSError?) -> Void) {
    let option = V2NIMTeamMemberQueryOption()
    option.limit = 1000
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
            self?.getAllTeamMemberInfos(teamId, result?.nextToken, &temMemberLists, queryType, completion)
          }
        }
      }
    }
  }
}
