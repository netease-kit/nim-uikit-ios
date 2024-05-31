// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class FunPinMessageViewController: NEBasePinMessageViewController {
  override public init(conversationId: String) {
    super.init(conversationId: conversationId)
    pin_content_maxW = (kScreenWidth - 32)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .funChatBackgroundColor
    emptyView.setEmptyImage(name: "fun_user_empty")
  }

  override open func getRegisterCellDic() -> [String: NEBasePinMessageCell.Type] {
    ChatMessageHelper.getPinCellRegisterDic(isFun: true)
  }

  override open func showAction(item: NEPinMessageModel) {
    var actions = [NECustomAlertAction]()
    weak var weakSelf = self

    let cancelPinAction = NECustomAlertAction(title: chatLocalizable("operation_cancel_pin")) {
      weakSelf?.cancelPinActionClicked(item: item)
    }
    actions.append(cancelPinAction)

    if item.message.messageType == .MESSAGE_TYPE_TEXT {
      let copyAction = NECustomAlertAction(title: chatLocalizable("operation_copy")) {
        weakSelf?.copyActionClicked(item: item)
      }
      actions.append(copyAction)
    }

    if item.message.messageType != .MESSAGE_TYPE_AUDIO {
      let forwardAction = NECustomAlertAction(title: chatLocalizable("operation_forward")) {
        weakSelf?.forwardActionClicked(item: item)
      }
      actions.append(forwardAction)
    }

    showCustomActionSheet(actions)
  }

  /// 获取转发确认弹窗 - 通用版
  override open func getForwardAlertController() -> NEBaseForwardAlertViewController {
    FunForwardAlertViewController()
  }

  override open func getMultiForwardViewController(_ messageAttachmentUrl: String?,
                                                   _ messageAttachmentFilePath: String,
                                                   _ messageAttachmentMD5: String?) -> MultiForwardViewController {
    FunMultiForwardViewController(messageAttachmentUrl, messageAttachmentFilePath, messageAttachmentMD5)
  }
}
