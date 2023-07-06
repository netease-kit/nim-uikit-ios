
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public class ReplyMessageUtil: NSObject {
  public static func textForReplyModel(model: MessageContentModel) -> String {
    var text = "|"
    if let name = model.fullName {
      text += name
    }
    text += ": "
    switch model.type {
    case .text, .reply:
      if let t = model.message?.text {
        text += t
      } else {
        text = chatLocalizable("message_not_found")
      }
    case .image:
      text += "[\(chatLocalizable("msg_image"))]"
    case .audio:
      text += "[\(chatLocalizable("msg_audio"))]"
    case .video:
      text += "[\(chatLocalizable("msg_video"))]"
    case .file:
      text += "[\(chatLocalizable("msg_file"))]"
    case .custom:
      text += "[\(chatLocalizable("msg_custom"))]"
    case .location:
      text += "[\(chatLocalizable("msg_location"))]"
    default:
      text += "[\(chatLocalizable("msg_unknown"))]"
    }
    return text
  }
}
