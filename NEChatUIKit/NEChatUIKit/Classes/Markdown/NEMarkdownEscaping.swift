// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

open class NEMarkdownEscaping: NEMarkdownElement {
  fileprivate static let regex = "\\\\."

  open var regex: String {
    NEMarkdownEscaping.regex
  }

  open func regularExpression() throws -> NSRegularExpression {
    try NSRegularExpression(pattern: regex, options: .dotMatchesLineSeparators)
  }

  open func match(_ match: NSTextCheckingResult, attributedString: NSMutableAttributedString) {
    let range = NSRange(location: match.range.location + 1, length: 1)
    // escape one character
    let matchString = attributedString.attributedSubstring(from: range).string
    if let escapedString = [UInt16](matchString.utf16).first
      .flatMap({ (value: UInt16) -> String in String(format: "%04x", value) }) {
      attributedString.replaceCharacters(in: range, with: escapedString)
    }
  }
}
