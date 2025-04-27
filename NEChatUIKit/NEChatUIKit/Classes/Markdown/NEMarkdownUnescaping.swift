// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

open class NEMarkdownUnescaping: NEMarkdownElement {
  fileprivate static let regex = "\\\\[0-9a-z]{4}"

  open var regex: String {
    NEMarkdownUnescaping.regex
  }

  open func regularExpression() throws -> NSRegularExpression {
    try NSRegularExpression(pattern: regex, options: .dotMatchesLineSeparators)
  }

  open func match(_ match: NSTextCheckingResult, attributedString: NSMutableAttributedString) {
    let range = NSRange(location: match.range.location + 1, length: 4)
    let matchString = attributedString.attributedSubstring(from: range).string
    guard let unescapedString = matchString.unescapeUTF16() else { return }
    attributedString.replaceCharacters(in: match.range, with: unescapedString)
  }
}
