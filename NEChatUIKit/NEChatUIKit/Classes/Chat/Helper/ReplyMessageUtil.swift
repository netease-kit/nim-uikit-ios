
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit

@objcMembers
open class ReplyMessageUtil: NSObject {
  @nonobjc
  public static func textForReplyModel(model: MessageContentModel) -> String {
    var text = ""
    if let name = model.fullName {
      text += name + ": "
    }

    if model.type == .text || model.type == .aiStreamText {
      if let content = NECustomUtils.contentOfRichText(model.message?.attachment) {
        return text + content
      }
      text += "\(model.message?.text ?? chatLocalizable("message_not_found"))"
    } else {
      text += "\(ChatMessageHelper.contentOfMessage(model.message))"
    }

    return text
  }

  @objc(textForReplyModel:)
  public static func objc_textForReplyModel(_ model: MessageContentModel) -> String {
    textForReplyModel(model: model)
  }

  @objc(textForReplyModelWithModel:)
  public static func objc_textForReplyModel(withModel model: MessageContentModel) -> String {
    textForReplyModel(model: model)
  }
}
