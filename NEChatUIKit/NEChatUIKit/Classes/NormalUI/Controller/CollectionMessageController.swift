//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class CollectionMessageController: NEBaseCollectionMessageController {
  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .ne_lightBackgroundColor
    navigationView.backgroundColor = .ne_lightBackgroundColor
    navigationController?.navigationBar.backgroundColor = .ne_lightBackgroundColor
  }

  /// 获取通用版皮肤样式注册表
  override open func getRegisterDic() -> [String: NEBaseCollectionMessageCell.Type] {
    ChatMessageHelper.getCollectionCellRegisterDic(isFun: false)
  }

  override open func getCollectionForwardAlertController() -> NEBaseForwardAlertViewController {
    ForwardAlertViewController()
  }

  override open func getMultiForwardViewController(_ messageAttachmentUrl: String?,
                                                   _ messageAttachmentFilePath: String,
                                                   _ messageAttachmentMD5: String?) -> MultiForwardViewController {
    NormalMultiForwardViewController(messageAttachmentUrl, messageAttachmentFilePath, messageAttachmentMD5)
  }
}
