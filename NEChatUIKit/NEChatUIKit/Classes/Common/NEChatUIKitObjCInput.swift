// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NIMSDK
import UIKit

public extension NEBaseChatInputView {
  @objc(checkRemoveAtMessageWithRange:attribute:)
  func objcCheckRemoveAtMessage(range: NSRange,
                                attribute: NSAttributedString) -> NSValue? {
    checkRemoveAtMessage(range: range, attribute: attribute).map(NSValue.init(range:))
  }

  @objc(findShowPositionWithRange:attribute:)
  func objcFindShowPosition(range: NSRange,
                            attribute: NSAttributedString) -> NSValue? {
    findShowPosition(range: range, attribute: attribute).map(NSValue.init(range:))
  }

  @objc(convertRangeToNSRangeWithRange:)
  func objcConvertRangeToNSRange(range: UITextRange?) -> NSValue? {
    convertRangeToNSRange(range: range).map(NSValue.init(range:))
  }
}

public extension ChatMessageHelper {
  @objc(isAIStreamLoading:)
  static func objcIsAIStreamLoading(_ message: V2NIMMessage?) -> Bool {
    isAIStreamLoading(message)
  }

  @objc(splitTextByAtMentions:message:)
  static func objcSplitTextByAtMentions(_ text: String,
                                        message: V2NIMMessage) -> NEChatTextMentionSplitResult {
    let result = splitTextByAtMentions(text: text, message: message)
    return NEChatTextMentionSplitResult(parts: result.parts, atFlags: result.isAtFlags)
  }
}
