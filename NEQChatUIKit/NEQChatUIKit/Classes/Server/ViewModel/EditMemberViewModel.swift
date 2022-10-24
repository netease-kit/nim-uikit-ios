// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIMKit
import NEQChatKit

@objcMembers
public class EditMemberViewModel: NSObject {
  var limitIdGroups = [IdGroupModel]()
  var allIdGroups = [IdGroupModel]()

  var serverRoles = [ServerRole]()
  var userRoles = [ServerRole]()

  var userDic = [UInt64: IdGroupModel]()
  var serverDic = [UInt64: IdGroupModel]()

  var delegate: ViewModelDelegate?

  let repo = QChatRepo()

  var limit = 5

  private let className = "EditMemberViewModel"

  override init() {}

  func checkoutCurrentUserRole(_ roleId: UInt64?) -> Bool {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", roleId:\(roleId ?? 0)")
    if let rid = roleId {
      if userDic[rid] != nil {
        return true
      }
    }
    return false
  }

  func showServerData() {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    limitIdGroups.removeAll()
    allIdGroups.removeAll()
    serverRoles.forEach { role in
      if let roleId = role.roleId {
        if let model = self.serverDic[roleId] {
          self.allIdGroups.append(model)
        }
      }
    }
    allIdGroups.first?.cornerType = .topLeft.union(.topRight)
    if allIdGroups.count > limit {
      limitIdGroups.append(contentsOf: allIdGroups.prefix(limit))
    } else {
      limitIdGroups.append(contentsOf: allIdGroups)
      if let last = limitIdGroups.last {
        last.cornerType = last.cornerType.union(.bottomLeft).union(.bottomRight)
      }
    }
    delegate?.dataDidChange()
  }

  func filterAllRoles() {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    let serverModels = getRoleModel(serverRoles, nil)
    serverModels.forEach { idModel in
      if let roleId = idModel.role?.roleId {
        self.serverDic[roleId] = idModel
      }
    }
  }

  func filterUserRoles() {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    allIdGroups.append(contentsOf: getRoleModel(userRoles, true))
    allIdGroups.first?.cornerType = .topLeft.union(.topRight)
    if allIdGroups.count > limit {
      limitIdGroups.append(contentsOf: allIdGroups.prefix(limit))
    } else {
      limitIdGroups.append(contentsOf: allIdGroups)
      if let last = limitIdGroups.last {
        last.cornerType = last.cornerType.union(.bottomLeft).union(.bottomRight)
      }
    }
    allIdGroups.forEach { idModel in
      if let roleId = idModel.role?.roleId {
        self.userDic[roleId] = idModel
      }
    }
    delegate?.dataDidChange()
  }

  func getData(_ serverId: UInt64?, _ accid: String?) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(serverId ?? 0)")
    weak var weakSelf = self

    var accidParam = GetServerRolesByAccIdParam(serverId: serverId, accid: accid)
    accidParam.limit = 200
    accidParam.timeTag = 0
    repo.getServerRolesByAccId(param: accidParam) { error, roles in
      if let err = error {
        weakSelf?.delegate?.dataDidError(err)
      } else {
        print("edit member member role : ", roles as Any)
        if let datas = roles {
          weakSelf?.userRoles.append(contentsOf: datas)
          weakSelf?.delegate?.dataDidChange()
          weakSelf?.filterUserRoles()
        }
      }
    }

    var param = GetServerRoleParam()
    param.limit = 200
    param.serverId = serverId

    repo.getRoles(param) { error, roles, sets in
      if let err = error {
        weakSelf?.delegate?.dataDidError(err)
      } else {
        print("edit member server roles : ", roles as Any)
        if let datas = roles {
          weakSelf?.serverRoles.append(contentsOf: datas)
          weakSelf?.filterAllRoles()
        }
      }
    }
  }

  func getRoleModel(_ roles: [ServerRole]?, _ select: Bool?) -> [IdGroupModel] {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", roles.count:\(roles?.count ?? 0)")
    var models = [IdGroupModel]()
    roles?.forEach { role in
      let model = IdGroupModel(role)
      if let s = select {
        model.isSelect = s
      }
      models.append(model)
    }
    return models
  }

  func updateMyMember(_ serverId: UInt64?, _ nick: String?,
                      _ completion: @escaping (Error?, ServerMemeber) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(serverId ?? 0)")
    var param = UpdateMyMemberInfoParam()
    param.serverId = serverId
    param.nick = nick
    repo.updateMyServerMember(param, completion)
  }

  func updateMember(_ serverId: UInt64?, _ nick: String?, _ accid: String?,
                    _ completion: @escaping (Error?, ServerMemeber) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(serverId ?? 0)")
    var param = UpdateServerMemberInfoParam()
    param.serverId = serverId
    param.nick = nick
    param.accid = accid
    repo.updateServerMember(param, completion)
  }

  func kickoutMember(_ serverId: UInt64?, _ accid: String?,
                     _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(serverId ?? 0)")
    var param = KickServerMembersParam()
    param.serverId = serverId
    var accids = [String]()
    if let acc = accid {
      accids.append(acc)
      param.accounts = accids
    }
    repo.kickoutServerMembers(param) { error in
      completion(error)
    }
  }

  func addMembers(_ accid: String?, _ serverId: UInt64?, _ roleId: UInt64?,
                  _ completion: @escaping () -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", accid:\(accid ?? "nil")")
    var param = AddServerRoleMemberParam()
    param.serverId = serverId
    param.roleId = roleId
    var accids = [String]()
    if let aid = accid {
      accids.append(aid)
    }
    param.accountArray = accids
    weak var weakSelf = self

    repo.addRoleMember(param) { error, successAccids, failedAccids in
      print("add role member result : ", error as Any)
      completion()
      if let err = error {
        weakSelf?.delegate?.dataDidError(err)
      } else {
        print("add members success accids : ", successAccids)

        if let rid = roleId, let model = weakSelf?.serverDic[rid] {
          weakSelf?.userDic[rid] = model
        }
        weakSelf?.delegate?.dataDidChange()
      }
    }
  }

  func remove(_ accid: String?, _ serverId: UInt64?, _ rid: UInt64?,
              _ completion: @escaping () -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", accid:\(accid ?? "nil")")
    var param = RemoveServerRoleMemberParam()
    param.serverId = serverId
    param.roleId = rid
    weak var weakSelf = self
    if let accid = accid {
      param.accountArray = [accid]
      repo.deleateRoleMember(param) { error, successAccids, failedAccids in
        if let err = error {
          weakSelf?.delegate?.dataDidError(err)
        } else {
          if let roleId = rid {
            print("add role id : ", roleId)
            weakSelf?.userDic.removeValue(forKey: roleId)
          }
          weakSelf?.delegate?.dataDidChange()
        }
        completion()
      }
    } else {
      completion()
    }
  }
}
