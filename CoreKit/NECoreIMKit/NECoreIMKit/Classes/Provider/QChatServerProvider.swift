
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
import AVFoundation

public protocol QChatServerProviderDelegate: NSObjectProtocol {
  func callBack()
}

@objcMembers
public class QChatServerProvider: NSObject, NIMQChatServerManagerDelegate {
  public static let shared = QChatServerProvider()
  private let mutiDelegate = MultiDelegate<QChatServerProviderDelegate>(strongReferences: false)

  override init() {
    super.init()
    NIMSDK.shared().qchatServerManager.add(self)
  }

  // 创建服务器
  public func createServer(param: CreateServerParam,
                           _ completion: @escaping (NSError?, CreateServerResult?) -> Void) {
    NIMSDK.shared().qchatServerManager.createServer(param.toIMParam()) { error, serverResult in
      completion(error as NSError?, CreateServerResult(serverResult: serverResult))
    }
  }

  // 查询服务器信息
  public func getServers(param: QChatGetServersParam,
                         _ completion: @escaping (NSError?, QChatGetServersResult?) -> Void) {
    NIMSDK.shared().qchatServerManager
      .getServers(param.toIMParam()) { error, getServersResult in
        completion(error as NSError?, QChatGetServersResult(serversResult: getServersResult))
      }
  }

  // 查询服务器列表
  public func getServerCount(param: GetServersByPageParam,
                             _ completion: @escaping (NSError?, GetServersByPageResult?)
                               -> Void) {
    print("getServers param timeTag:\(param.timeTag) \n limit:\(param.limit)")
    NIMSDK.shared().qchatServerManager.getServersByPage(param.toIMParam()) { error, result in
      print("getServers error:\(error) \n result:\(result)")
      completion(error as NSError?, GetServersByPageResult(serversResult: result))
    }
  }

  // 申请加入服务器
  public func applyServerJoin(param: QChatApplyServerJoinParam,
                              _ completion: @escaping (NSError?) -> Void) {
    NIMSDK.shared().qchatServerManager.applyServerJoin(param.toIMParam()) { error, result in
      completion(error as NSError?)
    }
  }

  // 查询服务器内成员信息
  public func getServerMembers(param: QChatGetServerMembersParam,
                               _ completion: @escaping (NSError?, QChatGetServerMembersResult?)
                                 -> Void) {
    NIMSDK.shared().qchatServerManager.getServerMembers(param.toIMParam()) { error, result in
      completion(error as NSError?, QChatGetServerMembersResult(memberData: result))
    }
  }

  // 分页查询服务器成员信息
  public func getServerMembersByPage(param: QChatGetServerMembersByPageParam,
                                     _ completion: @escaping (NSError?,
                                                              QChatGetServerMembersResult?)
                                       -> Void) {
    NIMSDK.shared().qchatServerManager
      .getServerMembers(byPage: param.toIMParam()) { error, result in
        completion(error as NSError?, QChatGetServerMembersResult(membersResult: result))
      }
  }

  // 邀请服务器成员
  public func inviteMembersToServer(param: QChatInviteServerMembersParam,
                                    _ completion: @escaping (NSError?) -> Void) {
    NIMSDK.shared().qchatServerManager
      .inviteServerMembers(param.toImParam()) { error, inviteResult in
        completion(error as NSError?)
      }
  }

  public func updateServer(_ param: UpdateServerParam, _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().qchatServerManager.updateServer(param.toImParam()) { error, reuslt in
      completion(error)
    }
  }

  public func deleteServer(_ serverid: UInt64, _ completion: @escaping (Error?) -> Void) {
    let param = NIMQChatDeleteServerParam()
    param.serverId = serverid
    NIMSDK.shared().qchatServerManager.deleteServer(param) { error in
      completion(error)
    }
  }

  public func leaveServer(_ serverId: UInt64?, _ completion: @escaping (Error?) -> Void) {
    let param = NIMQChatLeaveServerParam()
    if let sid = serverId {
      param.serverId = sid
    }
    NIMSDK.shared().qchatServerManager.leaveServer(param) { error in
      completion(error)
    }
  }

  public func getServerMembers(_ param: GetServerMembersByPageParam,
                               _ completion: @escaping (Error?, [ServerMemeber]) -> Void) {
    NIMSDK.shared().qchatServerManager
      .getServerMembers(byPage: param.toImParam()) { error, result in
        var members = [ServerMemeber]()
        result?.memberArray?.forEach { imMember in
          let member = ServerMemeber(imMember)
          members.append(member)
        }
        completion(error, members)
      }
  }

  public func updateMyServerMember(_ param: UpdateMyMemberInfoParam,
                                   _ completion: @escaping (Error?, ServerMemeber) -> Void) {
    NIMSDK.shared().qchatServerManager.updateMyMemberInfo(param.toImParam()) { error, member in
      completion(error, ServerMemeber(member))
    }
  }

  public func updateServerMember(_ param: UpdateServerMemberInfoParam,
                                 _ completion: @escaping (Error?, ServerMemeber) -> Void) {
    NIMSDK.shared().qchatServerManager
      .updateServerMemberInfo(param.toImPara()) { error, member in
        completion(error, ServerMemeber(member))
      }
  }

  public func kickoutServerMembers(_ param: KickServerMembersParam,
                                   _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().qchatServerManager.kickServerMembers(param.toImParam()) { error in
      completion(error)
    }
  }

  // MARK: callback

  func callback() {
    mutiDelegate |> { delegate in
      delegate.callBack()
    }
  }

  public func addDelegate(delegate: QChatServerProviderDelegate) {
    mutiDelegate.addDelegate(delegate)
  }

  public func removeDelegate(delegate: QChatServerProviderDelegate) {
    mutiDelegate.removeDelegate(delegate)
  }

//    public func getServer(_ serverid: Int){
//        let parameter = NIMQChatGetServersParam()
//        parameter.serverIds = [serverid]
//
//        NIMSDK.shared().qchatServerManager.getServers(parameter) { error, result in
//
//        }
//    }
}
