
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

open class ReplyMessageUtil: NSObject {
  public static func textForReplyModel(model: MessageContentModel) -> String {
    var text = ""
    if let name = model.fullName {
      text += name + ": "
    }

    if model.type == .reply {
      if let content = NECustomAttachment.contentOfRichText(message: model.message) {
        return text + content
      }
      text += "\(model.message?.text ?? chatLocalizable("message_not_found"))"
    } else {
      text += "\(ChatMessageHelper.contentOfMessage(model.message))"
    }

    return text
  }
}
