
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

open class NEEmotionTool: NSObject {
  class func getAttWithStr(str: String, font: UIFont,
                           _ offset: CGPoint = CGPoint(x: 0, y: -3)) -> NSMutableAttributedString {
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

    let emoticons = NIMInputEmoticonManager.shared
      .emoticonCatalog(catalogID: NIMKit_EmojiCatalog)?.emoticons
    let attStr = NSMutableAttributedString(string: str, attributes: [
      NSAttributedString.Key.font: font,
      .foregroundColor: NEKitChatConfig.shared.ui.messageProperties.messageTextColor,
    ])

    if let regArr = regularArr, regArr.count > 0, let targetEmotions = emoticons {
      for i in (0 ... regArr.count - 1).reversed() {
        let result = regArr[i]

        for (idx, obj) in targetEmotions.enumerated() {
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
}
