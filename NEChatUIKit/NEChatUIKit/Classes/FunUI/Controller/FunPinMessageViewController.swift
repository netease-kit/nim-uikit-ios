// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class FunPinMessageViewController: NEBasePinMessageViewController {
  override public init(session: NIMSession) {
    super.init(session: session)
    pin_content_maxW = (kScreenWidth - 32)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .funChatBackgroundColor
    emptyView.setEmptyImage(name: "fun_user_empty")
  }

  override open func getRegisterCellDic() -> [String: NEBasePinMessageCell.Type] {
    ChatMessageHelper.getPinCellRegisterDic(isFun: true)
  }

  override open func showAction(item: PinMessageModel) {
    var actions = [NECustomAlertAction]()
    weak var weakSelf = self

    let cancelPinAction = NECustomAlertAction(title: chatLocalizable("operation_cancel_pin")) {
      weakSelf?.cancelPinActionClicked(item: item)
    }
    actions.append(cancelPinAction)

    if item.message.messageType == .text {
      let copyAction = NECustomAlertAction(title: chatLocalizable("operation_copy")) {
        weakSelf?.copyActionClicked(item: item)
      }
      actions.append(copyAction)
    }

    if item.message.messageType != .audio {
      let forwardAction = NECustomAlertAction(title: chatLocalizable("operation_forward")) {
        weakSelf?.forwardActionClicked(item: item)
      }
      actions.append(forwardAction)
    }

    showCustomActionSheet(actions)
  }

  override open func getForwardAlertController() -> NEBaseForwardAlertViewController {
    FunForwardAlertViewController()
  }

  override open func forwardMessage(_ message: NIMMessage) {
    if IMKitClient.instance.getConfigCenter().teamEnable {
      let userAction = NECustomAlertAction(title: chatLocalizable("contact_user")) { [weak self] in
        self?.forwardMessageToUser(message)
      }

      let teamAction = NECustomAlertAction(title: chatLocalizable("team")) { [weak self] in
        self?.forwardMessageToTeam(message)
      }

      showCustomActionSheet([teamAction, userAction])
    } else {
      forwardMessageToUser(message)
    }
  }

  override open func getMultiForwardViewController(_ messageAttachmentUrl: String?,
                                                   _ messageAttachmentFilePath: String,
                                                   _ messageAttachmentMD5: String?) -> MultiForwardViewController {
    FunMultiForwardViewController(messageAttachmentUrl, messageAttachmentFilePath, messageAttachmentMD5)
  }
}
