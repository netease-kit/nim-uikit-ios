
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
import CoreMedia

public protocol QChatChannelProviderDelegate: NSObjectProtocol {
  func callBack()
}

@objcMembers
public class QChatChannelProvider: NSObject, NIMQChatChannelManagerDelegate {
  public static let shared = QChatChannelProvider()
  private let mutiDelegate = MultiDelegate<QChatChannelProviderDelegate>(strongReferences: false)

  override init() {
    super.init()
    NIMSDK.shared().qchatChannelManager.add(self)
  }

  public func createChannel(param: CreatChannelParam,
                            _ completion: @escaping (NSError?, ChatChannel?) -> Void) {
    print(#function + "param:\(param.toIMParam())")
    NIMSDK.shared().qchatChannelManager.createChannel(param.toIMParam()) { error, chatChannel in
      print("file:" + #file + "function:" + #function +
        "error:\(error?.localizedDescription ?? "")" +
        "chatChannel:\(chatChannel?.channelId ?? 0)")
      completion(error as NSError?, ChatChannel(channel: chatChannel))
    }
  }

  public func updateChannelInfo(param: UpdateChannelParam,
                                _ completion: @escaping (NSError?, ChatChannel?) -> Void) {
    NIMSDK.shared().qchatChannelManager.updateChannel(param.toIMParam()) { error, chatChannel in
      print("file:" + #file + "function:" + #function +
        "error:\(error?.localizedDescription ?? "")" +
        "chatChannel:\(chatChannel?.channelId ?? 0)")
      completion(error as NSError?, ChatChannel(channel: chatChannel))
    }
  }

  public func deleteChannel(channelId: UInt64?, _ completion: @escaping (NSError?) -> Void) {
    let param = NIMQChatDeleteChannelParam()
    param.channelId = channelId ?? 0
    NIMSDK.shared().qchatChannelManager.deleteChannel(param) { error in
      completion(error as NSError?)
    }
  }

  // 查询频道成员信息
  public func getChannelMembers(param: ChannelMembersParam,
                                _ completion: @escaping (NSError?, ChannelMembersResult?)
                                  -> Void) {
    NIMSDK.shared().qchatChannelManager
      .getChannelMembers(byPage: param.toIMParam()) { error, result in
        completion(error as NSError?, ChannelMembersResult(memberResult: result))
      }
  }

  public func getBlackWhiteMembersByPage(param: GetChannelBlackWhiteMembers,
                                         _ completion: @escaping (NSError?,
                                                                  ChannelMembersResult?) -> Void) {
    NIMSDK.shared().qchatChannelManager
      .getBlackWhiteMembers(byPage: param.toIMParam()) { error, result in
        print("error\(error) blackmemberArray:\(result?.memberArray)")
        completion(error as NSError?, ChannelMembersResult(whiteMemberResult: result))
      }
  }

  // 频道添加、删除黑白名单
  public func updateBlackWhiteMembers(param: UpdateChannelBlackWhiteMembersParam,
                                      _ completion: @escaping (NSError?) -> Void) {
    NIMSDK.shared().qchatChannelManager.updateBlackWhiteMembers(param.toIMParam()) { error in
      completion(error as NSError?)
    }
  }

  // 批量查询频道黑白名单成员列表
  public func getExistingChannelBlackWhiteMembers(param: GetExistingChannelBlackWhiteMembersParam,
                                                  _ completion: @escaping (NSError?,
                                                                           BlackWhiteMembersResult?)
                                                    -> Void) {
    print(#function + "param:\(param)")
    NIMSDK.shared().qchatChannelManager
      .getExistingChannelBlackWhiteMembers(param.toIMParam()) { error, result in
        print(#function + "error:\(param) result:\(result)")
        completion(error as NSError?, BlackWhiteMembersResult(result: result))
      }
  }

  // 分页查询圈组频道信息
  public func getChannelsByPage(param: QChatGetChannelsByPageParam,
                                _ completion: @escaping (NSError?, QChatGetChannelsByPageResult?)
                                  -> Void) {
    NIMSDK.shared().qchatChannelManager
      .getChannelsByPage(param.toIMParam()) { error, channelsResult in
        completion(
          error as NSError?,
          QChatGetChannelsByPageResult(channelsResult: channelsResult)
        )
      }
  }

  public func getChannelUnReadInfo(_ param: GetChannelUnreadInfosParam,
                                   _ completion: @escaping (Error?, [NIMQChatUnreadInfo]?)
                                     -> Void) {
    NIMSDK.shared().qchatChannelManager
      .getChannelUnreadInfos(param.toImParam()) { error, result in
        completion(error, result?.unreadInfo)
      }
  }

  // MARK: callback

  func callback() {
    mutiDelegate |> { delegate in
      delegate.callBack()
    }
  }
}
