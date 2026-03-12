//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunFusionContactSelectedController: NEBaseFusionContactSelectedController {
  override open func viewDidLoad() {
    fusionRegisterCellDic = [0: FunFusionContactSelectedCell.self]
    super.viewDidLoad()
    fusionEmptyView.setEmptyImage(name: "fun_user_empty")
  }

  override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    64
  }
}
