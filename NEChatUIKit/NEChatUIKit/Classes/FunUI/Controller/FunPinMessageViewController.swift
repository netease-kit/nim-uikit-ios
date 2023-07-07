//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK

@objcMembers
open class FunPinMessageViewController: NEBasePinMessageViewController {
  override public func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .funChatBackgroundColor
    emptyView.setEmptyImage(name: "fun_user_empty")
  }

  override open func getRegisterCellDic() -> [Int: NEBasePinMessageCell.Type] {
    let cellClassDic = [
      NIMMessageType.text.rawValue: FunPinMessageTextCell.self,
      NIMMessageType.image.rawValue: FunPinMessageImageCell.self,
      NIMMessageType.audio.rawValue: FunPinMessageAudioCell.self,
      NIMMessageType.video.rawValue: FunPinMessageVideoCell.self,
      NIMMessageType.location.rawValue: FunPinMessageLocationCell.self,
      NIMMessageType.file.rawValue: FunPinMessageFileCell.self,
      PinMessageDefaultType: FunPinMessageDefaultCell.self,
    ]
    return cellClassDic
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
    let userAction = NECustomAlertAction(title: chatLocalizable("contact_user")) { [weak self] in
      self?.forwardMessageToUser(message)
    }

    let teamAction = NECustomAlertAction(title: chatLocalizable("team")) { [weak self] in
      self?.forwardMessageToTeam(message)
    }

    showCustomActionSheet([teamAction, userAction])
  }
}
