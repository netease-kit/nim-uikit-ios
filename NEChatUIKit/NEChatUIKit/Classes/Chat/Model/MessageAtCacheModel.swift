// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class MessageAtCacheModel: NSObject {
  public var atModel: MessageAtInfoModel
  public var accid: String
  public var text: String?
  init(atModel: MessageAtInfoModel, accid: String) {
    self.atModel = atModel
    self.accid = accid
  }
}
