// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class PinMessageViewController: NEBasePinMessageViewController {
  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .ne_lightBackgroundColor
    navigationView.backgroundColor = .ne_lightBackgroundColor
    navigationController?.navigationBar.backgroundColor = .ne_lightBackgroundColor
  }

  override open func getRegisterCellDic() -> [String: NEBasePinMessageCell.Type] {
    ChatMessageHelper.getPinCellRegisterDic(isFun: false)
  }

  override open func getForwardAlertController() -> NEBaseForwardAlertViewController {
    ForwardAlertViewController()
  }

  override open func getMultiForwardViewController(_ messageAttachmentUrl: String?,
                                                   _ messageAttachmentFilePath: String,
                                                   _ messageAttachmentMD5: String?) -> MultiForwardViewController {
    NormalMultiForwardViewController(messageAttachmentUrl, messageAttachmentFilePath, messageAttachmentMD5)
  }
}
