
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import NIMSDK

@objcMembers
open class MessageTextModel: MessageContentModel {
  public var attributeStr: NSMutableAttributedString?
  public var textHeight: CGFloat = 0
  public var textWidght: CGFloat = 0

  public required init(message: V2NIMMessage?) {
    super.init(message: message)
    type = .text

    attributeStr = NEEmotionTool.getAttWithStr(
      str: message?.text ?? "",
      font: messageTextFont
    )

    if let remoteExt = getDictionaryFromJSONString(message?.serverExtension ?? ""), let dic = remoteExt[yxAtMsg] as? [String: AnyObject] {
      for (_, value) in dic {
        if let contentDic = value as? [String: AnyObject] {
          if let array = contentDic[atSegmentsKey] as? [AnyObject] {
            if let models = NSArray.yx_modelArray(with: MessageAtInfoModel.self, json: array) as? [MessageAtInfoModel] {
              for model in models {
                if attributeStr?.length ?? 0 > model.end {
                  attributeStr?.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.ne_blueText, range: NSMakeRange(model.start, model.end - model.start + atRangeOffset))
                }
              }
            }
          }
        }
      }
    }

    let textSize = NSAttributedString.getRealSize(attributeStr, messageTextFont, messageMaxSize)
    textHeight = textSize.height
    textWidght = textSize.width
    contentSize = CGSize(width: textSize.width + chat_content_margin * 2, height: textHeight + chat_content_margin * 2)
    height = contentSize.height + chat_content_margin * 2 + fullNameHeight + chat_pin_height
  }
}
