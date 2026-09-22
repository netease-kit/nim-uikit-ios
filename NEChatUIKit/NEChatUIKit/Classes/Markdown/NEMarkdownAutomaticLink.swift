// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

@objcMembers
open class NEMarkdownAutomaticLink: NEMarkdownLink {
  override open func regularExpression() throws -> NSRegularExpression {
    try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
  }

  override open func match(_ match: NSTextCheckingResult,
                           attributedString: NSMutableAttributedString) {
    guard let url = match.url else { return }
    formatText(attributedString, range: match.range, link: url.absoluteString)
    addAttributes(attributedString, range: match.range, link: url.absoluteString)
  }
}
