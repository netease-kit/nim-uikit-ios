
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objcMembers
open class MessageImageModel: MessageContentModel {
  public var imageUrl: String?

  public required init(message: NIMMessage?) {
    super.init(message: message)
    type = .image
    if let imageObject = message?.messageObject as? NIMImageObject {
      if let path = imageObject.path, FileManager.default.fileExists(atPath: path) {
        imageUrl = path
      } else {
        imageUrl = imageObject.url
      }
      contentSize = ChatMessageHelper.getSizeWithMaxSize(
        chat_pic_size,
        size: imageObject.size,
        miniWH: chat_min_h
      )
    } else {
      contentSize = chat_pic_size
    }
    height = contentSize.height + chat_content_margin * 2 + fullNameHeight
  }
}
