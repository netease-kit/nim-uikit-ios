
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import SVGKit

public enum ReplyMessageUtil {
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
      text = text + localizable("msg_image")
    case .audio:
      text = text + localizable("msg_audio")
    case .video:
      text = text + localizable("msg_video")
    case .file:
      text = text + localizable("msg_file")
    case .custom:
      text = text + localizable("msg_custom")
    default:
      text = text + localizable("msg_unknown")
    }
    return text
  }
}
