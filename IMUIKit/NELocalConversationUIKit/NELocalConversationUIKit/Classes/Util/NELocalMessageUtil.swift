
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import NIMSDK

open class NEMessageUtil {
  /// last message
  /// - Parameter message: message
  /// - Returns: result
  open class func messageContent(_ messageType: V2NIMMessageType,
                                 _ text: String?,
                                 _ attachment: V2NIMMessageAttachment?) -> String {
    switch messageType {
    case .MESSAGE_TYPE_TEXT:
      return text ?? ""
    case .MESSAGE_TYPE_TIP:
      return localizable("tip")
    case .MESSAGE_TYPE_AUDIO:
      return localizable("voice")
    case .MESSAGE_TYPE_IMAGE:
      return localizable("picture")
    case .MESSAGE_TYPE_VIDEO:
      return localizable("video")
    case .MESSAGE_TYPE_LOCATION:
      return localizable("location") + " \(text ?? "")"
    case .MESSAGE_TYPE_NOTIFICATION:
      return localizable("notification")
    case .MESSAGE_TYPE_FILE:
      return localizable("file")
    case .MESSAGE_TYPE_CUSTOM:
      return contentOfCustomMessage(attachment)
    case .MESSAGE_TYPE_CALL:
      if let attachment = attachment as? V2NIMMessageCallAttachment {
        return attachment.type == 1 ? localizable("internet_phone") : localizable("video_chat")
      }
    default:
      return localizable("unknown")
    }
    return localizable("unknown")
  }

  /// 返回自定义消息的外显文案
  static func contentOfCustomMessage(_ attachment: V2NIMMessageAttachment?) -> String {
    if let customType = NECustomUtils.typeOfCustomMessage(attachment) {
      if customType == customMultiForwardType {
        return localizable("chat_history")
      }
      if customType == customRichTextType {
        if let data = NECustomUtils.dataOfCustomMessage(attachment),
           let title = data["title"] as? String {
          return title
        }
      }

      return localizable("custom")
    }
    return localizable("unknown")
  }
}
