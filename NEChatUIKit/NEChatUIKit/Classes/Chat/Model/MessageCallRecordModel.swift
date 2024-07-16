
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NIMSDK
import UIKit

@objcMembers
open class MessageCallRecordModel: MessageContentModel {
  public var attributeStr: NSMutableAttributedString?

  public required init(message: V2NIMMessage?) {
    super.init(message: message)
    type = .rtcCallRecord
    var isAuiodRecord = false

    if let attach = message?.attachment as? V2NIMMessageCallAttachment {
      attributeStr = NSMutableAttributedString()
      let callType = attach.type
      let callStatus = attach.status
      var image: UIImage?
      var bound = CGRect.zero
      let offset: CGFloat = -1

      if callType == 1 {
        isAuiodRecord = true
        image = coreLoader.loadImage("audio_record")
        bound = CGRect(x: 0, y: offset - 5, width: 24, height: 24)
      } else {
        image = coreLoader.loadImage("video_record")
        bound = CGRect(x: 0, y: offset, width: 24, height: 14)
      }

      switch callStatus {
      case 1:
        var duration: TimeInterval = 0
        for durationModel in attach.durations {
          if durationModel.accountId == message?.senderId {
            duration = TimeInterval(durationModel.duration)
            break
          }
        }

        let timeString = Date.getFormatPlayTime(duration)
        attributeStr?.append(NSAttributedString(string: chatLocalizable("call_complete") + " \(timeString)"))
      case 2:
        attributeStr?.append(NSAttributedString(string: chatLocalizable("call_canceled")))
      case 3:
        attributeStr?.append(NSAttributedString(string: chatLocalizable("call_rejected")))
      case 4:
        attributeStr?.append(NSAttributedString(string: chatLocalizable("call_timeout")))
      case 5:
        attributeStr?.append(NSAttributedString(string: chatLocalizable("call_busy")))
      default:
        break
      }
      let attachment = NSTextAttachment()
      attachment.image = image
      attachment.bounds = bound
      if message?.isSelf == true {
        attributeStr?.append(NSAttributedString(string: " "))
        attributeStr?.append(NSAttributedString(attachment: attachment))
      } else {
        attributeStr?.insert(NSAttributedString(string: " "), at: 0)
        attributeStr?.insert(NSAttributedString(attachment: attachment), at: 0)
      }

      attributeStr?.addAttribute(NSAttributedString.Key.font, value: messageTextFont, range: NSMakeRange(0, attributeStr?.length ?? 0))

      attributeStr?.addAttribute(NSAttributedString.Key.foregroundColor, value: NEKitChatConfig.shared.ui.messageProperties.messageTextColor, range: NSMakeRange(0, attributeStr?.length ?? 0))
    }

    let textSize = NSAttributedString.getRealSize(attributeStr, messageTextFont, messageMaxSize)
    let contentSizeWidth = textSize.width + chat_cell_margin * 2
    let contentSizeHeight = textSize.height + (isAuiodRecord ? 20 : 24)
    contentSize = CGSize(width: contentSizeWidth, height: contentSizeHeight)
    height = contentSize.height + chat_content_margin * 2 + fullNameHeight + chat_pin_height
  }
}
