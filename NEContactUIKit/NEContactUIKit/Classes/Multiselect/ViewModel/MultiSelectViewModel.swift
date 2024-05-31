// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import UIKit

@objcMembers
open class MultiSelectViewModel: ContactViewModel {
  public var conversationRepo = ConversationRepo.shared
  public var teamRepo = TeamRepo.shared
  public var settingRepo = SettingRepo.shared

  var conversationLimit = 100 // 最近会话最大数量
  var conversationList = [MultiSelectModel]() // 最近会话缓存
  var contactList = [MultiSelectModel]() // 好友缓存
  var teamList = [MultiSelectModel]() // 群组缓存
  public var sessions = [MultiSelectModel]() // 当前展示列表

  /// 初始化
  init() {
    super.init(contactHeaders: nil)
  }

  /// 加载所有数据
  /// - Parameters:
  ///   - filters: 需要过滤的会话id列表
  ///   - completion: 完成回调
  func loadAllData(_ filters: Set<String>? = nil, _ completion: @escaping (NSError?) -> Void) {
    // 加载群聊
    loadData(2, filters) { [weak self] error in
      if let err = error {
        self?.sessions.removeAll()
        completion(err)
        return
      }

      // 加载好友
      self?.loadData(1, filters) { error in
        if let err = error {
          self?.sessions.removeAll()
          completion(err)
          return
        }

        // 加载最近会话
        self?.loadData(0, filters, completion)
      }
    }
  }

  /// 加载数据
  /// - Parameters:
  ///   - index: 0 - 最近会话；1 - 我的好友；2 - 我的群聊
  ///   - filters: 需要过滤的会话id列表
  ///   - completion: 完成回调
  func loadData(_ index: Int, _ filters: Set<String>? = nil, _ completion: @escaping (NSError?) -> Void) {
    sessions.removeAll()
    if index == 0 {
      if conversationList.isEmpty {
        getConversationList(filters) { [weak self] error in
          if let conversationList = self?.conversationList {
            self?.sessions = conversationList
          }
          completion(error)
        }
      } else {
        sessions = conversationList
        completion(nil)
      }
    } else if index == 1 {
      if contactList.isEmpty {
        getContactList(filters) { [weak self] error in
          if let contactList = self?.contactList {
            self?.sessions = contactList
          }
          completion(error)
        }
      } else {
        sessions = contactList
        completion(nil)
      }
    } else if index == 2 {
      if teamList.isEmpty {
        getTeamList(filters) { [weak self] error in
          if let teamList = self?.teamList {
            self?.sessions = teamList
          }
          completion(error)
        }
      } else {
        sessions = teamList
        completion(nil)
      }
    }
  }

  /// 加载最近转发
  /// - Returns: 最近转发列表
  func loadRecentForward() -> [MultiSelectModel] {
    var recentSessions = [MultiSelectModel]()

    var recentList = settingRepo.getRecentForward() ?? []
    for recent in recentList {
      // 从最近会话中查找对应的会话
      if let session = conversationList.first(where: { $0.conversationId == recent }) {
        recentSessions.append(session)
        continue
      }

      // 从我的好友中查找对应的会话
      if let session = contactList.first(where: { $0.conversationId == recent }) {
        recentSessions.append(session)
        continue
      }

      // 从我的群聊中查找对应的会话
      if let session = teamList.first(where: { $0.conversationId == recent }) {
        recentSessions.append(session)
        continue
      }

      // 移除失效的会话
      recentList.removeAll(where: { $0 == recent })
      settingRepo.updateRecentForward(recentList)
    }

    return recentSessions
  }

  /// 获取会话列表
  /// - Parameters:
  ///   - filters: 需要过滤的会话id列表
  ///   - completion: 完成回调
  func getConversationList(_ filters: Set<String>? = nil, _ completion: @escaping (NSError?) -> Void) {
    conversationRepo.getConversationList(0, conversationLimit) { [weak self] conversations, offset, finished, error in
      if let error = error {
        NEALog.errorLog(ModuleName + " " + MultiSelectViewModel.className(), desc: #function + ", error: " + error.localizedDescription)
      } else if var conversations = conversations {
        // 过滤
        if let filterConvs = filters {
          conversations = conversations.filter { !filterConvs.contains($0.conversationId) }
        }

        for conversation in conversations {
          let model = MultiSelectModel()

          // 校验好友是否已存在
          if let model = self?.findFriend(conversation.conversationId) {
            self?.conversationList.append(model)
            continue
          }

          // 校验群聊是否已存在
          if let model = self?.findTeam(conversation.conversationId) {
            self?.conversationList.append(model)
            continue
          }

          model.conversationId = conversation.conversationId
          model.name = conversation.name
          model.avatar = conversation.avatar
          self?.conversationList.append(model)
        }
      }
      completion(error)
    }
  }

  /// 获取好友列表
  /// - Parameters:
  ///   - filters: 需要过滤的好友id列表
  ///   - completion: 完成回调
  func getContactList(_ filters: Set<String>? = nil, _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", filters.count: \(filters?.count ?? 0)")

    getContactList(filters) { [weak self] result, error in
      for item in result ?? [] {
        for contact in item.contacts {
          let conversationId = V2NIMConversationIdUtil.p2pConversationId(contact.user?.user?.accountId ?? "")
          let model = MultiSelectModel()
          model.conversationId = conversationId
          model.avatar = contact.user?.user?.avatar
          model.name = contact.user?.showName() ?? ""
          self?.contactList.append(model)
        }
      }
      completion(error)
    }
  }

  /// 获取群聊列表
  /// - Parameters:
  ///   - filters: 需要过滤的群id列表
  ///   - completion: 完成回调
  func getTeamList(_ filters: Set<String>? = nil, _ completion: @escaping (NSError?) -> Void) {
    teamRepo.getTeamList { [weak self] teams, error in
      if let error = error {
        NEALog.errorLog(ModuleName + " " + MultiSelectViewModel.className(), desc: #function + ", error: " + error.localizedDescription)
      } else if var teams = teams {
        // 过滤
        if let filterTeams = filters {
          teams = teams.filter { !filterTeams.contains($0.teamId ?? "") }
        }

        teams.sort(by: { team1, team2 in
          (team1.createTime ?? 0) > (team2.createTime ?? 0)
        })

        for team in teams {
          let conversationId = V2NIMConversationIdUtil.teamConversationId(team.teamId ?? "")
          let model = MultiSelectModel()
          model.conversationId = conversationId
          model.name = team.teamName
          model.avatar = team.avatarUrl
          model.memberCount = team.memberNumber ?? 0
          self?.teamList.append(model)
        }

        completion(nil)
      }
    }
  }

  /// 在好友缓存中查找该会话
  /// - Parameter conversationId: 会话id
  /// - Returns: 存在则返回该回话，不存在返回 nil
  func findFriend(_ conversationId: String?) -> MultiSelectModel? {
    for conv in contactList {
      if conv.conversationId == conversationId {
        return conv
      }
    }
    return nil
  }

  /// 在群聊缓存中查找该会话
  /// - Parameter conversationId: 会话id
  /// - Returns: 存在则返回该回话，不存在返回 nil
  func findTeam(_ conversationId: String?) -> MultiSelectModel? {
    for conv in teamList {
      if conv.conversationId == conversationId {
        return conv
      }
    }
    return nil
  }

  func searchText(_ text: String) {
    if text.isEmpty {
      return
    }
    sessions = sessions.filter { $0.name?.contains(text) == true }
  }
}
