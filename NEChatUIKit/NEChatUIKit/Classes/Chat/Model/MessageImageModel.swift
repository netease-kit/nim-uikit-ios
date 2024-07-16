
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NIMSDK

@objcMembers
open class MessageImageModel: MessageContentModel {
  public var urlString: String?

  public required init(message: V2NIMMessage?) {
    super.init(message: message)
    type = .image
    if let imageObject = message?.attachment as? V2NIMMessageImageAttachment {
      if let path = imageObject.path, FileManager.default.fileExists(atPath: path) {
        urlString = path
      } else if let url = imageObject.url {
        if imageObject.ext?.lowercased() != ".gif" {
          urlString = V2NIMStorageUtil.imageThumbUrl(url, thumbSize: 350)
        }
        urlString = url
      }
      contentSize = ChatMessageHelper.getSizeWithMaxSize(
        chat_pic_size,
        size: CGSize(width: Int(imageObject.width), height: Int(imageObject.height)),
        miniWH: chat_min_h
      )
    } else {
      contentSize = chat_pic_size
    }
    height = contentSize.height + chat_content_margin * 2 + fullNameHeight + chat_pin_height
  }
}
