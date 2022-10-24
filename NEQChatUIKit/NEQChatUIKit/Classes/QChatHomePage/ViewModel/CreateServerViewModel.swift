// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIMKit
import UIKit
import NEQChatKit
import NIMSDK
import NECoreKit
import SDWebImageWebPCoder
import SDWebImageSVGKitPlugin

@objcMembers
public class CreateServerViewModel: NSObject, QChatRepoMessageDelegate, AllChannelDataDelegate {
  typealias ServerListRefresh = () -> Void

  var dataDic = WeakDictionary<UInt64, QChatServer>()

  var channelUnreadCountDic = [UInt64: Int]()

  var requestFlag = [UInt64: AllChannelData]()

  var channelDataDic = [UInt64: [UInt64: UInt]]()

  let repo = QChatRepo()

  var currentServerId: UInt64?

  var delegate: ViewModelDelegate?

  var updateServerList: ServerListRefresh?

  private let className = "CreateServerViewModel"

  override public init() {
    super.init()
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    repo.delegate = self
    let webpCoder = SDImageWebPCoder()
    SDImageCodersManager.shared.addCoder(webpCoder)
    let svgCoder = SDImageSVGKCoder.shared
    SDImageCodersManager.shared.addCoder(svgCoder)
  }

  public func onUnReadChange(_ unreads: [NIMQChatUnreadInfo]?,
                             _ lastUnreads: [NIMQChatUnreadInfo]?) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", unreads.count:\(unreads?.count ?? 0)")
    print("onUnReadChange: ", unreads as Any)
    weak var weakSelf = self
    var set = Set<UInt64>()

    unreads?.forEach { unread in
      set.insert(unread.serverId)
      if weakSelf?.channelDataDic[unread.serverId] != nil {
        weakSelf?.channelDataDic[unread.serverId]?[unread.channelId] = unread.unreadCount
      } else {
        var channelDic = [UInt64: UInt]()
        channelDic[unread.channelId] = unread.unreadCount
        weakSelf?.channelDataDic[unread.serverId] = channelDic
      }
    }

    set.forEach { sid in
      let hasUnread = checkServerExistUnread(sid)
      print("hasUnread : ", hasUnread)
      let model = weakSelf?.dataDic[sid]
      print("server model : ", model?.name as Any)
      model?.hasUnread = hasUnread
      if let cSid = weakSelf?.currentServerId, cSid == sid {
        weakSelf?.delegate?.dataDidChange()
      }
    }

    if let block = updateServerList {
      block()
    }
  }

  func checkServerExistUnread(_ serverId: UInt64) -> Bool {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(serverId)")
    if let channelDic = channelDataDic[serverId] {
      for key in channelDic.keys {
        if let unreadCount = channelDic[key], unreadCount > 0 {
          return true
        }
      }
    }
    return false
  }

  public lazy var dataArray: [(String, String)] = {
    let array = [
      ("mine_create", localizable("qchat_mine_add")),
      ("addOther_icon", localizable("qchat_join_otherServer")),
    ]
    return array
  }()

  public func createServer(parameter: CreateServerParam,
                           _ completion: @escaping (NSError?, CreateServerResult?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", name:\(parameter.name ?? "nil")")
    QChatServerProvider.shared.createServer(param: parameter) { error, serverResult in
      completion(error, serverResult)
    }
  }

  public func getServers(parameter: QChatGetServersParam,
                         _ completion: @escaping (NSError?, QChatGetServersResult?) -> Void) {
    NELog.infoLog(
      ModuleName + " " + className,
      desc: #function + ", serverIds.count:\(parameter.serverIds?.count ?? 0)"
    )
    repo.getServers(parameter) { error, serverResult in
      completion(error, serverResult)
    }
  }

  public func getServerList(parameter: GetServersByPageParam,
                            _ completion: @escaping (NSError?, GetServersByPageResult?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    QChatServerProvider.shared.getServerCount(param: parameter) { error, result in
      completion(error, result)
    }
  }

  public func getServerMemberList(parameter: QChatGetServerMembersParam,
                                  _ completion: @escaping (NSError?,
                                                           QChatGetServerMembersResult?) -> Void) {
    NELog.infoLog(
      ModuleName + " " + className,
      desc: #function + ", serverAccIds.count:\(parameter.serverAccIds?.count ?? 0)"
    )
    QChatServerProvider.shared.getServerMembers(param: parameter) { error, result in
      completion(error, result)
    }
  }

  public func getServerMembersByPage(parameter: QChatGetServerMembersByPageParam,
                                     _ completion: @escaping (NSError?,
                                                              QChatGetServerMembersResult?)
                                       -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(parameter.serverId ?? 0)")
    QChatServerProvider.shared.getServerMembersByPage(param: parameter) { error, result in
      completion(error, result)
    }
//        repo.getServerMembersByPage(parameter, completion)
  }

  public func applyServerJoin(parameter: QChatApplyServerJoinParam,
                              _ completion: @escaping (NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(parameter.serverId)")
    QChatServerProvider.shared.applyServerJoin(param: parameter) { error in
      completion(error)
    }
  }

  public func inviteMembersToServer(serverId: UInt64, accids: [String],
                                    _ completion: @escaping (NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(serverId)")
    let param = QChatInviteServerMembersParam(serverId: serverId, accids: accids)
    repo.inviteMembersToServer(param) { error in
      completion(error)
    }
  }

  public func getUnread(_ servers: [QChatServer]) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", servers.count:\(servers.count)")
//    print("server model get unread servers : ", servers.count)

    if currentServerId == nil {
      currentServerId = servers.first?.serverId
    }
    weak var weakSelf = self
    servers.forEach { server in
      if let sid = server.serverId {
        weakSelf?.dataDic[sid] = server
      }
      weakSelf?.getAllChannel(server)
    }
  }

  func getAllChannel(_ server: QChatServer) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(server.serverId ?? 0)")
    if let sid = server.serverId, requestFlag[sid] == nil {
      let allChannelData = AllChannelData(sid: sid)
      allChannelData.delegate = self
      requestFlag[sid] = allChannelData
    }
  }

  func getChannelUnread(_ serverId: UInt64, _ channels: [ChatChannel]) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(serverId), channels.count:\(channels.count)")
//    print("getChannelUnread channel count : ", channels.count)
    var param = GetChannelUnreadInfosParam()
    var targets = [ChannelIdInfo]()

    channels.forEach { channel in
      var channelIdInfo = ChannelIdInfo()
      channelIdInfo.serverId = serverId
      channelIdInfo.channelId = channel.channelId
      targets.append(channelIdInfo)
    }
    param.targets = targets
//        weak var weakSelf = self
    repo.getChannelUnReadInfo(param) { error, infos in

      print("get channel unread info : ", error as Any)
      /*
       infos?.forEach({ info in
           if  weakSelf?.channelDataDic[info.serverId] != nil {
               weakSelf?.channelDataDic[info.serverId]?[info.channelId] = info.unreadCount
           }else {
               var channelDic = [UInt64: UInt]()
               channelDic[info.channelId] = info.unreadCount
               weakSelf?.channelDataDic[info.serverId] = channelDic
           }
       })
       if let last = infos?.last, let sid = weakSelf?.currentServerId {
           if last.serverId == sid {
               weakSelf?.delegate?.dataDidChange()
           }
       }
       if let server = weakSelf?.dataDic[serverId], let block = weakSelf?.updateServerList, let hasUnread =  weakSelf?.checkServerExistUnread(serverId){
           server.hasUnread = hasUnread
           block()
           if let cSid = weakSelf?.currentServerId, cSid == serverId {
               weakSelf?.delegate?.dataDidChange()
           }
       }*/
    }
  }

  func dataGetSuccess(_ serverId: UInt64, _ channels: [ChatChannel]) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(serverId)")
    print("get unread channel success : ", channels.count)
    requestFlag.removeValue(forKey: serverId)
    getChannelUnread(serverId, channels)
  }

  func dataGetError(_ serverId: UInt64, _ error: Error) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(serverId)")
    requestFlag.removeValue(forKey: serverId)
    print("get all channels error : ", error)
  }

  func getChannelUnreadCount(_ serverId: UInt64, _ channelId: UInt64) -> UInt {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(serverId)")
    if let channelDic = channelDataDic[serverId], let count = channelDic[channelId] {
      return count
    }
    return 0
  }
}
