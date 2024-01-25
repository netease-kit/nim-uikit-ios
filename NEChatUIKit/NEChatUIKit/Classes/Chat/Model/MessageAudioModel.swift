
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objcMembers
open class MessageAudioModel: MessageContentModel {
  public var duration: Int = 0
  public var isPlaying = false

  public required init(message: NIMMessage?) {
    super.init(message: message)
    type = .audio
    var audioW = 96.0
    let audioTotalWidth = kScreenWidth <= 325 ? 230 : 265.0
    // contentSize
    if let obj = message?.messageObject as? NIMAudioObject {
      duration = obj.duration / 1000
      if duration > 2 {
        audioW = min(Double(duration) * 8 + audioW, audioTotalWidth)
      }
    }
    contentSize = CGSize(width: audioW, height: chat_min_h)
    height = contentSize.height + chat_content_margin * 2 + fullNameHeight
  }
}
