
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK

@objc
enum DownloadState: Int {
  case Success = 1
  case Downalod
}

@objcMembers
class MessageVideoModel: MessageContentModel {
  public var imageUrl: String?
  public var state = DownloadState.Success
  public var progress: Float = 0
  public weak var cell: NEChatBaseCell?
  required init(message: NIMMessage?) {
    super.init(message: message)
    type = .video
    if let videoObject = message?.messageObject as? NIMVideoObject {
      imageUrl = videoObject.url
      contentSize = ChatMessageHelper.getSizeWithMaxSize(
        chat_pic_size,
        size: videoObject.coverSize,
        miniWH: chat_min_h
      )
    } else {
      contentSize = chat_pic_size
    }
    height = Float(contentSize.height + chat_content_margin) + fullNameHeight
  }
}
