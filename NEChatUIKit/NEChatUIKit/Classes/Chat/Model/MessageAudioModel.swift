
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objcMembers
open class MessageAudioModel: MessageContentModel {
  public var duration: Int = 0
  public var audioWidth: Double = 0
  public var isPlaying = false
  public var text: String? // 语音转文字结果

  public required init(message: V2NIMMessage?) {
    super.init(message: message)
    type = .audio
    var audioW = 96.0
    // contentSize
    if let obj = message?.attachment as? V2NIMMessageAudioAttachment {
      duration = Int((Double(obj.duration) / 1000).rounded())
      if duration > 2 {
        audioW = min(Double(duration) * 8 + audioW, audio_max_width)
      }
    }
    audioWidth = audioW
    contentSize = CGSize(width: audioW, height: chat_min_h)
    height = contentSize.height + chat_content_margin * 2 + fullNameHeight + chat_pin_height
  }
}
