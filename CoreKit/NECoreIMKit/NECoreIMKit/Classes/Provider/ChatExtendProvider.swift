
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objc public protocol ChatExtendProviderDelegate: NSObjectProtocol {
  @objc optional func onNotifySyncStickTopSessions(_ response: NIMSyncStickTopSessionResponse)
  @objc optional func onNotifyAddStickTopSession(_ newInfo: NIMStickTopSessionInfo)
  @objc optional func onNotifyRemoveStickTopSession(_ removedInfo: NIMStickTopSessionInfo)
  @objc optional func onNotifyAddMessagePin(pinItem: NIMMessagePinItem)
  @objc optional func onNotifyRemoveMessagePin(pinItem: NIMMessagePinItem)
}

@objcMembers
public class ChatExtendProvider: NSObject, NIMChatExtendManagerDelegate {
  public static let shared = ChatExtendProvider()
  private let mutiDelegate = MultiDelegate<ChatExtendProviderDelegate>(strongReferences: false)

  // 置顶信息保存
  public var stickTopInfos = [NIMSession: NIMStickTopSessionInfo]()
  override init() {
    super.init()
    NIMSDK.shared().chatExtendManager.add(self)
  }

  public func addDelegate(delegate: ChatExtendProviderDelegate) {
    mutiDelegate.addDelegate(delegate)
  }

  public func removeDelegate(delegate: ChatExtendProviderDelegate) {
    mutiDelegate.removeDelegate(delegate)
  }

  /// 根据置顶信息排序最近会话
  /// - Parameters:
  ///   - recentSessions: 需要排序的置顶会话
  ///   - stickTopInfos: [会话：置顶信息] 映射
  /// - Returns: 排序后的最近会话列表，若传如可变数组，则返回其数组本身
  public func sortRecentSessions(recentSessions: [NIMRecentSession],
                                 stickTopInfos: [NIMSession: NIMStickTopSessionInfo])
    -> [NIMRecentSession] {
    NIMSDK.shared().chatExtendManager
      .sortRecentSessions(recentSessions, withStickTopInfos: stickTopInfos)
  }

  /// 添加置顶
  /// - Parameters:
  ///   - params: 添加置顶的参数
  ///   - completion: 回调
  public func addStickTopSession(params: NIMAddStickTopSessionParams,
                                 _ completion: @escaping (NSError?, NIMStickTopSessionInfo?)
                                   -> Void) {
    NIMSDK.shared().chatExtendManager.addStickTopSession(params) { error, newInfo in
      completion(error as NSError?, newInfo)
    }
  }

  /// 删除置顶
  /// - Parameters:
  ///   - params: 删除置顶参数
  ///   - completion: 回调
  public func removeStickTopSession(params: NIMStickTopSessionInfo,
                                    _ completion: @escaping (NSError?, NIMStickTopSessionInfo?)
                                      -> Void) {
    NIMSDK.shared().chatExtendManager.removeStickTopSession(params) { error, removedInfo in
      completion(error as NSError?, removedInfo)
    }
  }

  /// 查找所有的置顶记录
  /// - Parameter completion: 完成回调
  public func loadStickTopSessionInfos(_ completion:
    @escaping (NSError?, [NIMSession: NIMStickTopSessionInfo]?)
      -> Void) {
    NIMSDK.shared().chatExtendManager.loadStickTopSessionInfos { error, stickTopInfo in
      completion(error as NSError?, stickTopInfo)
    }
  }

  /// 查询某个会话的置顶信息
  /// - Parameter session: 需要查询的会话
  /// - Returns: 置顶信息
  public func stickTopInfoForSession(session: NIMSession) -> NIMStickTopSessionInfo? {
    NIMSDK.shared().chatExtendManager.stickTopInfo(for: session)
  }

  /// 获取置顶信息
  /// - Returns: 返回置顶信息
  public func getStickTopInfos() -> [NIMSession: NIMStickTopSessionInfo]? {
    if stickTopInfos.count > 0 {
      return stickTopInfos
    }
    return nil
  }

  /// 根据sessionId，判断是否为置顶消息
  /// - Parameter sessionId: P2P为userId，team时为teamId
  /// - Returns: 是否是置顶会话
  public func isStickTopInfo(sessionId: String) -> Bool {
    for session in stickTopInfos.keys {
      if session.sessionId == sessionId {
        return true
      }
    }
    return false
  }

//    MARK: collection

  public func addCollection(_ info: NIMAddCollectParams,
                            _ completion: @escaping (NSError?, NIMCollectInfo?) -> Void) {
    NIMSDK.shared().chatExtendManager.addCollect(info) { error, info in
      completion(error as? NSError, info)
    }
  }

//    MARK: reply

  public func reply(_ message: NIMMessage, _ target: NIMMessage,
                    _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().chatExtendManager.reply(message, to: target, completion: completion)
  }

//    MARK: pin

  public func pin(_ pinItem: NIMMessagePinItem,
                  _ completion: @escaping (Error?, NIMMessagePinItem?) -> Void) {
    NIMSDK.shared().chatExtendManager.addMessagePin(pinItem, completion: completion)
  }

  public func removePin(_ pinItem: NIMMessagePinItem,
                        _ completion: @escaping (Error?, NIMMessagePinItem?) -> Void) {
    NIMSDK.shared().chatExtendManager.removeMessagePin(pinItem, completion: completion)
  }

  public func pinItem(_ message: NIMMessage) -> NIMMessagePinItem? {
    NIMSDK.shared().chatExtendManager.pinItem(for: message)
  }

  public func fetchHistoryMessages(_ infos: [NIMChatExtendBasicInfo], _ syncToDB: Bool, _ completion: @escaping (Error?, NSMapTable<NIMChatExtendBasicInfo, NIMMessage>?) -> Void) {
    NIMSDK.shared().chatExtendManager.fetchHistoryMessages(infos, syncToDB: syncToDB) { error, table in
      completion(error, table)
    }
  }

  // MARK: ==================NIMChatExtendManagerDelegate===================

  public func onNotifySyncStickTopSessions(_ response: NIMSyncStickTopSessionResponse) {
    weak var weakSelf = self
    if response.hasChange {
      stickTopInfos.removeAll()
      response.allInfos.forEach { stickTopSessionInfo in
        stickTopInfos[stickTopSessionInfo.session] = stickTopSessionInfo
      }
    } else {
      loadStickTopSessionInfos { _, stickTopInfos in
        if let infos = stickTopInfos {
          weakSelf?.stickTopInfos = infos
        }
      }
    }
    mutiDelegate |> { delegate in
      delegate.onNotifySyncStickTopSessions?(response)
    }
  }

  public func getTopSessionInfo(_ session: NIMSession) -> NIMStickTopSessionInfo {
    NIMSDK.shared().chatExtendManager.stickTopInfo(for: session)
  }

  /// 根据 session 获取 pin 消息列表
  /// - Parameters:
  ///   - session: 会话 session
  ///   - completion:  完成回调
  public func fetchPinMessage(_ session: NIMSession, _ completion: @escaping (Error?, [NIMMessagePinItem]?) -> Void) {
    NIMSDK.shared().chatExtendManager.loadMessagePins(for: session) { error, pinImtes in
      completion(error, pinImtes)
    }
  }

  public func onNotifyAddStickTopSession(_ newInfo: NIMStickTopSessionInfo) {
    mutiDelegate |> { delegate in
      delegate.onNotifyAddStickTopSession?(newInfo)
    }
  }

  public func onNotifyRemoveStickTopSession(_ removedInfo: NIMStickTopSessionInfo) {
    mutiDelegate |> { delegate in
      delegate.onNotifyRemoveStickTopSession?(removedInfo)
    }
  }

  public func onNotifyAddMessagePin(_ item: NIMMessagePinItem) {
    mutiDelegate |> { delegate in
      delegate.onNotifyAddMessagePin?(pinItem: item)
    }
  }

  public func onNotifyUpdateMessagePin(_ item: NIMMessagePinItem) {
    print(#function)
  }

  public func onNotifyRemoveMessagePin(_ item: NIMMessagePinItem) {
    mutiDelegate |> { delegate in
      delegate.onNotifyRemoveMessagePin?(pinItem: item)
    }
    print(#function)
  }
}
