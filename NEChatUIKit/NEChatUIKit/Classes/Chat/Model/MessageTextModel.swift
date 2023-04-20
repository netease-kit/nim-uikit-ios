
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objcMembers
class MessageTextModel: MessageContentModel {
  public var attributeStr: NSMutableAttributedString?
  public var textHeight: CGFloat = 0

  required init(message: NIMMessage?) {
    super.init(message: message)
    type = .text

    attributeStr = NEEmotionTool.getAttWithStr(
      str: message?.text ?? "",
      font: NEKitChatConfig.shared.ui.messageTextSize
    )

    if let remoteExt = message?.remoteExt, let dic = remoteExt[yxAtMsg] as? [String: AnyObject] {
      dic.forEach { (key: String, value: AnyObject) in
        if let contentDic = value as? [String: AnyObject] {
          if let array = contentDic[atSegmentsKey] as? [AnyObject] {
            if let models = NSArray.yx_modelArray(with: MessageAtInfoModel.self, json: array) as? [MessageAtInfoModel] {
              models.forEach { model in
                if attributeStr?.length ?? 0 > model.end {
                  attributeStr?.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.ne_blueText, range: NSMakeRange(model.start, model.end - model.start + atRangeOffset))
                }
              }
            }
          }
        }
      }
    }

    let textSize = NEChatUITool.getSizeWithAtt(
      att: attributeStr ?? NSAttributedString(string: ""),
      font: NEKitChatConfig.shared.ui.messageTextSize,
      maxSize: CGSize(width: qChat_content_maxW, height: CGFloat.greatestFiniteMagnitude)
    )
    textHeight = textSize.height
    var h = qChat_min_h
    h = textSize.height + 24
    contentSize = CGSize(width: textSize.width + qChat_margin * 2, height: h)
    height = Float(contentSize.height + qChat_margin) + fullNameHeight
  }
}
