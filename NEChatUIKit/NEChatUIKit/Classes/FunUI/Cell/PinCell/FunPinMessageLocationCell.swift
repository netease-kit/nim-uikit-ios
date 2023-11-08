// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

@objcMembers
open class FunPinMessageLocationCell: NEBasePinMessageLocationCell {
  override open func setupUI() {
    super.setupUI()
    backLeftConstraint?.constant = 0
    backRightConstraint?.constant = 0
    backView.layer.cornerRadius = 0
    headerView.layer.cornerRadius = 4.0
  }
}
