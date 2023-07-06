
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objcMembers
public class ConversationProvider: NSObject {
  public static let shared = ConversationProvider()

  override init() {
    super.init()
  }

  public func addDelegate(delegate: NIMConversationManagerDelegate) {
    NIMSDK.shared().conversationManager.add(delegate)
  }

  public func removeDelegate(delegate: NIMConversationManagerDelegate) {
    NIMSDK.shared().conversationManager.remove(delegate)
  }

  /// 获取所有最近会话
  public func getAllRecentSessions() -> [NIMRecentSession]? {
    NIMSDK.shared().conversationManager.allRecentSessions()
  }

  /// 从服务端分页获取历史会话列表
  /// - Parameters:
  ///   - option: 分页查询选项，可为空，空时默认全量获取
  ///   - completion: 完成回调
  public func fetchServerSessions(option: NIMFetchServerSessionOption,
                                  _ completion: @escaping (NSError?, [NIMRecentSession]?)
                                    -> Void) {
    NIMSDK.shared().conversationManager
      .fetchServerSessions(option) { error, recentSessions, hasMore in
        completion(error as NSError?, recentSessions)
      }
  }

  /// 删除某个最近会话
  /// - Parameters:
  ///   - params: 参数
  ///   - option: 选项
  ///   - completion: 回调
  public func deleteRecentConversation(_ params: NIMRecentSession,
                                       _ option: NIMDeleteRecentSessionOption,
                                       _ completion: @escaping (NSError?) -> Void) {
    NIMSDK.shared().conversationManager.delete(params, option: option) { error in
      completion(error as NSError?)
    }
  }

  /// 删除服务器端最近会话
  /// - Parameters:
  ///   - rencentSession: 会话参数
  ///   - option: 选择
  ///   - completion: 回调
  public func deleteServerSessions(_ sessions: [NIMSession],
                                   _ completion: @escaping (NSError?) -> Void) {
    NIMSDK.shared().conversationManager.deleteServerSessions(sessions) { error in
      completion(error as NSError?)
    }
  }

  /// 删除某个最近会话
  public func deleteRecentSession(_ recentSession: NIMRecentSession) {
    NIMSDK.shared().conversationManager.delete(recentSession)
  }

  public func createRecentTeamSession(_ teamid: String) -> NIMSession {
    let option = NIMAddEmptyRecentSessionBySessionOption()
    let session = NIMSession(teamid, type: .team)
    NIMSDK.shared().conversationManager.addEmptyRecentSession(by: session, option: option)
    return session
  }

  public func markReadInSession(_ session: NIMSession,
                                _ completion: @escaping (NSError?) -> Void) {
    NIMSDK.shared().conversationManager.markAllMessagesRead(in: session)
  }

  /**
    查询漫游消息未完整会话信息

    @param session 目标会话
    @param completion 结果完成回调
   */
  public func incompleteSessionInfo(session: NIMSession,
                                    _ completion: @escaping (NSError?,
                                                             [NIMIncompleteSessionInfo]?) -> Void) {
    NIMSDK.shared().conversationManager
      .incompleteSessionInfo(by: session) { error, sessionInfo in
        completion(error as? NSError, sessionInfo)
      }
  }

  /// 更新未漫游完整会话列表
  /// - Parameters:
  ///   - messages: 消息对象
  ///   - completion: 完成回调
  public func updateIncompleteSessions(messages: [NIMMessage],
                                       _ completion: @escaping (NSError?,
                                                                [NIMImportedRecentSession]?)
                                         -> Void) {
    NIMSDK.shared().conversationManager
      .updateIncompleteSessions(messages) { error, recentSessions in
        completion(error as? NSError, recentSessions)
      }
  }

  /// 获取所有未读数
  /// - Parameter notify: 是否需要通知
  /// - Returns: 返回未读数
  public func allUnreadCount(notify: Bool) -> NSInteger {
    NIMSDK.shared().conversationManager.allUnreadCount(notify)
  }

  /// 设置所有会话消息为已读
  public func markAllMessagesRead() {
    NIMSDK.shared().conversationManager.markAllMessagesRead()
  }

  /// 删除本地消息
  public func deleteMessage(message: NIMMessage) {
    let op = NIMDeleteMessageOption()
//    op.removeFromDB = true
    NIMSDK.shared().conversationManager.delete(message, option: op)
  }

  /// 从服务端删除
  public func deleteServerMessage(message: NIMMessage, ext: String?, _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().conversationManager.deleteMessage(fromServer: message, ext: ext) { error in
      completion(error)
    }
  }

  public func onMarkMessageReadComplete(in session: NIMSession, error: Error?) {
    print("session:\(session) error:\(error)")
  }

  public func searchMessages(_ session: NIMSession, option: NIMMessageSearchOption,
                             _ completion: @escaping (NSError?, [NIMMessage]?) -> Void) {
    NIMSDK.shared().conversationManager
      .searchMessages(session, option: option) { error, messages in
        completion(error as NSError?, messages)
      }
  }

  public func messagesInSession(_ session: NIMSession, messageIds: [String]) -> [NIMMessage]? {
    NIMSDK.shared().conversationManager.messages(in: session, messageIds: messageIds)
  }

  /// 从服务器上获取一个会话里某条消息之前的若干条的消息
  /// - Parameters:
  ///   - session: 消息所属的会话
  ///   - option: 搜索选项
  ///   - completion: 回调
  public func fetchMessageHistory(session: NIMSession, option: NIMHistoryMessageSearchOption,
                                  _ completion: @escaping (NSError?, [NIMMessage]?) -> Void) {
    NIMSDK.shared().conversationManager
      .fetchMessageHistory(session, option: option) { error, messages in
        completion(error as NSError?, messages)
      }
  }

  /// 保存消息到本地
  /// - Parameters:
  ///  - message: 消息对象
  ///  - session: 会话
  public func saveMessageToDB(_ message: NIMMessage, _ session: NIMSession, _ completion: @escaping (NSError?) -> Void) {
    NIMSDK.shared().conversationManager.save(message, for: session) { error in
      completion(error as NSError?)
    }
  }

  /// 动态途径获取消息，默认回调错误码403，动态能力需要开通功能，并在同步完成后生效
  ///
  ///  @param param
  ///  @param completion 完成后的回调
  public func getMessagesDynamically(_ param: NIMGetMessagesDynamicallyParam,
                                     _ completion: @escaping (NSError?, Bool, [NIMMessage]?) -> Void) {
    NIMSDK.shared().conversationManager.getMessagesDynamically(param) { error, isReliable, messages in
      completion(error as NSError?, isReliable, messages)
    }
  }
}
