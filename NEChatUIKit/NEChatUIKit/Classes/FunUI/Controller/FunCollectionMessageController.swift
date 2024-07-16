//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class FunCollectionMessageController: NEBaseCollectionMessageController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    collection_content_maxW = (kScreenWidth - 32)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .funChatBackgroundColor
    collectionEmptyView.setEmptyImage(name: "fun_user_empty")
  }

  /// 获取娱乐版皮肤样式注册表
  override open func getRegisterDic() -> [String: NEBaseCollectionMessageCell.Type] {
    ChatMessageHelper.getCollectionCellRegisterDic(isFun: true)
  }

  override open func showActions(_ model: CollectionMessageModel) {
    var actions = [NECustomAlertAction]()
    weak var weakSelf = self

    let deleteCollectionAction = NECustomAlertAction(title: chatLocalizable("operation_delete_collection")) {
      weakSelf?.removeCollectionActionClicked(model)
    }
    actions.append(deleteCollectionAction)

    if model.message?.messageType == .MESSAGE_TYPE_TEXT {
      let copyAction = NECustomAlertAction(title: chatLocalizable("operation_copy")) {
        weakSelf?.copyCollectionActionClicked(model)
      }
      actions.append(copyAction)
    }

    if let message = model.message, message.messageType != .MESSAGE_TYPE_AUDIO {
      let forwardAction = NECustomAlertAction(title: chatLocalizable("operation_forward")) {
        weakSelf?.forwardCollectionMessage(message, model.conversationName ?? "")
      }
      actions.append(forwardAction)
    }

    showCustomActionSheet(actions)
  }

  override open func getCollectionForwardAlertController() -> NEBaseForwardAlertViewController {
    FunForwardAlertViewController()
  }

  override open func getMultiForwardViewController(_ messageAttachmentUrl: String?,
                                                   _ messageAttachmentFilePath: String,
                                                   _ messageAttachmentMD5: String?) -> MultiForwardViewController {
    FunMultiForwardViewController(messageAttachmentUrl, messageAttachmentFilePath, messageAttachmentMD5)
  }
}
