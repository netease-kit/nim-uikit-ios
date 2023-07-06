
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
import UIKit
import AVFoundation
public protocol QChatRoleProviderDelegate: NSObjectProtocol {}

@objcMembers
public class QChatRoleProvider: NSObject {
  public static let shared = QChatRoleProvider()
  private let mutiDelegate = MultiDelegate<QChatRoleProviderDelegate>(strongReferences: false)

  public func createRole(_ param: ServerRoleParam,
                         _ completion: @escaping (Error?, ServerRole) -> Void) {
    let roleParam = param.toIMParam()
    NIMSDK.shared().qchatRoleManager.createServerRole(roleParam) { error, role in
      completion(error, ServerRole(role))
    }
  }

  //    获取服务器身份组
  public func getRoles(_ param: GetServerRoleParam,
                       _ completion: @escaping (Error?, [ServerRole]?, Set<NSNumber>?) -> Void) {
    NIMSDK.shared().qchatRoleManager.getServerRoles(param.toImParam()) { error, result in
      var roles = [ServerRole]()
      result?.serverRoleArray.forEach { role in
        let sRole = ServerRole(role)
        roles.append(sRole)
      }
      completion(error, roles, result?.isMemberSet)
    }
  }

  public func updateServerRolePriorities(_ param: UpdateServerRolePrioritiesParam,
                                         _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().qchatRoleManager
      .updateServerRolePriorities(param.toImParam()) { error, result in
        completion(error)
      }
  }

  public func deleteRoles(_ param: DeleteServerRoleParam,
                          _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().qchatRoleManager.deleteServerRole(param.toIMParam()) { error in
      completion(error)
    }
  }

  public func updateRole(_ param: UpdateServerRoleParam,
                         _ completion: @escaping (Error?, ServerRole) -> Void) {
    let imParam = param.toImParam()
    print("update role : ", imParam.commands)
    NIMSDK.shared().qchatRoleManager.updateServerRole(imParam) { error, role in
      let serverRole = ServerRole(role)
      completion(error, serverRole)
    }
  }

  public func getServerRoleMembers(_ param: GetServerRoleMembersParam,
                                   _ completion: @escaping (Error?, [RoleMember]) -> Void) {
    NIMSDK.shared().qchatRoleManager.getServerRoleMembers(param.toImParam()) { error, result in
      var members = [RoleMember]()
      result?.memberArray.forEach { member in
        members.append(RoleMember(member))
      }
      completion(error, members)
    }
  }

  public func addRoleMember(_ param: AddServerRoleMemberParam,
                            _ completion: @escaping (Error?, [String], [String]) -> Void) {
    NIMSDK.shared().qchatRoleManager.addServerRoleMembers(param.toImParam()) { error, result in
      var successAccids = [String]()
      var failedAccids = [String]()
      if let err = error {
        completion(err, successAccids, failedAccids)
      } else {
        if let sAccids = result?.successfulAccidArray {
          sAccids.forEach { value in
            successAccids.append(value)
          }
        }
        if let fAccids = result?.failedAccidArray {
          fAccids.forEach { value in
            failedAccids.append(value)
          }
        }
        completion(error, successAccids, failedAccids)
      }
    }
  }

  public func deleateRoleMember(_ param: RemoveServerRoleMemberParam,
                                _ completion: @escaping (Error?, [String], [String]) -> Void) {
    NIMSDK.shared().qchatRoleManager
      .removeServerRoleMember(param.toImParam()) { error, result in
        var success = [String]()
        var faileds = [String]()
        result?.successfulAccidArray.forEach { accid in
          success.append(accid)
        }
        result?.failedAccidArray.forEach { accid in
          faileds.append(accid)
        }
        completion(error, success, faileds)
      }
  }

  // 添加身份组到某个频道下
  public func addChannelRole(param: AddChannelRoleParam,
                             _ completion: @escaping (NSError?, ChannelRole?) -> Void) {
    NIMSDK.shared().qchatRoleManager.addChannelRole(param.toImParam()) { error, cRole in
      if error != nil {
        completion(error as NSError?, nil)
      } else {
        completion(error as NSError?, ChannelRole(role: cRole))
      }
    }
  }

  // 移除某个频道下的身份组
  public func removeChannelRole(param: RemoveChannelRoleParam,
                                _ completion: @escaping (NSError?) -> Void) {
    NIMSDK.shared().qchatRoleManager.removeChannelRole(param.toImParam()) { error in
      completion(error as NSError?)
    }
  }

  // 查询频道下身份组列表
  public func getChannelRoles(param: ChannelRoleParam,
                              _ completion: @escaping (NSError?, [ChannelRole]?) -> Void) {
    NIMSDK.shared().qchatRoleManager.getChannelRoles(param.toIMParam()) { error, result in
      guard let roleArray = result?.channelRoleArray else {
        completion(error as NSError?, nil)
        return
      }
      var array = [ChannelRole]()
      for role in roleArray {
        array.append(ChannelRole(role: role))
      }
      completion(error as NSError?, array)
    }
  }

  // 查询身份组是否已经添加到频道中，返回已经添加的身份组列表
  public func getExistingChannelRoles(param: GetExistingChannelRolesByServerRoleIdsParam,
                                      _ completion: @escaping (NSError?, [ChannelRole]?)
                                        -> Void) {
    NIMSDK.shared().qchatRoleManager
      .getExistingChannelRoles(byServerRoleIds: param.toIMParam()) { error, result in
        guard let roleArray = result?.channelRoleArray else {
          completion(error as NSError?, nil)
          return
        }
        var array = [ChannelRole]()
        for role in roleArray {
          array.append(ChannelRole(role: role))
        }
        completion(error as NSError?, array)
      }
  }

  // 查询频道下成员的权限
  public func getMemberRoles(param: GetMemberRolesParam,
                             _ completion: @escaping (NSError?, [MemberRole]?) -> Void) {
    NIMSDK.shared().qchatRoleManager.getMemberRoles(param.toImParam()) { error, result in
      guard let roleArray = result?.memberRoleArray else {
        completion(error as NSError?, nil)
        return
      }
      var array = [MemberRole]()
      for member in roleArray {
        array.append(MemberRole(member: member))
      }
      completion(error as NSError?, array)
    }
  }

  // 设置频道下身份组权限
  public func updateChannelRole(param: UpdateChannelRoleParam,
                                _ completion: @escaping (NSError?, ChannelRole?) -> Void) {
    NIMSDK.shared().qchatRoleManager
      .updateChannelRole(param.toIMParam()) { error, channelRole in
        completion(error as NSError?, ChannelRole(role: channelRole))
      }
  }

  // 通过accid查询自定义身份组列表
  public func getServerRolesByAccId(param: GetServerRolesByAccIdParam,
                                    _ completion: @escaping (Error?, [ServerRole]?) -> Void) {
    let imParam = param.toIMParam()
    print("im param : ", imParam)
    NIMSDK.shared().qchatRoleManager.getServerRoles(byAccid: imParam) { error, result in
      var roles = [ServerRole]()
      result?.serverRoles.forEach { role in
        roles.append(ServerRole(role))
      }
      completion(error, roles)
    }
  }

  // 查询一批accids的自定义身份组列表
  public func getExistingServerRolesByAccids(param: QChatGetExistingAccidsInServerRoleParam,
                                             _ completion: @escaping (NSError?,
                                                                      [String: [ServerRole]]?)
                                               -> Void) {
    NIMSDK.shared().qchatRoleManager
      .getExistingAccids(inServerRole: param.toImParam()) { error, result in
        var serverRoles = [String: [ServerRole]]()
        result?.accidServerRolesDic?.forEach { key, serverRole in

          var memberRoleArray = [ServerRole]()
          serverRole.forEach { role in
            memberRoleArray.append(ServerRole(role))
          }
          serverRoles[key] = memberRoleArray
        }
        completion(error as NSError?, serverRoles)
      }
  }

  // 添加成员到频道
  public func addMemberRole(_ param: AddMemberRoleParam,
                            _ completion: @escaping (NSError?, MemberRole?) -> Void) {
    NIMSDK.shared().qchatRoleManager.addMemberRole(param.toIMParam()) { error, memberRole in
      if let m = memberRole {
        completion(error as NSError?, MemberRole(member: m))
      } else {
        completion(error as NSError?, nil)
      }
    }
  }

  // 移除某个频道下的成员
  public func removeMemberRole(param: RemoveMemberRoleParam,
                               _ completion: @escaping (NSError?) -> Void) {
    NIMSDK.shared().qchatRoleManager.removeMemberRole(param.toIMParam()) { error in
      completion(error as NSError?)
    }
  }

  // 设置某个频道下的成员的权限
  public func updateMemberRole(param: UpdateMemberRoleParam,
                               _ completion: @escaping (NSError?, MemberRole?) -> Void) {
    NIMSDK.shared().qchatRoleManager.updateMemberRole(param.toIMParam()) { error, memberRole in
      completion(error as NSError?, MemberRole(member: memberRole))
    }
  }

  //    查询成员是否已经添加到频道中，返回已经添加的成员列表
  public func getExistingMemberRoles(param: GetExistingAccidsOfMemberRolesParam,
                                     _ completion: @escaping (NSError?, [MemberRole]?) -> Void) {
    print(#function + "⬆️accid:\(param.accids)")
    NIMSDK.shared().qchatRoleManager
      .getExistingAccids(ofMemberRoles: param.toIMParam()) { error, result in
        guard let memberRoles = result?.accidArray else {
          completion(error as NSError?, nil)
          return
        }
        var array = [MemberRole]()
        for memberRole in memberRoles {
          array.append(MemberRole(aid: memberRole))
        }
        print(#function + "⬇️array:\(array)")
        completion(error as NSError?, array)
      }
  }

  public func getExistingServerRoleMembersByAccids(_ param: GetExistingServerRoleMembersByAccidsParam,
                                                   _ completion: @escaping (Error?, [String])
                                                     -> Void) {
    NIMSDK.shared().qchatRoleManager
      .getExistingServerRoleMembers(byAccids: param.toImParam()) { error, result in
        var accids = [String]()
        result?.accidArray.forEach { member in
          accids.append(member)
        }
        completion(error, accids)
      }
  }

  public func addDelegate(delegate: QChatRoleProviderDelegate) {
    mutiDelegate.addDelegate(delegate)
  }

  public func removeDelegate(delegate: QChatRoleProviderDelegate) {
    mutiDelegate.removeDelegate(delegate)
  }
}
