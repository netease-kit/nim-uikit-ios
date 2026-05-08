
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECommonKit
import NIMSDK

@objcMembers
open class MessageTextModel: MessageContentModel {
  public var messageText: String?
  public var attributeStr: NSMutableAttributedString?
  public var textHeight: CGFloat = 0

  // MARK: - 翻译相关字段

  /// 译文信息（从 localExtension 解析，仅初始化时解析一次）
  public var translationInfo: TranslationInfo?

  /// 译文区域是否可见（用户手动隐藏后为 false）
  public var translationVisible: Bool = true

  /// 当前已加入 height 的译文高度（用于还原），0 表示尚未加入
  public var addedTranslationHeight: CGFloat = 0

  /// 估算译文气泡高度（Normal 皮肤内嵌用）
  /// 布局：dividerTop(8) + divider(0.5) + textTop(8) + textBlock + gap(6) + footer(20) + containerBottom(chat_content_margin)
  public func estimateTranslationBubbleHeight() -> CGFloat {
    guard let text = translationInfo?.translatedText, !text.isEmpty, translationVisible else { return 0 }
    let maxWidth = chat_content_maxW - chat_content_margin * 2
    let textSize = (text as NSString).boundingRect(
      with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: [.font: messageTextFont],
      context: nil
    )
    // 6(divTop) + 0.5(div) + 12(textTop) + text + 6(gap) + 20(footer) + chat_content_margin(bottom)
    return ceil(textSize.height) + 6 + 1 + 12 + 6 + 20 + chat_content_margin
  }

  /// 译文 footer 区域所需最小宽度：图标(14) + 间距(4) + 文案宽度
  public var translationFooterMinWidth: CGFloat {
    let tagText = chatLocalizable("chat_translate_tag") as NSString
    let tagW = tagText.boundingRect(
      with: CGSize(width: 200, height: 20),
      options: .usesLineFragmentOrigin,
      attributes: [.font: UIFont.systemFont(ofSize: 12)],
      context: nil
    ).width
    return ceil(14 + 4 + tagW)
  }

  /// 估算译文文本宽度（用于气泡宽度扩展，同时保证 footer 不被裁切）
  public func estimateTranslationTextWidth() -> CGFloat {
    guard let text = translationInfo?.translatedText, !text.isEmpty, translationVisible else { return 0 }
    let maxWidth = chat_content_maxW - chat_content_margin * 2
    let textSize = (text as NSString).boundingRect(
      with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: [.font: messageTextFont],
      context: nil
    )
    // 取译文文字宽度和 footer 最小宽度中的较大值，确保 footer 完整显示
    return min(max(ceil(textSize.width), translationFooterMinWidth), maxWidth)
  }

  public required init(message: V2NIMMessage?) {
    super.init(message: message)
    type = .text
    messageText = message?.text
    // 初始化时从 localExtension 解析翻译缓存（仅解析一次）
    translationInfo = TranslationInfo.parse(from: message?.localExtension)
    resetMessage(message)
  }

  override public func resetMessage(_ message: V2NIMMessage?) {
    super.resetMessage(message)

    if let text = messageText, !text.isEmpty {
      attributeStr = NEEmotionTool.getAttWithStr(
        str: text,
        font: messageTextFont,
        color: messageTextColor
      )
    } else {
      attributeStr = nil
    }

    // 解析 @，效果高亮
    if IMKitConfigCenter.shared.enableAtMessage {
      if let att = ChatMessageHelper.loadAtInMessage(message, attributeStr) {
        attributeStr = att
      }
    }

    resetHeight()
  }

  public func getTextSize(_ attributeStr: NSAttributedString?) -> CGSize {
    NSAttributedString.getRealTextViewSize(attributeStr ?? self.attributeStr, messageTextFont, messageMaxSize)
  }

  public func resetHeight(_ attributeStr: NSAttributedString? = nil) {
    let textSize = getTextSize(attributeStr)
    textHeight = ceil(textSize.height)
    textWidth = ceil(textSize.width)
    let contentSizeWidth = textWidth + chat_content_margin * 2
    let contentSizeHeight = textHeight + chat_content_margin * 2
    contentSize = CGSize(width: contentSizeWidth, height: contentSizeHeight)
    height = contentSizeHeight + chat_content_margin * 2 + fullNameHeight + chat_pin_height
  }

  public func resetWH(_ height: CGFloat, _ width: CGFloat = chat_content_maxW) {
    textHeight = ceil(height)
    textWidth = ceil(width)
    let contentSizeWidth = textWidth + chat_content_margin * 2
    let contentSizeHeight = textHeight + chat_content_margin * 2
    contentSize = CGSize(width: contentSizeWidth, height: contentSizeHeight)
    self.height = contentSizeHeight + chat_content_margin * 2 + fullNameHeight + chat_pin_height
  }

  /// 获取划词选中的文本（替换内置表情）
  /// - Returns: 选中的文本
  override open func selectText() -> String? {
    if let selectRange = selectRange {
      // 内置表情转为文本
      let text = NEEmotionTool.getTextWithAtt(attributeStr, selectRange)

      return text
    }

    return nil
  }
}
