
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NIMSDK

@objcMembers
open class AIChatViewModel: NSObject {
  public var aiChatData: [AIChatCellModel]?
  public var lastContents: [V2NIMMessage]?
  public var lastMessage: V2NIMMessage?

  /// 加载 AI 助聊语句
  /// - Parameters:
  ///   - messages: 上下文消息
  ///   - lastMessage: 对方发送的最后一条消息
  open func loadData(_ messages: [V2NIMMessage]?,
                     _ lastMessage: V2NIMMessage?,
                     _ completion: @escaping (Error?) -> Void) {
    if messages != nil {
      lastContents = messages
    }

    if lastMessage != nil {
      self.lastMessage = lastMessage
    }

    if let aiChatDataLoader = ChatUIConfig.shared.aiChatDataLoader {
      aiChatDataLoader(messages ?? lastContents, lastMessage ?? self.lastMessage) { [weak self] models, error in
        self?.aiChatData = models
        completion(error)
      }
    } else {
      let error = NSError(domain: "[\(className())] [\(#function)] aiChatDataLoader is nil", code: -1)
      completion(error)
    }
  }
}
