
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objcMembers
public class QChatSystemMessageProvider: NSObject {
  public static let shared = QChatSystemMessageProvider()
  override private init() {
    super.init()
  }

  public func sendMessage(message: NIMQChatMessage, session: NIMSession,
                          _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().qchatMessageManager.send(message, to: session) { error in
      completion(error)
    }
  }

  public func getMessageHistory(param: GetMessageHistoryParam,
                                _ completion: @escaping (Error?, [NIMQChatMessage]?) -> Void) {
    NIMSDK.shared().qchatMessageManager.getMessageHistory(param.toImParam()) { error, result in
      completion(error, result?.messages)
    }
  }

  public func getLocalMessage(param: NIMQChatGetMessageCacheParam, completion: @escaping (Error?, [NIMQChatMessage]?) -> Void) {
    NIMSDK.shared().qchatMessageManager.getMessageCache(param) { error, result in
      completion(error, result?.messages)
    }
  }

  public func markMessageRead(param: MarkMessageReadParam,
                              _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().qchatMessageManager.markMessageRead(param.toImParam()) { error in
      completion(error)
    }
  }

  public func addDelegate(delegate: NIMQChatMessageManagerDelegate) {
    NIMSDK.shared().qchatMessageManager.add(delegate)
  }

  public func removeDelegate(delegate: NIMQChatMessageManagerDelegate) {
    NIMSDK.shared().qchatMessageManager.add(delegate)
  }
}
