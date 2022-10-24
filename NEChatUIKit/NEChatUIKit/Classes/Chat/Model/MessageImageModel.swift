
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objcMembers
class MessageImageModel: MessageContentModel {
  public var imageUrl: String?
  required init(message: NIMMessage?) {
    super.init(message: message)
    type = .image
    if let imageObject = message?.messageObject as? NIMImageObject {
      if let path = imageObject.path, FileManager.default.fileExists(atPath: path) {
        imageUrl = path
      } else {
        imageUrl = imageObject.url
      }
      contentSize = ChatMessageHelper.getSizeWithMaxSize(
        qChat_pic_size,
        size: imageObject.size,
        miniWH: qChat_min_h
      )
    } else {
      contentSize = qChat_pic_size
    }
    height = Float(contentSize.height + qChat_margin) + fullNameHeight
  }
}
