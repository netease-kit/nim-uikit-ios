
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

open class NEMessageUtil {
  /// last message
  /// - Parameter message: message
  /// - Returns: result
  open class func messageContent(message: NIMMessage) -> String {
    var text = ""
    switch message.messageType {
    case .text:
      if let messageText = message.text {
        text = messageText
      }
    case .tip:
      return localizable("tip")
    case .audio:
      text = localizable("voice")
    case .image:
      text = localizable("picture")
    case .video:
      text = localizable("video")
    case .location:
      text = localizable("location")
    case .notification:
      text = localizable("notification")
    case .file:
      text = localizable("file")
    case .custom:
      text = contentOfCustomMessage(message: message)
    case .rtcCallRecord:
      let record = message.messageObject as? NIMRtcCallRecordObject
      text = (record?.callType == .audio) ? localizable("internet_phone") :
        localizable("video_chat")
    default:
      text = localizable("unknown")
    }

    return text
  }

  /// 返回自定义消息的外显文案
  static func contentOfCustomMessage(message: NIMMessage?) -> String {
    if message?.messageType == .custom,
       let object = message?.messageObject as? NIMCustomObject,
       let custom = object.attachment as? NECustomAttachment {
      if custom.customType == customMultiForwardType {
        return localizable("chat_history")
      }
      if custom.customType == customRichTextType {
        if let data = NECustomAttachment.dataOfCustomMessage(message: message),
           let title = data["title"] as? String {
          return title
        }
      }
    }
    return localizable("unknown")
  }
}
