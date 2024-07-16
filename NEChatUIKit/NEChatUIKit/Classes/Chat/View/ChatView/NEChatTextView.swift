
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonUIKit
import UIKit

@objcMembers
open class NEChatTextView: UITextView {
  override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    false
  }

  override open func shouldChangeText(in range: UITextRange, replacementText text: String) -> Bool {
    false
  }
}
