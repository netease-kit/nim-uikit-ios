
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public class ReplyMessageUtil: NSObject {
  public static func textForReplyModel(model: MessageContentModel) -> String {
    var text = "|"
    if let name = model.fullName {
      text = text + name
    }
    text = text + ": "
    switch model.type {
    case .text:
      if let t = model.message?.text {
        text = text + t
      }
    case .image:
      text = text + chatLocalizable("msg_image")
    case .audio:
      text = text + chatLocalizable("msg_audio")
    case .video:
      text = text + chatLocalizable("msg_video")
    case .file:
      text = text + chatLocalizable("msg_file")
    case .custom:
      text = text + chatLocalizable("msg_custom")
    default:
      text = text + chatLocalizable("msg_unknown")
    }
    return text
  }
}
