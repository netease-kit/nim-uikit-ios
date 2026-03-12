
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import UIKit

@objcMembers
open class AIChatCellModel: NSObject {
  var tagTitle: String?
  var tagTitleColor: UIColor?
  var tagTitleBackgroundColor: UIColor?
  var contentTitle: String?

  public init(tagTitle: String? = nil,
              tagTitleColor: UIColor? = nil,
              tagTitleBackgroundColor: UIColor? = nil,
              contentTitle: String? = nil) {
    self.tagTitle = tagTitle
    self.tagTitleColor = tagTitleColor
    self.tagTitleBackgroundColor = tagTitleBackgroundColor
    self.contentTitle = contentTitle
  }
}
