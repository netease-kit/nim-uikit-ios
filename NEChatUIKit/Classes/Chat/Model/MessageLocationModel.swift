// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class MessageLocationModel: MessageContentModel {
  public var lat: Double?
  public var lng: Double?
  public var title: String?
  public var subTitle: String?

  public required init(message: V2NIMMessage?) {
    super.init(message: message)
    type = .location
    if let locationObject = message?.attachment as? V2NIMMessageLocationAttachment {
      lat = locationObject.latitude
      lng = locationObject.longitude
      subTitle = locationObject.address
      title = message?.text
      contentSize = CGSize(width: 242, height: 140)
    }
    height = contentSize.height + chat_content_margin * 2 + fullNameHeight + chat_pin_height
  }
}
