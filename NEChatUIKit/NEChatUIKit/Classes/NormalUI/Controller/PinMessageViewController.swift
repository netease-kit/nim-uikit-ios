// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class PinMessageViewController: NEBasePinMessageViewController {
  override public func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .ne_lightBackgroundColor
    customNavigationView.backgroundColor = .ne_lightBackgroundColor
    navigationController?.navigationBar.backgroundColor = .ne_lightBackgroundColor
  }

  override open func getRegisterCellDic() -> [Int: NEBasePinMessageCell.Type] {
    let cellClassDic = [
      NIMMessageType.text.rawValue: PinMessageTextCell.self,
      NIMMessageType.image.rawValue: PinMessageImageCell.self,
      NIMMessageType.audio.rawValue: PinMessageAudioCell.self,
      NIMMessageType.video.rawValue: PinMessageVideoCell.self,
      NIMMessageType.location.rawValue: PinMessageLocationCell.self,
      NIMMessageType.file.rawValue: PinMessageFileCell.self,
      PinMessageDefaultType: PinMessageDefaultCell.self,
    ]
    return cellClassDic
  }

  override open func getForwardAlertController() -> NEBaseForwardAlertViewController {
    ForwardAlertViewController()
  }
}
