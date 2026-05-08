
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import NECoreIM2Kit
import NIMSDK

@objc
public protocol NELocalConversationListener: NSObjectProtocol {
  /// 会话同步开始
  @objc optional func onLocalConversationSyncStarted()

  /// 会话同步完成
  @objc optional func onLocalConversationSyncFinished()

  /// 会话同步失败
  /// - Parameter error: 失败信息
  @objc optional func onLocalConversationSyncFailed(_ error: V2NIMError)

  /// 会话创建回调
  /// - Parameter conversation: 会话
  @objc optional func onLocalConversationCreated(_ conversation: V2NIMLocalConversation)

  /// 会话删除回调
  /// - Parameter conversationIds: 会话id列表
  @objc optional func onLocalConversationDeleted(_ conversationIds: [String])

  /// 会话变更回调
  /// - Parameter conversations: 会话列表
  @objc optional func onLocalConversationChanged(_ conversations: [V2NIMLocalConversation])

  /// 总未读数变更回调
  /// - Parameter unreadCount: 未读数
  @objc optional func onLocalTotalUnreadCountChanged(_ unreadCount: Int)

  /// 注册了 subscribeUnreadCountByFilter 监听后，会抛出该回调
  /// 根据不同Filter，回调对应的内容
  /// - Parameters:
  ///   - filter: 订阅注册的相关Filter
  ///   - unreadCount: 对应Fliter过滤条件得出的未读数
  @objc optional func onLocalUnreadCountChangedByFilter(_ filter: V2NIMLocalConversationFilter, _ unreadCount: Int)

  /// 账号多端登录会话已读时间戳标记通知
  /// 账号A登录设备D1, D2,  D1会话已读时间戳标记，同步到D2成员
  /// - Parameters:
  ///   - conversationId: 同步标记的会话ID
  ///   - readTime: 标记的时间戳
  @objc optional func onLocalConversationReadTimeUpdated(_ conversationId: String, _ readTime: TimeInterval)
}

@objcMembers
public class LocalConversationRepo: NSObject, V2NIMLocalConversationListener {
  public static let shared = LocalConversationRepo()

  private let localConversationMultiDelegate = MultiDelegate<NELocalConversationListener>(strongReferences: false)

  /// V2  会话 Provider
  public let localConversationProvider = LocalConversationProvider.shared

  /// V2 User Provider
  public let userProvider = UserProvider.shared

  /// V2 Team Provider
  public let teamProvider = TeamProvider.shared

  /// V2 Chat Provider
  public let chatProvider = ChatProvider.shared

  /// V2 Friend Provider
  public let friendProvider = FriendProvider.shared

  override private init() {
    super.init()
    localConversationProvider.addListener(self)
  }

  /// 添加回到监听
  /// - Parameter listener: 实现监听协议的对象
  open func addLocalConversationListener(_ listener: NELocalConversationListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    localConversationMultiDelegate.addDelegate(listener)
  }

  /// 移除监听
  /// - Parameter listener: 实现监听协议的对象
  open func removeLocalConversationListener(_ listener: NELocalConversationListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    localConversationMultiDelegate.removeDelegate(listener)
  }

  /// 删除一个会话
  /// - Parameter conversationId: 会话id
  /// - Parameter clearMessage: 是否清空消息，默认不清空
  /// - Parameter completion: 完成回调
  open func deleteConversation(_ conversationId: String,
                               _ clearMessage: Bool = false,
                               _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " conversation id : \(conversationId)")
    localConversationProvider.deleteConversation(conversationId, clearMessage, completion)
  }

  /// 创建一个会话
  /// - Parameter conversationId: 会话id
  /// - Parameter completion: 完成回调
  open func createConversation(_ conversationId: String, _ completion: @escaping (V2NIMLocalConversation?, NSError?) -> Void) {
    localConversationProvider.createConversation(conversationId, completion)
  }

  /// 获取一个会话
  /// - Parameter conversationId: 会话id
  /// - Parameter completion: 完成回调
  open func getConversation(_ conversationId: String,
                            _ completion: @escaping (V2NIMLocalConversation?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " conversation id : \(conversationId)")
    localConversationProvider.getConversation(conversationId, completion)
  }

  /// 根据 id 批量获取会话
  /// - Parameter conversationIds: 会话id数组
  /// - Parameter completion: 完成回调
  open func getConversationListByIds(_ conversationIds: [String],
                                     _ completion: @escaping ([V2NIMLocalConversation]?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    localConversationProvider.getConversationListByIds(conversationIds, completion)
  }

  /// 分页获取会话列表
  /// - Parameter offset: 偏移量
  /// - Parameter limit: 限制数量
  /// - Parameter completion: 完成回调
  open func getConversationList(_ offset: Int, _ limit: Int, _ completion: @escaping ([V2NIMLocalConversation]?, Int?, Bool?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " offset: \(offset)  limit: \(limit)")
    localConversationProvider.getConversationList(offset, limit) { result, error in
      print(#function + " " + "getConversationList result offset : \(result?.offset ?? 0) finished : \(result?.finished ?? false) error : \(error?.localizedDescription ?? "")")

      completion(result?.conversationList, result?.offset, result?.finished, error)
    }
  }

  /// 设置会话置顶
  ///   - Parameter conversationId: 需要添加置顶的会话id
  ///   - Parameter stickTop: 是否置顶
  ///   - Parameter completion:   完成回调
  open func setStickTop(_ conversationId: String,
                        _ stickTop: Bool,
                        _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " conversation id : \(conversationId)")
    localConversationProvider.stickTopConversation(conversationId, stickTop, completion)
  }

  /// 获取所有未读数
  /// - Returns: 返回未读数
  open func getTotalUnreadCount() -> NSInteger {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    return localConversationProvider.getTotalUnreadCount()
  }

  /// 清空所有未读数
  open func clearTotalUnreadCount() {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)

    localConversationProvider.clearTotalUnreadCount { [weak self] error in
      if let err = error {
        NEALog.infoLog(ModuleName + " " + LocalConversationRepo.className(), desc: #function + " \(err.localizedDescription)")
      }
    }
  }

  /// 标记会话已读时间戳
  /// - Parameter conversationId: 会话id
  /// - Parameter completion: 完成回调
  open func markConversationRead(_ conversationId: String, _ completion: @escaping (TimeInterval?, NSError?) -> Void) {
    localConversationProvider.markConversationRead(conversationId, completion)
  }

  /// 获取会话已读时间戳
  /// - Parameter conversationId: 会话id
  /// - Parameter completion: 完成回调
  open func getConversationReadTime(_ conversationId: String, _ completion: @escaping (TimeInterval?, NSError?) -> Void) {
    localConversationProvider.getConversationReadTime(conversationId, completion)
  }

  /// 根据会话ID列表清空相应本地会话的未读数
  /// 每次限制最多10条
  /// 调用该方法后，SDK可能触发onTotalUnreadCountChanged、onUnreadCountChangedByFilter
  /// - Parameter conversationIds: 会话ID, 拼接方式： myAccountID|conversationType|targetId；不能为空，为空直接返回参数错误；每次最多10条
  /// - Parameter completion: 完成回调
  open func clearUnreadCountByIds(_ conversationIds: [String], _ completion: @escaping ([V2NIMLocalConversationOperationResult]?, NSError?) -> Void) {
    localConversationProvider.clearUnreadCountByIds(conversationIds, completion)
  }

  /// 会话同步开始
  open func onSyncStarted() {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    localConversationMultiDelegate |> { delegate in
      delegate.onLocalConversationSyncStarted?()
    }
  }

  /// 会话同步完成
  open func onSyncFinished() {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    localConversationMultiDelegate |> { delegate in
      delegate.onLocalConversationSyncFinished?()
    }
  }

  /// 会话同步失败
  /// - Parameter error: 失败信息
  open func onSyncFailed(_ error: V2NIMError) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    localConversationMultiDelegate |> { delegate in
      delegate.onLocalConversationSyncFailed?(error)
    }
  }

  /// 会话创建回调
  /// - Parameter conversation: 会话
  public func onConversationCreated(_ conversation: V2NIMLocalConversation) {
    localConversationMultiDelegate |> { delegate in
      delegate.onLocalConversationCreated?(conversation)
    }
  }

  /// 会话删除回调
  /// - Parameter conversationIds: 会话id列表
  open func onConversationDeleted(_ conversationIds: [String]) {
    localConversationMultiDelegate |> { delegate in
      delegate.onLocalConversationDeleted?(conversationIds)
    }
  }

  /// 会话变更回调
  /// - Parameter conversations: 会话列表
  open func onConversationChanged(_ conversations: [V2NIMLocalConversation]) {
    localConversationMultiDelegate |> { delegate in
      delegate.onLocalConversationChanged?(conversations)
    }
  }

  /// 总未读数变更回调
  /// - Parameter unreadCount: 未读数
  open func onTotalUnreadCountChanged(_ unreadCount: Int) {
    localConversationMultiDelegate |> { delegate in
      delegate.onLocalTotalUnreadCountChanged?(unreadCount)
    }
  }

  /// 注册了 subscribeUnreadCountByFilter 监听后，会抛出该回调
  /// 根据不同Filter，回调对应的内容
  /// - Parameters:
  ///   - filter: 订阅注册的相关Filter
  ///   - unreadCount: 对应Fliter过滤条件得出的未读数
  public func onUnreadCountChanged(by filter: V2NIMLocalConversationFilter, unreadCount: Int) {
    localConversationMultiDelegate |> { delegate in
      delegate.onLocalUnreadCountChangedByFilter?(filter, unreadCount)
    }
  }

  /// 账号多端登录会话已读时间戳标记通知
  /// 账号A登录设备D1, D2,  D1会话已读时间戳标记，同步到D2成员
  /// - Parameters:
  ///   - conversationId: 同步标记的会话ID
  ///   - readTime: 标记的时间戳
  public func onConversationReadTimeUpdated(_ conversationId: String, readTime: TimeInterval) {
    localConversationMultiDelegate |> { delegate in
      delegate.onLocalConversationReadTimeUpdated?(conversationId, readTime)
    }
  }
}
