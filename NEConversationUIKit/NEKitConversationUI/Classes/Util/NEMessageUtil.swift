
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
public class NEMessageUtil {
  /// last message
  /// - Parameter message: message
  /// - Returns: result
  class func messageContent(message: NIMMessage) -> String {
    var text = ""
    switch message.messageType {
    case .text:
      if let messageText = message.text {
        text = messageText
      }
    case .audio:
      text = "[语音]"
    case .image:
      text = "[图片]"
    case .video:
      text = "[视频]"
    case .location:
      text = "[位置]"
    case .notification:
      text = "[通知]"
    case .file:
      text = "[文件]"
    case .tip:
      if let messageText = message.text {
        text = messageText
      }
    case .rtcCallRecord:
      let record = message.messageObject as? NIMRtcCallRecordObject
      text = (record?.callType == .audio) ? "[网络通话]" : "[视频聊天]"
    default:
      text = "[未知消息]"
    }

    return text
  }
}
