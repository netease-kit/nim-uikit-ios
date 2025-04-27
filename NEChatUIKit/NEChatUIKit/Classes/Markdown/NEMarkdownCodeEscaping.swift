// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

open class NEMarkdownCodeEscaping: NEMarkdownElement {
  fileprivate static let regex = "(\\s+|^)(?<!\\\\)(?:\\\\\\\\)*+(\\`+)(.+?)(\\2)"

  open var regex: String {
    NEMarkdownCodeEscaping.regex
  }

  open func regularExpression() throws -> NSRegularExpression {
    try NSRegularExpression(pattern: regex, options: .dotMatchesLineSeparators)
  }

  open func match(_ match: NSTextCheckingResult, attributedString: NSMutableAttributedString) {
    let range = match.range(at: 3)
    // escaping all characters
    let matchString = attributedString.attributedSubstring(from: range).string
    let escapedString = [UInt16](matchString.utf16)
      .map { (value: UInt16) -> String in String(format: "%04x", value) }
      .reduce("") { (string: String, character: String) -> String in
        "\(string)\(character)"
      }
    attributedString.replaceCharacters(in: range, with: escapedString)
  }
}
