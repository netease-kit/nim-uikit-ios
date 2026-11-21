
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import UIKit

@objcMembers
open class PopListView: NEBasePopListView {
  override open func setupUI() {
    super.setupUI()
    shadowTopConstraint = shadowView.topAnchor.constraint(equalTo: topAnchor, constant: topConstant - 10)
    shadowRightConstraint = shadowView.rightAnchor.constraint(equalTo: rightAnchor, constant: -20)
    shadowTopConstraint?.isActive = true
    shadowRightConstraint?.isActive = true

    popView.backgroundColor = .normalConversationPopViewBg
  }
}
