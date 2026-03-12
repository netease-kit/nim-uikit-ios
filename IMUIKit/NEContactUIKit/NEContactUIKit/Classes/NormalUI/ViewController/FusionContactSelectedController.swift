//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FusionContactSelectedController: NEBaseFusionContactSelectedController {
  override open func viewDidLoad() {
    fusionRegisterCellDic = [0: FusionContactSelectedCell.self]
    super.viewDidLoad()
  }
}
