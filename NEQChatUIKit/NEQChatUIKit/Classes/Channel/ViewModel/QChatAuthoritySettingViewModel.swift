// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIMKit
import NEQChatKit

@objcMembers
public class QChatAuthoritySettingViewModel: NSObject {
  public var channel: ChatChannel?
  public var rolesData = QChatRoles()
  public var membersData = QChatRoles()

  private var repo = QChatRepo()
  private let className = "QChatAuthoritySettingViewModel"

  init(channel: ChatChannel?) {
    self.channel = channel
  }

  func firstGetChannelRoles(_ completion: @escaping (Error?, [RoleModel]?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    rolesData.timeTag = 0
    rolesData.roles = [RoleModel]()
    getChannelRoles(completion)
  }

  func getChannelRoles(_ completion: @escaping (Error?, [RoleModel]?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    guard let sid = channel?.serverId, let cid = channel?.channelId else {
      completion(NSError.paramError(), nil)
      return
    }
    var param = ChannelRoleParam(serverId: sid, channelId: cid)
    param.limit = rolesData.pageSize
    param.timeTag = rolesData.timeTag
    repo.getChannelRoles(param) { [weak self] error, roleList in
      print("error:\(error) roleList:\(roleList)")
      if error != nil {
        completion(error, self?.rolesData.roles)
      } else {
        // 移除占位
        if let last = self?.rolesData.roles.last, last.isPlacehold {
          self?.rolesData.roles.removeLast()
        }

        if let roles = roleList, roles.count > 0 {
          // 添加身份组
          for role in roles {
            var model = RoleModel()
            model.role = role
            self?.rolesData.roles.append(model)
          }
          // 记录最后一个身份组的时间戳 用于下页请求
          self?.rolesData.timeTag = self?.rolesData.roles.last?.role?.createTime

          // 添加占位
          if roles.count >= self?.rolesData.pageSize ?? 5 {
            var placeholdModel = RoleModel()
            placeholdModel.title = localizable("more")
            placeholdModel.isPlacehold = true
            self?.rolesData.roles.append(placeholdModel)
          }
          self?.setRoundedCorner()
          // 设置圆角
          completion(error, self?.rolesData.roles)
        } else {
          // 设置圆角
          self?.setRoundedCorner()
          completion(error, self?.rolesData.roles)
        }
      }
    }
  }

  func firstGetMembers(_ completion: @escaping (Error?, [RoleModel]?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    membersData.pageSize = 50
    membersData.timeTag = 0
    membersData.roles = [RoleModel]()
    getMembers(completion)
  }

  func getMembers(_ completion: @escaping (Error?, [RoleModel]?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    guard let sid = channel?.serverId, let cid = channel?.channelId else {
      completion(NSError.paramError(), nil)
      return
    }
    var param = GetMemberRolesParam()
    param.serverId = sid
    param.channelId = cid
    param.limit = membersData.pageSize
    param.timeTag = membersData.timeTag

    repo.getMemberRoles(param: param) { [weak self] error, memberRoles in
      print("error:\(error) memberArray:\(memberRoles)")
      if error != nil {
        completion(error, self?.membersData.roles)
      } else {
        // 移除占位
        if let last = self?.membersData.roles.last, last.isPlacehold {
          self?.membersData.roles.removeLast()
        }
        if let members = memberRoles, members.count > 0 {
          // 添加成员
          for member in members {
            var model = RoleModel()
            model.member = member
            self?.membersData.roles.append(model)
          }
          // 记录最后一个身份组的时间戳 用于下页请求
          self?.membersData.timeTag = self?.membersData.roles.last?.member?.createTime

          // 添加占位
          if members.count == self?.rolesData.pageSize {
            var placeholdModel = RoleModel()
            placeholdModel.title = localizable("more")
            placeholdModel.isPlacehold = true
            self?.membersData.roles.append(placeholdModel)
          }
          self?.setRoundedCorner()
          // 设置圆角
          completion(error, self?.membersData.roles)
        } else {
          // 设置圆角
          self?.setRoundedCorner()
          completion(error, self?.membersData.roles)
        }
      }
    }
  }

  public func removeChannelRole(role: ChannelRole?, index: Int,
                                _ completion: @escaping (NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(role?.serverId ?? 0)")
    var param = RemoveChannelRoleParam()
    param.serverId = role?.serverId
    param.roleId = UInt64(role?.roleId ?? 0)
    param.channelId = role?.channelId
    repo.removeChannelRole(param: param) { [weak self] anError in
      if anError == nil {
        self?.rolesData.roles.remove(at: index)
        completion(anError)
      }
      completion(anError)
    }
  }

  public func removeMemberRole(member: MemberRole?, index: Int,
                               _ completion: @escaping (NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(member?.serverId ?? 0)")
    let param = RemoveMemberRoleParam(
      serverId: channel?.serverId,
      channelId: channel?.channelId,
      accid: member?.accid
    )
    repo.removeMemberRole(param: param) { [weak self] anError in
      if anError == nil {
        self?.membersData.roles.remove(at: index)
      }
      completion(anError)
    }
  }

//    本地插入成员
  public func insertLocalMemberAtHead(member: MemberRole) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(member.serverId ?? 0)")
    let model = RoleModel(member: member, isPlacehold: false)
    membersData.roles.insert(model, at: 0)
    setRoundedCorner()
  }

//    本地插入身份组
  public func insertLocalRoleAtHead(role: ChannelRole) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(role.serverId ?? 0)")
    let model = RoleModel(role: role, isPlacehold: false)
    rolesData.roles.insert(model, at: 0)
    setRoundedCorner()
  }

  private func setRoundedCorner() {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    if rolesData.roles.count > 0 {
      if rolesData.roles.count == 1 {
        rolesData.roles[0].corner = .all
      } else {
        rolesData.roles[0].corner = .top
        rolesData.roles[rolesData.roles.count - 1].corner = .bottom
      }
    }
    if membersData.roles.count > 0 {
      if membersData.roles.count == 1 {
        membersData.roles[0].corner = .all
      } else {
        membersData.roles[0].corner = .top
        membersData.roles[membersData.roles.count - 1].corner = .bottom
      }
    }
  }
}
