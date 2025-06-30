
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NIMSDK

@objcMembers
open class AIChatViewModel: NSObject {
  public var aiChatData: [AIChatCellModel]?

  /// 加载 AI 助聊语句
  /// - Parameters:
  ///   - messages: 上下文消息
  ///   - completion: 回调
  open func loadData(_ messages: [V2NIMMessage]?,
                     _ completion: @escaping (Error?) -> Void) {
    if let aiChatDataLoader = ChatUIConfig.shared.aiChatDataLoader {
      aiChatDataLoader(messages) { [weak self] models, error in
        self?.aiChatData = models
        completion(error)
      }
    } else {
      let error = NSError(domain: "[\(className())] [\(#function)] aiChatDataLoader is nil", code: -1)
      completion(error)
    }
  }
}
