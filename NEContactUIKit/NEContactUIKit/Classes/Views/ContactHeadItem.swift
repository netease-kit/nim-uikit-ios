
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

@objcMembers
open class ContactHeadItem {
  public var name: String?
  public var imageName: String?
  public var color = UIColor(hexString: "#60CFA7")
  public var router: String

  init(name: String, imageName: String?, router: String, color: UIColor) {
    self.name = name
    self.imageName = imageName
    self.router = router
    self.color = color
  }
}
