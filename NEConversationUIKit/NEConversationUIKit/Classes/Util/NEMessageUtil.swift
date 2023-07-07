
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
public class NEMessageUtil {
  /// last message
  /// - Parameter message: message
  /// - Returns: result
  public class func messageContent(message: NIMMessage) -> String {
    var text = ""
    switch message.messageType {
    case .text:
      if let messageText = message.text {
        text = messageText
      }
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
    case .tip:
      if let messageText = message.text {
        text = messageText
      }
    case .rtcCallRecord:
      let record = message.messageObject as? NIMRtcCallRecordObject
      text = (record?.callType == .audio) ? localizable("internet_phone") :
        localizable("video_chat")
    default:
      text = localizable("unknown")
    }

    return text
  }
}
