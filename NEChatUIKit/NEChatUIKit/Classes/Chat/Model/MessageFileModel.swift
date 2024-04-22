
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class MessageFileModel: MessageVideoModel {
  public var displayName: String?
  public var path: String?
  public var fileLength: Int64?
  public var size: Float = 0

  public required init(message: V2NIMMessage?) {
    super.init(message: message)
    type = .file
    if let fileObject = message?.attachment as? V2NIMMessageFileAttachment {
      displayName = fileObject.name
      path = fileObject.path
      fileLength = Int64(fileObject.size)
    }
    contentSize = chat_file_size
    height = contentSize.height + chat_content_margin * 2 + fullNameHeight + chat_pin_height
  }
}
