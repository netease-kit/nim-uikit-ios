// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class NormalMultiForwardViewController: MultiForwardViewController {
  override public init(_ attachmentUrl: String?,
                       _ attachmentFilePath: String,
                       _ attachmentMD5: String?) {
    super.init(attachmentUrl, attachmentFilePath, attachmentMD5)
    navigationView.backgroundColor = .white
    navigationController?.navigationBar.backgroundColor = .white
    cellRegisterDic = ChatMessageHelper.getChatCellRegisterDic(isFun: false)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func getMultiForwardViewController(_ messageAttachmentUrl: String?,
                                                   _ messageAttachmentFilePath: String,
                                                   _ messageAttachmentMD5: String?) -> MultiForwardViewController {
    NormalMultiForwardViewController(messageAttachmentUrl, messageAttachmentFilePath, messageAttachmentMD5)
  }
}
