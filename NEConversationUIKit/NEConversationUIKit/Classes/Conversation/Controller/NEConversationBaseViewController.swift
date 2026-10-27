// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEBaseUIKit
import UIKit

/// 会话模块 ViewController 基类
@objcMembers
open class NEConversationBaseViewController: NEBaseViewController {
  override open var shouldShowTitleBar: Bool {
    ConversationUIConfig.shared.showTitleBar
  }

  override open var shouldBindMoreButtonAction: Bool { false }

  override open func setupBackUI() {
    let image = CommonUIConfig.shared.backArrowImage?.withRenderingMode(.alwaysOriginal)
    let backItem = UIBarButtonItem(
      image: image,
      style: .plain,
      target: self,
      action: #selector(backEvent)
    )
    backItem.accessibilityIdentifier = "id.backArrow"
    navigationItem.leftBarButtonItem = backItem
  }
}
