
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunChatMessageTipCell: NEBaseChatMessageTipCell {
  override open func commonUI() {
    super.commonUI()
    contentLabel.font = .systemFont(ofSize: 14)
    contentLabel.textColor = .funRecordAudioTextColor
  }
}
