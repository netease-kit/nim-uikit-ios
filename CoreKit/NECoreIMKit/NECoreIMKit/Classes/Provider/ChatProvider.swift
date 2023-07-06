
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objcMembers
public class ChatProvider: NSObject {
  public static let shared = ChatProvider()

  public func addDelegate(delegate: NIMChatManagerDelegate) {
    NIMSDK.shared().chatManager.add(delegate)
  }

  public func removeDelegate(delegate: NIMChatManagerDelegate) {
    NIMSDK.shared().chatManager.remove(delegate)
  }

  public func sendMessage(message: NIMMessage, session: NIMSession,
                          _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().chatManager.send(message, to: session) { error in
      completion(error)
    }
  }

  public func getMessageHistory(session: NIMSession, message: NIMMessage?, limit: UInt,
                                _ completion: @escaping (Error?, [NIMMessage]?) -> Void) {
    NIMSDK.shared().conversationManager
      .messages(in: session, message: message, limit: Int(limit)) { error, messages in
        completion(error, messages)
      }
  }

  public func markRead(param: NIMMessageReceipt, _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().chatManager.send(param) { error in
      print("[chat provider] markRead error:\(error)")
      completion(error)
    }
  }

  public func markReadInTeam(param: [NIMMessageReceipt],
                             _ completion: @escaping (Error?, [NIMMessageReceipt]?) -> Void) {
    NIMSDK.shared().chatManager.sendTeamMessageReceipts(param) { error, receipts in
      print("[chat provider] markRead error:\(error)")
      completion(error, receipts)
    }
  }

  public func resendMessage(message: NIMMessage) -> NSError? {
    do {
      try NIMSDK.shared().chatManager.resend(message)
      return nil
    } catch let error as NSError {
      return error
    }
  }

//    MARK: revoke

  public func revokeMessage(message: NIMMessage, _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().chatManager.revokeMessage(message) { error in
      completion(error as? NSError)
    }
  }

  public func fetchMessageAttachment(_ message: NIMMessage,
                                     _ completion: @escaping (Error?) -> Void) {
    do {
      try NIMSDK.shared().chatManager.fetchMessageAttachment(message)
      completion(nil)
    } catch {
      completion(error)
    }
  }

  public func downLoad(_ urlString: String, _ filePath: String, _ progress: NIMHttpProgressBlock?,
                       _ completion: NIMDownloadCompleteBlock?) {
    NIMSDK.shared().resourceManager.download(
      urlString,
      filepath: filePath,
      progress: progress,
      completion: completion
    )
  }

  public func cancelTask(filepath: String) {
    NIMSDK.shared().resourceManager.cancelTask(filepath)
  }

  public func makeForwardMessage(_ message: NIMMessage) -> NIMMessage? {
    NIMSDK.shared().chatManager.makeForwardMessage(from: message, error: nil)
  }

  public func sendForwardMessage(_ message: NIMMessage, _ session: NIMSession) {
    do {
      try NIMSDK.shared().chatManager.sendForwardMessage(message, to: session)
    } catch {
      print("send forward message : ", error)
    }
  }

  public func forwardMessage(_ message: NIMMessage, _ session: NIMSession) {
    do {
      try NIMSDK.shared().chatManager.forwardMessage(message, to: session)
    } catch {
      print("forward message : ", error)
    }
  }

  public func refreshReceipts(_ messages: [NIMMessage]) {
    NIMSDK.shared().chatManager.refreshTeamMessageReceipts(messages)
  }
}
