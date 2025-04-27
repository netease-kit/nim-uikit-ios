// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public protocol NEMarkdownCommonElement: NEMarkdownElement, NEMarkdownStyle {
  func addAttributes(_ attributedString: NSMutableAttributedString, range: NSRange)
}

public extension NEMarkdownCommonElement {
  func regularExpression() throws -> NSRegularExpression {
    try NSRegularExpression(pattern: regex, options: [])
  }

  func addAttributes(_ attributedString: NSMutableAttributedString, range: NSRange) {
    attributedString.addAttributes(attributes, range: range)
  }

  func match(_ match: NSTextCheckingResult, attributedString: NSMutableAttributedString) {
    // deleting trailing markdown
    attributedString.deleteCharacters(in: match.range(at: 4))
    // formatting string (may alter the length)
    addAttributes(attributedString, range: match.range(at: 3))
    // deleting leading markdown
    attributedString.deleteCharacters(in: match.range(at: 2))
  }
}
