
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
    fatalError("init(coder:) has not been implemented")
  }

  open func uploadProgress(byRight: Bool, _ progress: Float) {
    fatalError("override in sub class")
  }

  open func setModel(_ model: MessageContentModel) {}
  open func setModel(_ model: MessageContentModel, _ isSend: Bool = false) {}
}
