// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit
import NIMSDK

@objcMembers
open class TeamMemberSelectVM: NSObject {
  public var teamRepo = TeamRepo.shared
  private let className = "TeamMemberSelectVM"

  let teamProvider = TeamProvider.shared

  open func fetchTeamMembers(_ teamId: String,
                             _ completion: @escaping (Error?, NETeamInfoModel?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", teamId: " + teamId)
    getTeamWithMembers(teamId, .TEAM_MEMBER_ROLE_QUERY_TYPE_ALL, completion)
  }

  /// 分页查询群成员信息
  /// - Parameter members:          要查询的群成员列表
  /// - Parameter model :           群信息
  /// - Parameter maxSizeByPage:    单页最大查询数量
  /// - Parameter completion:       完成后的回调
  public func splitTeamMember(_ members: [V2NIMTeamMember],
                              _ model: NETeamInfoModel,
                              _ maxSizeByPage: Int = 150,
                              _ completion: @escaping (NSError?, NETeamInfoModel?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", members.count:\(members.count)")
    var remaind = [[V2NIMTeamMember]]()
    remaind.append(contentsOf: members.chunk(maxSizeByPage))
    fetchAtListUserInfo(&remaind, model, completion)
  }

  /// 获取群信息
  /// - Parameter teamId:  群id
  /// - Parameter queryType:  查询类型
  /// - Parameter completion:  完成后的回调
  public func getTeamWithMembers(_ teamId: String,
                                 _ queryType: V2NIMTeamMemberRoleQueryType,
                                 _ completion: @escaping (NSError?, NETeamInfoModel?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", teamid:\(teamId)")
    weak var weakSelf = self

    teamRepo.getTeamInfo(teamId) { team, error in
      if let err = error {
        NEALog.infoLog(ModuleName + " " + (weakSelf?.className() ?? ""), desc: "CALLBACK fetchTeamInfo \(String(describing: error))")
        completion(err, nil)
      } else {
        var memberLists = [V2NIMTeamMember]()

        weakSelf?.getAllTeamMemberList(teamId, nil, &memberLists, queryType) { ms, error in
          if let e = error {
            NEALog.infoLog(ModuleName + " " + (weakSelf?.className() ?? ""), desc: "CALLBACK fetchTeamMember \(String(describing: error))")
            completion(e, nil)
          } else {
            let model = NETeamInfoModel()
            model.team = team
            if let members = ms {
              weakSelf?.splitTeamMember(members, model, 150, completion)
            } else {
              completion(error, model)
            }
          }
        }
      }
    }
  }

  /// 从云信服务器批量获取用户资料
  ///   - Parameter remainUserIds:  用户集合
  ///   - Parameter completion:    成功回调
  private func fetchAtListUserInfo(_ remainUserIds: inout [[V2NIMTeamMember]],
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

    ContactRepo.shared.getUserWithFriend(accountIds: accids) { users, v2Error in
      if let err = v2Error {
        completion(err as NSError, model)
      } else {
        if let us = users {
          for index in 0 ..< members.count {
            let memberInfoModel = NETeamMemberInfoModel()
            memberInfoModel.teamMember = members[index]
            if us.count > index {
              let user = us[index]
              memberInfoModel.nimUser = user
            }
            model.users.append(memberInfoModel)
          }
        }
        temArray.removeFirst()
        weakSelf?.fetchAtListUserInfo(&temArray, model, completion)
      }
    }
  }

  /// 获取群成员
  /// - Parameter teamId:  群ID
  /// - Parameter completion:  完成回调
  public func getAllTeamMemberList(_ teamId: String, _ nextToken: String? = nil, _ memberList: inout [V2NIMTeamMember], _ queryType: V2NIMTeamMemberRoleQueryType, _ completion: @escaping ([V2NIMTeamMember]?, NSError?) -> Void) {
    let option = V2NIMTeamMemberQueryOption()
    if let token = nextToken {
      option.nextToken = token
    } else {
      option.nextToken = ""
    }
    option.limit = 1000
    option.direction = .QUERY_DIRECTION_ASC
    option.onlyChatBanned = false
    option.roleQueryType = queryType
    var temMemberLists = memberList
    teamProvider.getTeamMemberList(teamId: teamId, teamType: .TEAM_TYPE_NORMAL, queryOption: option) { result, error in
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
            self.getAllTeamMemberList(teamId, result?.nextToken, &temMemberLists, queryType, completion)
          }
        }
      }
    }
  }
}
