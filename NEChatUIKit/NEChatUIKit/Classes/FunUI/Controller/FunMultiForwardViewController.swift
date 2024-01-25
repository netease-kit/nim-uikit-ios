// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

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
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .funChatBackgroundColor // 换肤颜色提取
    brokenNetworkView.errorIcon.isHidden = false
    brokenNetworkView.backgroundColor = .funChatNetworkBrokenBackgroundColor
    brokenNetworkView.content.textColor = .funChatNetworkBrokenTitleColor
    navigationView.backgroundColor = .funChatBackgroundColor
    navigationView.titleBarBottomLine.backgroundColor = .funChatNavigationBottomLineColor
  }

  override open func getMultiForwardViewController(_ messageAttachmentUrl: String?,
                                                   _ messageAttachmentFilePath: String,
                                                   _ messageAttachmentMD5: String?) -> MultiForwardViewController {
    FunMultiForwardViewController(messageAttachmentUrl, messageAttachmentFilePath, messageAttachmentMD5)
  }

  override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    viewmodel.messages[indexPath.row].cellHeight()
  }

  open func getMessageModel(model: MessageModel) {
    if model.type == .tip ||
      model.type == .notification ||
      model.type == .time {
      if let tipModel = model as? MessageTipsModel {
        tipModel.contentSize = String.getTextRectSize(tipModel.text ?? "",
                                                      font: .systemFont(ofSize: 14),
                                                      size: CGSize(width: chat_text_maxW, height: CGFloat.greatestFiniteMagnitude))
        tipModel.height = max(tipModel.contentSize.height + chat_content_margin, 28)
      }
      return
    }

    let contentWidth = model.contentSize.width
    let contentHeight = model.contentSize.height
    if contentHeight < 42 {
      let subHeight = 42 - contentHeight
      model.contentSize = CGSize(width: contentWidth, height: 42)
      model.offset = CGFloat(subHeight)
    }

    if model.type == .rtcCallRecord {
      model.contentSize = CGSize(width: contentWidth, height: contentHeight - 2)
      model.offset = -2
    }
  }
}
