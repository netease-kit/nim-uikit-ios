
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import NECoreIM2Kit
import NIMSDK

@objc
public protocol NEConversationListener: NSObjectProtocol {
  /// 会话同步开始
  @objc optional func onConversationSyncStarted()

  /// 会话同步完成
  @objc optional func onConversationSyncFinished()

  /// 会话同步失败
  /// - Parameter error: 失败信息
  @objc optional func onConversationSyncFailed(_ error: V2NIMError)

  /// 会话创建回调
  /// - Parameter conversation: 会话
  @objc optional func onConversationCreated(_ conversation: V2NIMConversation)

  /// 会话删除回调
  /// - Parameter conversationIds: 会话id列表
  @objc optional func onConversationDeleted(_ conversationIds: [String])

  /// 会话变更回调
  /// - Parameter conversations: 会话列表
  @objc optional func onConversationChanged(_ conversations: [V2NIMConversation])

  /// 总未读数变更回调
  /// - Parameter unreadCount: 未读数
  @objc optional func onTotalUnreadCountChanged(_ unreadCount: Int)

  /// 注册了 subscribeUnreadCountByFilter 监听后，会抛出该回调
  /// 根据不同Filter，回调对应的内容
  /// - Parameters:
  ///   - filter: 订阅注册的相关Filter
  ///   - unreadCount: 对应Fliter过滤条件得出的未读数
  @objc optional func onUnreadCountChangedByFilter(_ filter: V2NIMConversationFilter, _ unreadCount: Int)

  /// 账号多端登录会话已读时间戳标记通知
  /// 账号A登录设备D1, D2,  D1会话已读时间戳标记，同步到D2成员
  /// - Parameters:
  ///   - conversationId: 同步标记的会话ID
  ///   - readTime: 标记的时间戳
  @objc optional func onConversationReadTimeUpdated(_ conversationId: String, _ readTime: TimeInterval)
}

@objcMembers
public class ConversationRepo: NSObject, V2NIMConversationListener {
  public static let shared = ConversationRepo()

  private let conversationMultiDelegate = MultiDelegate<NEConversationListener>(strongReferences: false)

  /// V2  会话 Provider
  public let conversationProvider = ConversationProvider.shared

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
    conversationProvider.addListener(self)
  }

  /// 添加回到监听
  /// - Parameter listener: 实现监听协议的对象
  open func addConversationListener(_ listener: NEConversationListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    conversationMultiDelegate.addDelegate(listener)
  }

  /// 移除监听
  /// - Parameter listener: 实现监听协议的对象
  open func removeConversationListener(_ listener: NEConversationListener) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    conversationMultiDelegate.removeDelegate(listener)
  }

  /// 删除一个会话
  /// - Parameter conversationId: 会话id
  /// - Parameter clearMessage: 是否清空消息，默认不清空
  /// - Parameter completion: 完成回调
  open func deleteConversation(_ conversationId: String,
                               _ clearMessage: Bool = false,
                               _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " conversationId: \(conversationId) clearMessage: \(clearMessage)")
    conversationProvider.deleteConversation(conversationId, clearMessage, completion)
  }

  /// 创建一个会话
  /// - Parameter conversationId: 会话id
  /// - Parameter completion: 完成回调
  open func createConversation(_ conversationId: String, _ completion: @escaping (V2NIMConversation?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " conversationId: \(conversationId)")
    conversationProvider.createConversation(conversationId, completion)
  }

  /// 获取一个会话
  /// - Parameter conversationId: 会话id
  /// - Parameter completion: 完成回调
  open func getConversation(_ conversationId: String,
                            _ completion: @escaping (V2NIMConversation?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " conversationId: \(conversationId)")
    conversationProvider.getConversation(conversationId, completion)
  }

  /// 根据 id 批量获取会话
  /// - Parameter conversationIds: 会话id数组
  /// - Parameter completion: 完成回调
  open func getConversationListByIds(_ conversationIds: [String],
                                     _ completion: @escaping ([V2NIMConversation]?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " conversationIds: \(conversationIds.description)")
    conversationProvider.getConversationListByIds(conversationIds, completion)
  }

  /// 分页获取会话列表
  /// - Parameter offset: 偏移量
  /// - Parameter limit: 限制数量
  /// - Parameter completion: 完成回调
  open func getConversationList(_ offset: Int64, _ limit: Int, _ completion: @escaping ([V2NIMConversation]?, Int64?, Bool?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " offset: \(offset)  limit: \(limit)")
    conversationProvider.getConversationList(offset, limit) { result, error in
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
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " conversationId: \(conversationId) stickTop: \(stickTop)")
    conversationProvider.stickTopConversation(conversationId, stickTop, completion)
  }

  /// 获取所有未读数
  /// - Returns: 返回未读数
  open func getTotalUnreadCount() -> Int {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    return conversationProvider.getTotalUnreadCount()
  }

  /// 清空所有未读数
  open func clearTotalUnreadCount(_ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    conversationProvider.clearTotalUnreadCount(completion)
  }

  /// 标记会话已读时间戳
  /// - Parameter conversationId: 会话id
  /// - Parameter completion: 完成回调
  open func markConversationRead(_ conversationId: String, _ completion: @escaping (TimeInterval?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " conversationId: \(conversationId)")
    conversationProvider.markConversationRead(conversationId, completion)
  }

  /// 获取会话已读时间戳
  /// - Parameter conversationId: 会话id
  /// - Parameter completion: 完成回调
  open func getConversationReadTime(_ conversationId: String, _ completion: @escaping (TimeInterval?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " conversationId: \(conversationId)")
    conversationProvider.getConversationReadTime(conversationId, completion)
  }

  /// 根据会话id列表清空相应会话的未读数
  /// - Parameter conversationIds: 会话id数组
  /// - Parameter completion: 完成回调
  open func clearUnreadCountByIds(_ conversationIds: [String], _ completion: @escaping ([V2NIMConversationOperationResult]?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " conversationIds: \(conversationIds.description)")
    conversationProvider.clearUnreadCountByIds(conversationIds, completion)
  }

  /// 会话同步开始
  open func onSyncStarted() {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    conversationMultiDelegate |> { delegate in
      delegate.onConversationSyncStarted?()
    }
  }

  /// 会话同步完成
  open func onSyncFinished() {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    conversationMultiDelegate |> { delegate in
      delegate.onConversationSyncFinished?()
    }
  }

  /// 会话同步失败
  /// - Parameter error: 失败信息
  open func onSyncFailed(_ error: V2NIMError) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " error: \(error.desc)")
    conversationMultiDelegate |> { delegate in
      delegate.onConversationSyncFailed?(error)
    }
  }

  /// 会话创建回调
  /// - Parameter conversation: 会话
  open func onConversationCreated(_ conversation: V2NIMConversation) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " conversation: \(conversation.description)")
    conversationMultiDelegate |> { delegate in
      delegate.onConversationCreated?(conversation)
    }
  }

  /// 会话删除回调
  /// - Parameter conversationIds: 会话id列表
  open func onConversationDeleted(_ conversationIds: [String]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " conversationIds: \(conversationIds.description)")
    conversationMultiDelegate |> { delegate in
      delegate.onConversationDeleted?(conversationIds)
    }
  }

  /// 会话变更回调
  /// - Parameter conversations: 会话列表
  open func onConversationChanged(_ conversations: [V2NIMConversation]) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " conversations: \(conversations.description)")
    conversationMultiDelegate |> { delegate in
      delegate.onConversationChanged?(conversations)
    }
  }

  /// 总未读数变更回调
  /// - Parameter unreadCount: 未读数
  open func onTotalUnreadCountChanged(_ unreadCount: Int) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " unreadCount: \(unreadCount)")
    conversationMultiDelegate |> { delegate in
      delegate.onTotalUnreadCountChanged?(unreadCount)
    }
  }

  /// 注册了 subscribeUnreadCountByFilter 监听后，会抛出该回调
  /// 根据不同Filter，回调对应的内容
  /// - Parameters:
  ///   - filter: 订阅注册的相关Filter
  ///   - unreadCount: 对应Fliter过滤条件得出的未读数
  public func onUnreadCountChanged(by filter: V2NIMConversationFilter, unreadCount: Int) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " filter: \(filter.description) unreadCount: \(unreadCount)")
    conversationMultiDelegate |> { delegate in
      delegate.onUnreadCountChangedByFilter?(filter, unreadCount)
    }
  }

  /// 账号多端登录会话已读时间戳标记通知
  /// 账号A登录设备D1, D2,  D1会话已读时间戳标记，同步到D2成员
  /// - Parameters:
  ///   - conversationId: 同步标记的会话ID
  ///   - readTime: 标记的时间戳
  public func onConversationReadTimeUpdated(_ conversationId: String, readTime: TimeInterval) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " conversationId: \(conversationId) readTime: \(readTime)")
    conversationMultiDelegate |> { delegate in
      delegate.onConversationReadTimeUpdated?(conversationId, readTime)
    }
  }

  // MARK: - 扩展会话操作

  /// 获取置顶会话列表
  /// - Parameter completion: 完成回调
  open func getStickTopConversationList(_ completion: @escaping ([V2NIMConversation]?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    ConversationProvider.shared.getStickTopConversationList { conversations, error in
      completion(conversations, error)
    }
  }

  /// 设置会话免打扰
  /// - Parameters:
  ///   - conversationId: 会话 ID
  ///   - mute: 是否免打扰
  ///   - completion: 完成回调
  open func muteConversation(_ conversationId: String, _ mute: Bool, _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " conversationId: \(conversationId) mute: \(mute)")
    ConversationProvider.shared.muteConversation(conversationId, mute) { error in
      completion(error)
    }
  }

  /// 按会话分组 ID 清空未读数
  /// - Parameters:
  ///   - groupId: 分组 ID
  ///   - completion: 完成回调
  open func clearUnreadCountByGroupId(_ groupId: String, _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " groupId: \(groupId)")
    ConversationProvider.shared.clearUnreadCountByGroupId(groupId) { error in
      completion(error)
    }
  }

  /// 按类型清空未读数
  /// - Parameters:
  ///   - types: 会话类型数组
  ///   - completion: 完成回调
  open func clearUnreadCountByTypes(_ types: [NSNumber], _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " types: \(types)")
    ConversationProvider.shared.clearUnreadCountByTypes(types) { error in
      completion(error)
    }
  }

  /// 更新会话
  /// - Parameters:
  ///   - conversationId: 会话 ID
  ///   - updateInfo: 更新信息
  ///   - completion: 完成回调
  open func updateConversation(_ conversationId: String, _ updateInfo: V2NIMConversationUpdate, _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " conversationId: \(conversationId)")
    ConversationProvider.shared.updateConversation(conversationId, updateInfo) { error in
      completion(error)
    }
  }

  /// 更新会话本地扩展字段
  /// - Parameters:
  ///   - conversationId: 会话 ID
  ///   - localExtension: 本地扩展字段
  ///   - completion: 完成回调
  open func updateConversationLocalExtension(_ conversationId: String, _ localExtension: String, _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " conversationId: \(conversationId)")
    ConversationProvider.shared.updateConversationLocalExtension(conversationId, localExtension) { error in
      completion(error)
    }
  }

  /// 分页获取会话列表（按选项过滤）
  /// - Parameters:
  ///   - offset: 偏移量
  ///   - limit: 限制数量
  ///   - option: 查询条件
  ///   - completion: 完成回调
  open func getConversationListByOption(_ offset: Int64, _ limit: Int, _ option: V2NIMConversationOption, _ completion: @escaping (V2NIMConversationResult?, NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " offset: \(offset) limit: \(limit)")
    ConversationProvider.shared.getConversationListByOption(offset, limit, option) { result, error in
      completion(result, error)
    }
  }

  /// 订阅过滤后的未读数变化
  /// - Parameters:
  ///   - filter: 过滤条件
  ///   - completion: 完成回调
  open func subscribeUnreadCountByFilter(_ filter: V2NIMConversationFilter, _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    ConversationProvider.shared.addUnreadCountChangeObserver(filter) { error in
      completion(error)
    }
  }

  /// 取消订阅过滤后的未读数变化
  /// - Parameters:
  ///   - filter: 过滤条件
  ///   - completion: 完成回调
  open func unsubscribeUnreadCountByFilter(_ filter: V2NIMConversationFilter, _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    ConversationProvider.shared.unsubscribeUnreadCountByFilter(filter) { error in
      completion(error)
    }
  }
}
