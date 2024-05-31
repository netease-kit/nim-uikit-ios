
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
    let text = message?.text ?? ""
    attributeStr = NEEmotionTool.getAttWithStr(
      str: text,
      font: messageTextFont
    )

    // 兼容老的表情消息，如果前面有表情而位置计算异常则回退回老的解析
    var notFound = false

    // 计算表情(根据转码后的index)
    if let remoteExt = getDictionaryFromJSONString(message?.serverExtension ?? ""), let dic = remoteExt[yxAtMsg] as? [String: AnyObject] {
      for (_, value) in dic {
        if let contentDic = value as? [String: AnyObject] {
          if let array = contentDic[atSegmentsKey] as? [AnyObject] {
            if let models = NSArray.yx_modelArray(with: MessageAtInfoModel.self, json: array) as? [MessageAtInfoModel] {
              for model in models {
                // 前面因为表情增加的索引数量
                var count = 0
                if text.count > model.start {
                  let frontAttributeStr = NEEmotionTool.getAttWithStr(
                    str: String(text.prefix(model.start)),
                    font: messageTextFont
                  )
                  count = getReduceIndexCount(frontAttributeStr)
                }
                let start = model.start - count
                if start < 0 {
                  notFound = true
                  break
                }
                var end = model.end - count

                if model.end + atRangeOffset > text.count {
                  notFound = true
                  break
                }
                // 获取起始索引
                let startIndex = text.index(text.startIndex, offsetBy: model.start)
                // 获取结束索引
                let endIndex = text.index(text.startIndex, offsetBy: model.end + atRangeOffset)
                let frontAttributeStr = NEEmotionTool.getAttWithStr(
                  str: String(text[startIndex ..< endIndex]),
                  font: messageTextFont
                )
                let innerCount = getReduceIndexCount(frontAttributeStr)
                end = end - innerCount
                if end <= start {
                  notFound = true
                  break
                }

                if attributeStr?.length ?? 0 > end {
                  attributeStr?.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.ne_normalTheme, range: NSMakeRange(start, end - start + atRangeOffset))
                }
              }
            }
          }
        }
      }
    }

    if notFound == true, let remoteExt = getDictionaryFromJSONString(message?.serverExtension ?? ""), let dic = remoteExt[yxAtMsg] as? [String: AnyObject] {
      for (_, value) in dic {
        if let contentDic = value as? [String: AnyObject] {
          if let array = contentDic[atSegmentsKey] as? [AnyObject] {
            if let models = NSArray.yx_modelArray(with: MessageAtInfoModel.self, json: array) as? [MessageAtInfoModel] {
              for model in models {
                if attributeStr?.length ?? 0 > model.end {
                  attributeStr?.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.ne_normalTheme, range: NSMakeRange(model.start, model.end - model.start + atRangeOffset))
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

  /// 计算减少的
  /// - Parameter attribute： at 文本前的文本
  func getReduceIndexCount(_ attribute: NSAttributedString) -> Int {
    var count = 0
    attribute.enumerateAttributes(
      in: NSMakeRange(0, attribute.length),
      options: NSAttributedString.EnumerationOptions(rawValue: 0)
    ) { dics, range, stop in
      if let neAttachment = dics[NSAttributedString.Key.attachment] as? NEEmotionAttachment {
        if let tagCount = neAttachment.emotion?.tag?.count {
          count = count + tagCount - 1
        }
      }
    }
    return count
  }
}
