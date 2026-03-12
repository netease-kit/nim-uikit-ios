
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import UIKit

@objcMembers
open class ContactHeadItem {
  public var name: String?
  public var imageName: String?
  public var color: UIColor?
  public var router: String

  public init(router: String, name: String? = nil, imageName: String? = nil, color: UIColor? = nil) {
    self.name = name
    self.imageName = imageName
    self.color = color
    self.router = router
  }
}
