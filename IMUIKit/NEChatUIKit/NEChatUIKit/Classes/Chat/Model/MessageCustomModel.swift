// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import NIMSDK
import UIKit

@objc
open class MessageCustomModel: MessageContentModel {
  public required init(message: V2NIMMessage?) {
    super.init(message: message)
    type = .custom
  }

  public init(message: V2NIMMessage?, customType: Int, contentHeight: Int) {
    super.init(message: message)
    type = .custom
    self.customType = customType

    contentSize = CGSize(width: 0, height: contentHeight)
    height = CGFloat(contentHeight) + chat_content_margin * 2 + fullNameHeight + chat_pin_height
    if let customHeight = NECustomUtils.heightOfCustomMessage(message?.attachment) {
      height = customHeight
    }
  }
}
