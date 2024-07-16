// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonKit
import NIMSDK
import UIKit

@objcMembers
open class FunMultiForwardViewController: MultiForwardViewController {
  override public init(_ attachmentUrl: String?,
                       _ attachmentFilePath: String,
                       _ attachmentMD5: String?) {
    super.init(attachmentUrl, attachmentFilePath, attachmentMD5)
    brokenNetworkViewHeight = 48
    cellRegisterDic = ChatMessageHelper.getChatCellRegisterDic(isFun: true)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .funChatBackgroundColor // 换肤颜色提取
    brokenNetworkView.errorIconView.isHidden = false
    brokenNetworkView.backgroundColor = .funChatNetworkBrokenBackgroundColor
    brokenNetworkView.contentLabel.textColor = .funChatNetworkBrokenTitleColor
    navigationView.backgroundColor = .funChatBackgroundColor
    navigationView.titleBarBottomLine.backgroundColor = .funChatNavigationBottomLineColor
  }

  override open func getMultiForwardViewController(_ messageAttachmentUrl: String?,
                                                   _ messageAttachmentFilePath: String,
                                                   _ messageAttachmentMD5: String?) -> MultiForwardViewController {
    FunMultiForwardViewController(messageAttachmentUrl, messageAttachmentFilePath, messageAttachmentMD5)
  }

  override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    viewModel.messages[indexPath.row].cellHeight()
  }

  open func getMessageModel(model: MessageModel) {
    if model.type == .tip || model.type == .notification {
      if let tipModel = model as? MessageTipsModel, let text = tipModel.text {
        tipModel.contentSize = String.getRealSize(text, .systemFont(ofSize: 14), CGSize(width: chat_text_maxW, height: CGFloat.greatestFiniteMagnitude))
        tipModel.height = max(tipModel.contentSize.height + chat_content_margin, 28)
      }
      return
    }

    let contentWidth = model.contentSize.width
    let contentHeight = model.contentSize.height
    if contentHeight < fun_chat_min_h {
      let subHeight = fun_chat_min_h - contentHeight
      model.contentSize = CGSize(width: contentWidth, height: fun_chat_min_h)
      model.offset = CGFloat(subHeight)
    }

    if model.type == .rtcCallRecord {
      model.contentSize = CGSize(width: contentWidth, height: contentHeight - 2)
      model.offset = -2
    }
  }
}
