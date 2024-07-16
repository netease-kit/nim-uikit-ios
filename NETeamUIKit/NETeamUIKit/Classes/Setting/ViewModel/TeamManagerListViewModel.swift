//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

public protocol TeamManagerListViewModelDelegate: NSObject {
  func didNeedReloadData()
}

@objcMembers
open class TeamManagerListViewModel: NSObject, NETeamListener {
  /// 群API 单例
  public let teamRepo = TeamRepo.shared
  /// 当前用户的群成员对象
  public var currentMember: V2NIMTeamMember?

  public var managers = [NETeamMemberInfoModel]()

  weak var delegate: TeamManagerListViewModelDelegate?
  /// 群 id
  public var teamId: String?

  /// 是否正在请求数据
  public var isRequest = false

  override public init() {
    super.init()
    teamRepo.addTeamListener(self)
    ContactRepo.shared.addContactListener(self)
    NotificationCenter.default.addObserver(self, selector: #selector(didTapHeader), name: NENotificationName.didTapHeader, object: nil)
  }

  deinit {
    teamRepo.removeTeamListener(self)
    ContactRepo.shared.removeContactListener(self)
  }

  /// 点击消息发送者头像
  /// 拉取最新用户信息后刷新消息发送者信息
  /// - Parameter noti: 通知对象
  func didTapHeader(_ noti: Notification) {
    if let user = noti.object as? NEUserWithFriend,
       let accid = user.user?.accountId {
      if NETeamMemberCache.shared.isCurrentMember(accid) {
        var isDidFind = false
        for model in managers {
          if let accountId = model.nimUser?.user?.accountId, accountId == accid {
            model.nimUser = user
            isDidFind = true
          }
        }
        if isDidFind == true {
          delegate?.didNeedReloadData()
        }
      }
    }
  }

  /// 获取群成员信息
  /// - Parameter teamId: 群id
  /// - Parameter completion: 结果回调
  open func getManagerDatas(_ teamId: String, _ completion: @escaping (Error?) -> Void) {
    getTeamInfo(teamId) { [weak self] model, error in
      if error == nil {
        self?.managers.removeAll()
        model?.users.forEach { model in
          if model.teamMember?.memberRole == .TEAM_MEMBER_ROLE_MANAGER {
            self?.managers.append(model)
          }
        }
        completion(nil)
      } else {
        completion(error)
      }
    }
  }

  /// 获当前登录用户的群成员信息
  /// - Parameter teamId: 群id
  /// - Parameter completion: 完成回调
  func getCurrentUserTeamMember(_ teamId: String, _ completion: @escaping (NSError?) -> Void) {
    weak var weakSelf = self
    teamRepo.getTeamMember(teamId, .TEAM_TYPE_NORMAL, IMKitClient.instance.account()) { member, error in
      weakSelf?.currentMember = member
      completion(error)
    }
  }

  /// 添加管理员
  /// - Parameter teamId: 群id
  /// - Parameter uids: 用户id
  /// - Parameter completion: 结果回调
  open func addTeamManager(_ teamId: String, _ uids: [String], _ completion: @escaping (Error?) -> Void) {
    teamRepo.addManagers(teamId, .TEAM_TYPE_NORMAL, uids) { error in
      completion(error)
    }
  }

  /// 移除管理员
  /// - Parameter teamId: 群id
  /// - Parameter uids: 用户id
  /// - Parameter completion: 结果回调
  open func removeTeamManager(_ teamId: String, _ uids: [String], _ completion: @escaping (Error?) -> Void) {
    teamRepo.removeManagers(teamId, .TEAM_TYPE_NORMAL, uids) { error in
      completion(error)
    }
  }

  /// 获取当前群成员信息
  /// - Parameter teamId: 群id
  open func getCurrentMember(_ teamId: String) {
    weak var weakSelf = self
    teamRepo.getTeamMember(teamId, .TEAM_TYPE_NORMAL, IMKitClient.instance.account()) { member, error in
      weakSelf?.currentMember = member
    }
  }

  /// 刷新数据
  func refreshData() {
    guard let tid = teamId else {
      return
    }
    getManagerDatas(tid) { [weak self] error in
      if error == nil {
        self?.delegate?.didNeedReloadData()
      }
    }
  }

  ///  群成员离开
  ///  - Parameter teamMembers: 群成员
  public func onTeamMemberLeft(_ teamMembers: [V2NIMTeamMember]) {
    onTeamMemberChanged(teamMembers)
  }

  /// 群成员被踢
  /// - Parameter operatorAccountId: 操作者id
  /// - Parameter teamMembers: 群成员
  public func onTeamMemberKicked(_ operatorAccountId: String, teamMembers: [V2NIMTeamMember]) {
    onTeamMemberChanged(teamMembers)
  }

  /// 群成员加入
  /// - Parameter teamMembers: 群成员
  public func onTeamMemberJoined(_ teamMembers: [V2NIMTeamMember]) {
    onTeamMemberChanged(teamMembers)
  }

  public func onTeamMemberInfoUpdated(_ teamMembers: [V2NIMTeamMember]) {
    onTeamMemberChanged(teamMembers)
  }

  public func onTeamLeft(_ team: V2NIMTeam, isKicked: Bool) {}

  /// 群信息更新
  /// - Parameter team: 群对象
  private func onTeamMemberChanged(_ members: [V2NIMTeamMember]) {
    var isCurrentTeam = false
    for member in members {
      if let currentTid = teamId, currentTid == member.teamId {
        isCurrentTeam = true
        break
      }
    }

    if isCurrentTeam == true {
      guard let tid = teamId else {
        return
      }

      getManagerDatas(tid) { [weak self] error in
        if error == nil {
          self?.delegate?.didNeedReloadData()
        }
      }
    }
  }

  /// 获取群信息(包含管理员)
  /// - Parameter teamId: 群id
  /// - Parameter completion: 完成回调
  func getTeamInfo(_ teamId: String, _ completion: @escaping (NETeamInfoModel?, NSError?) -> Void) {
    weak var weakSelf = self
    if isRequest == true {
      return
    }
    isRequest = true
    getCurrentUserTeamMember(teamId) { error in
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
            weakSelf?.getTeamManagers(model, .TEAM_MEMBER_ROLE_QUERY_TYPE_MANAGER) { error, teamInfo in
              weakSelf?.isRequest = false
              if let err = error {
                completion(nil, err)
              } else {
                if let datas = teamInfo?.users {
                  weakSelf?.managers.removeAll()
                  weakSelf?.managers.append(contentsOf: datas)
                  weakSelf?.managers.sort(by: { model1, model2 in
                    if let time1 = model1.teamMember?.joinTime, let time2 = model2.teamMember?.joinTime {
                      return time2 > time1
                    }
                    return false
                  })
                }
                completion(teamInfo, error)
              }
            }
          }
        }
      }
    }
  }

  /// 获取群管理员
  /// - Parameter teamModel：群信息对象
  /// - Parameter queryType:  查询类型
  /// - Parameter completion:  完成后的回调
  private func getTeamManagers(_ teamInfo: NETeamInfoModel,
                               _ queryType: V2NIMTeamMemberRoleQueryType,
                               _ completion: @escaping (NSError?, NETeamInfoModel?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamid:\(teamInfo.team?.teamId ?? "")")
    guard let teamId = teamInfo.team?.teamId else {
      return
    }

    weak var weakSelf = self
    var memberLists = [V2NIMTeamMember]()

    weakSelf?.getAllTeamManagerInfos(teamId, nil, &memberLists, queryType) { ms, error in
      if let e = error {
        NEALog.infoLog(ModuleName + " " + (weakSelf?.className() ?? ""), desc: "CALLBACK fetchTeamMember \(String(describing: error))")
        completion(e, nil)
      } else {
        if let members = ms {
          weakSelf?.splitTeamManagers(members, teamInfo, 150) { error, model in
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
  private func splitTeamManagers(_ members: [V2NIMTeamMember],
                                 _ model: NETeamInfoModel,
                                 _ maxSizeByPage: Int = 150,
                                 _ completion: @escaping (NSError?, NETeamInfoModel?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", members.count:\(members.count)")
    var remaind = [[V2NIMTeamMember]]()
    remaind.append(contentsOf: members.chunk(maxSizeByPage))
    fetchManagersInfo(&remaind, model, completion)
  }

  /// 从云信服务器批量获取用户资料
  ///   - Parameter remainUserIds: 用户集合
  ///   - Parameter model： 群信息
  ///   - Parameter completion: 成功回调
  private func fetchManagersInfo(_ remainUserIds: inout [[V2NIMTeamMember]],
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
        weakSelf?.fetchManagersInfo(&temArray, model, completion)
      }
    }
  }

  /// 获取群管理员
  /// - Parameter teamId:  群ID
  /// - Parameter nextToken: 下一页标识
  /// - Parameter completion:  完成回调
  private func getAllTeamManagerInfos(_ teamId: String, _ nextToken: String? = nil, _ memberList: inout [V2NIMTeamMember], _ queryType: V2NIMTeamMemberRoleQueryType, _ completion: @escaping ([V2NIMTeamMember]?, NSError?) -> Void) {
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
            self?.getAllTeamManagerInfos(teamId, result?.nextToken, &temMemberLists, queryType, completion)
          }
        }
      }
    }
  }
}

// MARK: - NEContactListener

extension TeamManagerListViewModel: NEContactListener {
  /// 好友信息缓存更新
  /// - Parameter accountId: 用户 id
  public func onContactChange(_ changeType: NEContactChangeType, _ contacts: [NEUserWithFriend]) {
    for contact in contacts {
      for memberInfo in managers {
        if memberInfo.teamMember?.accountId == contact.user?.accountId {
          memberInfo.nimUser = contact
          delegate?.didNeedReloadData()
        }
      }
    }
  }
}
