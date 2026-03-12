
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import UIKit

@objcMembers
open class NEChatBaseCell: UITableViewCell {
  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func uploadProgress(_ progress: UInt) {}

  open func setModel(_ model: MessageContentModel) {}
  open func setModel(_ model: MessageContentModel, _ isSend: Bool = false) {}
}
