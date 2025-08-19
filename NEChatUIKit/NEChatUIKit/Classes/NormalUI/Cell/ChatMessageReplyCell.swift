
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import SDWebImage
import UIKit

@objcMembers
open class ChatMessageReplyCell: ChatMessageAIStreamTextCell {
  public lazy var replyImageViewLeft: UIImageView = {
    let view = UIImageView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.contentMode = .scaleAspectFill
    view.clipsToBounds = true
    view.accessibilityIdentifier = "id.thumbnail"
    view.layer.cornerRadius = 8
    return view
  }()

  public lazy var replyImageViewRight: UIImageView = {
    let view = UIImageView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.contentMode = .scaleAspectFill
    view.clipsToBounds = true
    view.accessibilityIdentifier = "id.thumbnail"
    view.layer.cornerRadius = 8
    return view
  }()

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)
    replyLabelLeft.isHidden = showRight
    replyImageViewLeft.isHidden = showRight
    replyLabelRight.isHidden = !showRight
    replyImageViewRight.isHidden = !showRight
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    let replyLabel = isSend ? replyLabelRight : replyLabelLeft

    if var text = model.replyText,
       let font = replyLabel.font {
      // 如果有回复的消息，需要在回复的消息前加上“| ”
      if text != chatLocalizable("message_not_found") {
        text = "| " + text
      }

      replyLabel.attributedText = NEEmotionTool.getAttWithStr(str: text,
                                                              font: font,
                                                              color: replyLabel.textColor)
      replyLabel.accessibilityValue = text

      if let attriText = replyLabel.attributedText {
        let textSize = NSAttributedString.getRealLabelSize(attriText, font, CGSize(width: chat_text_maxW, height: CGFloat.greatestFiniteMagnitude))
        model.contentSize.width = max(textSize.width, model.textWidth) + chat_content_margin * 2
      }
    }

    super.setModel(model, isSend)

    let replyImageView = isSend ? replyImageViewRight : replyImageViewLeft
    if let m = model as? MessageImageModel,
       let urlString = m.urlString {
      var options: SDWebImageOptions = [.retryFailed]
      if let imageObject = model.message?.attachment as? V2NIMMessageImageAttachment,
         imageObject.ext?.lowercased() != ".gif" {
        options = [.retryFailed, .progressiveLoad]
      }

      if urlString.hasPrefix("http") {
        let url = URL(string: urlString)
        replyImageView.sd_setImage(with: url, placeholderImage: nil, options: options, context: nil)
      } else {
        let url = URL(fileURLWithPath: urlString)
        replyImageView.sd_setImage(with: url, placeholderImage: nil, options: options, context: nil)
      }
    } else {
      replyImageView.image = nil
    }
  }
}
