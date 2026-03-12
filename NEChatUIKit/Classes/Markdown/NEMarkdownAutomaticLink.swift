// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

open class NEMarkdownAutomaticLink: NEMarkdownLink {
  override open func regularExpression() throws -> NSRegularExpression {
    try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
  }

  override open func match(_ match: NSTextCheckingResult,
                           attributedString: NSMutableAttributedString) {
    let linkURLString = attributedString.attributedSubstring(from: match.range).string
    formatText(attributedString, range: match.range, link: linkURLString)
    addAttributes(attributedString, range: match.range, link: linkURLString)
  }
}
