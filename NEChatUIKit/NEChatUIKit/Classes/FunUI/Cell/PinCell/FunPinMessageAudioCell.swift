// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunPinMessageAudioCell: NEBasePinMessageAudioCell {
  override open func setupUI() {
    super.setupUI()

    backLeftConstraint?.constant = 0
    backRightConstraint?.constant = 0
    backView.layer.cornerRadius = 0
    headerView.layer.cornerRadius = 4.0
    let image = NEKitChatConfig.shared.ui.leftBubbleBg ?? UIImage.ne_imageNamed(name: "fun_pin_message_audio_bg")
    bubbleImage.image = image?
      .resizableImage(withCapInsets: UIEdgeInsets(top: 35, left: 25, bottom: 10, right: 25))
  }
}
