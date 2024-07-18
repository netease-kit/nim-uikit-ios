
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

open class NEEmotionTool: NSObject {
  /// 找出所有表情的位置集合
  /// - Parameter str: 字符串
  /// - Returns: 表情位置
  class func getRegularArray(str: String) -> [NSTextCheckingResult]? {
    let regular = "\\[[^\\[|^\\]]+\\]"

    var reExpression: NSRegularExpression?
    do {
      reExpression = try NSRegularExpression(pattern: regular, options: .caseInsensitive)
    } catch {}
    // 找出所有符合正则的位置集合
    let regularArr = reExpression?.matches(
      in: str,
      options: .reportProgress,
      range: NSRange(location: 0, length: str.utf16.count)
    )

    return regularArr
  }

  /// 表情替换
  /// - Parameters:
  ///   - str: 原始文本
  ///   - font: 字体
  ///   - offset: 偏移量
  /// - Returns: 替换表情后的富文本
  class func getAttWithStr(str: String, font: UIFont,
                           _ offset: CGPoint = CGPoint(x: 0, y: -3)) -> NSMutableAttributedString {
    let regularArr = getRegularArray(str: str)
    let emoticons = NIMInputEmoticonManager.shared
      .emoticonCatalog(catalogID: NIMKit_EmojiCatalog)?.emoticons
    let attStr = NSMutableAttributedString(string: str, attributes: [
      NSAttributedString.Key.font: font,
      .foregroundColor: NEKitChatConfig.shared.ui.messageProperties.messageTextColor,
    ])

    if let regArr = regularArr, regArr.count > 0, let targetEmotions = emoticons {
      for i in (0 ... regArr.count - 1).reversed() {
        let result = regArr[i]

        for obj in targetEmotions {
          let ocStr = str as NSString
          if ocStr.substring(with: result.range) == obj.tag {
            attStr.replaceCharacters(
              in: result.range,
              with: getAttWithEmotion(emotion: obj, font: font, offset: offset)
            )
            break
          }
        }
      }
    }
    return attStr
  }

  class func getAttWithStr(str: String, font: UIFont, color: UIColor, _ offset: CGPoint = CGPoint(x: 0, y: -3)) -> NSMutableAttributedString {
    let att = getAttWithStr(str: str, font: font, offset)
    att.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: att.length))
    return att
  }

  class func getAttWithEmotion(emotion: NIMInputEmoticon, font: UIFont,
                               offset: CGPoint) -> NSAttributedString {
    let textAttachment = NEEmotionAttachment()
    textAttachment.emotion = emotion
    let height = font.lineHeight
    textAttachment.bounds = CGRect(x: offset.x, y: offset.y, width: height, height: height)
    return NSAttributedString(attachment: textAttachment)
  }

  /// 将富文本中的表情转换为文本
  /// - Parameters:
  ///   - att: 富文本
  ///   - range: 范围
  /// - Returns: 文本
  class func getTextWithAtt(_ att: NSMutableAttributedString?, _ range: NSRange) -> String? {
    guard let att = att else {
      return nil
    }

    var text = ""
    att.enumerateAttributes(in: range, using: { attrs, range, stop in
      if let attachment = attrs[NSAttributedString.Key.attachment] as? NEEmotionAttachment {
        text += attachment.emotion?.tag ?? ""
      } else {
        let subStr = (att.string as NSString).substring(with: range)
        text += subStr
      }

    })

    return text.isEmpty ? nil : text
  }
}
