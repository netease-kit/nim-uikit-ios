// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objc
open class MessageCustomModel: MessageContentModel {
  public required init(message: NIMMessage?) {
    super.init(message: message)
    type = .custom
    if let attachment = NECustomAttachment.attachmentOfCustomMessage(message: message) {
      contentSize = CGSize(width: 0, height: Int(attachment.cellHeight))
      height = contentSize.height + chat_content_margin * 2 + fullNameHeight
    }
  }
}
