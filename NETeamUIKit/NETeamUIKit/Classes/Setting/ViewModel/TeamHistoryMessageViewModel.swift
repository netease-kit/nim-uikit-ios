//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import NECoreIM2Kit
import NIMSDK
import UIKit

@objcMembers
open class TeamHistoryMessageViewModel: NSObject, NETeamListener {
  /// 群信息
  public var teamInfoModel: NETeamInfoModel?
  /// 搜索结果
  public var searchResultInfos: [HistoryMessageModel]?

  /// 群模块API单例
  public let teamRepo = TeamRepo.shared

  /// 通讯录模块API单例
  public let contactRepo = ContactRepo.shared

  /// 消息模块API单例
  public let chatRepo = ChatRepo.shared

  /// 群成员缓存
  public var memberModelCacheDic = [String: NETeamMemberInfoModel]()

  override public init() {
    super.init()
    teamRepo.addTeamListener(self)
    contactRepo.addContactListener(self)
  }

  deinit {
    teamRepo.removeTeamListener(self)
    contactRepo.removeContactListener(self)
  }

  /// 设置从上一个页面传入的成员
  public func setupCache() {
    teamInfoModel?.users.forEach { member in
      if let accountId = member.teamMember?.accountId {
        memberModelCacheDic[accountId] = member
      }
    }
  }

  /// 消息搜索
  /// - Parameter teamId: 群id
  /// - Parameter searchContent: 搜索内容
  open func searchHistoryMessages(_ teamId: String?, _ searchContent: String, _ completion: @escaping (Error?, [HistoryMessageModel]?) -> Void) {
    var infoDic = [String: NETeamMemberInfoModel]()
    for (key, value) in memberModelCacheDic {
      if let accountId = value.teamMember?.accountId {
        infoDic[accountId] = value
      }
    }

    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", searchContent:\(searchContent)")
    guard let teamId = teamId else {
      completion(NSError(domain: "teamId is nil", code: -1), nil)
      return
    }

    let param = V2NIMMessageSearchParams()
    param.keyword = searchContent
    param.teamIds = [teamId]

    weak var weakSelf = self
    chatRepo.searchMessages(params: param) { messages, error in

      if error == nil {
        // 未找到用户信息信息记录
        var noFindUserSet = Set<String>()
        for message in messages ?? [] {
          if let uid = ChatMessageHelper.getSenderId(message.imMessage) {
            if let member = infoDic[uid] {
              message.avatar = member.nimUser?.user?.avatar
              message.fullName = member.atNameInTeam()
              message.shortName = member.getShortName(member.showNickInTeam() ?? "")
            } else if let aiUser: V2NIMAIUser = NEAIUserManager.shared.getAIUserById(uid) {
              message.avatar = aiUser.avatar
              message.fullName = aiUser.showName()
              message.shortName = aiUser.shortName()
            } else {
              noFindUserSet.insert(uid)
            }
          }
        }
        if noFindUserSet.count > 0 {
          let accids = Array(noFindUserSet)
          weakSelf?.getSearchMessageMembers(teamId, accids) { error, members in
            if let err = error {
              completion(err, nil)
            } else {
              members?.forEach { member in
                if let accountId = member.teamMember?.accountId {
                  infoDic[accountId] = member
                  weakSelf?.memberModelCacheDic[accountId] = member
                }
              }
              if let historyMessages = messages {
                weakSelf?.bindMessageUserInfo(historyMessages, infoDic)
              }
              weakSelf?.searchResultInfos = messages
              completion(nil, messages)
            }
          }
        } else {
          weakSelf?.searchResultInfos = messages
          completion(nil, messages)
        }
      } else {
        completion(error, nil)
      }
    }
  }

  /// 获取消息对应的用户信息
  public func bindMessageUserInfo(_ messages: [HistoryMessageModel], _ infoDic: [String: NETeamMemberInfoModel]) {
    for message in messages {
      if let uid = ChatMessageHelper.getSenderId(message.imMessage) {
        if let member = infoDic[uid] {
          message.avatar = member.nimUser?.user?.avatar
          message.fullName = member.atNameInTeam()
          message.shortName = member.getShortName(member.showNickInTeam() ?? "")
        }
      }
    }
  }

  /// 获取群信息
  public func getTeamInfo(_ teamId: String?, _ completion: @escaping (V2NIMTeam?, NSError?) -> Void) {
    guard let tid = teamId else {
      return
    }
    teamRepo.getTeamInfo(tid) { team, error in
      completion(team, error)
    }
  }

  /// 获取搜索消息中关联的群成员信息
  /// - Parameter teamId: 群id
  /// - Parameter accounts: 群成员id列表
  /// - Parameter completion: 完成回调
  public func getSearchMessageMembers(_ teamId: String, _ accounts: [String], _ completion: @escaping (NSError?, [NETeamMemberInfoModel]?) -> Void) {
    weak var weakSelf = self
    teamRepo.getTeamMemberListByIds(teamId, .TEAM_TYPE_NORMAL, accounts) { members, error in
      if let err = error {
        completion(err, nil)
      } else {
        if let ms = members {
          weakSelf?.getUsersInfo(ms) { error, memberInfos in
            var retMembers = [NETeamMemberInfoModel]()
            memberInfos?.forEach { member in
              retMembers.append(member)
            }
            completion(nil, retMembers)
          }
        } else {
          completion(nil, nil)
        }
      }
    }
  }

  /// 根据成员信息获取用户信息
  /// - Parameter members: 群成员列表
  /// - Parameter completion: 完成回调
  public func getUsersInfo(_ members: [V2NIMTeamMember], _ completion: @escaping (NSError?, [NETeamMemberInfoModel]?) -> Void) {
    var memberModels = [NETeamMemberInfoModel]()
    var accids = [String]()

    for member in members {
      accids.append(member.accountId)
      let model = NETeamMemberInfoModel()
      model.teamMember = member
      memberModels.append(model)
    }

    contactRepo.getUserWithFriend(accountIds: accids) { users, v2Error in

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

  /// 群成员变更回调
  /// - parameter teamMembers: 群成员信息对象列表
  public func onTeamMemberInfoUpdated(_ teamMembers: [V2NIMTeamMember]) {
    guard let currentTeamId = teamInfoModel?.team?.teamId else {
      return
    }
    // 判断是否有属于当前群
    var currentMembers = [V2NIMTeamMember]()
    for member in teamMembers {
      if member.teamId == currentTeamId {
        currentMembers.append(member)
      }
    }
    for member in currentMembers {
      memberModelCacheDic[member.accountId]?.teamMember = member
    }
  }
}

// MARK: - NEContactListener

extension TeamHistoryMessageViewModel: NEContactListener {
  /// 好友信息缓存更新
  /// - Parameter accountId: 用户 id
  public func onContactChange(_ changeType: NEContactChangeType, _ contacts: [NEUserWithFriend]) {
    for contact in contacts {
      if let accid = contact.user?.accountId,
         memberModelCacheDic[accid] != nil {
        memberModelCacheDic[accid]?.nimUser = contact
      }
    }
  }
}
