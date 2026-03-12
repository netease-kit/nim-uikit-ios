// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

/// The base protocol for all Markdown Elements, it handles parsing through regex.
public protocol NEMarkdownElement: AnyObject {
  var regex: String { get }

  func regularExpression() throws -> NSRegularExpression
  func parse(_ attributedString: NSMutableAttributedString)
  func match(_ match: NSTextCheckingResult, attributedString: NSMutableAttributedString)
}

public extension NEMarkdownElement {
  func parse(_ attributedString: NSMutableAttributedString) {
    var location = 0
    do {
      let regex = try regularExpression()
      while let regexMatch =
        regex.firstMatch(in: attributedString.string,
                         options: .withoutAnchoringBounds,
                         range: NSRange(location: location,
                                        length: attributedString.length - location)) {
        let oldLength = attributedString.length
        match(regexMatch, attributedString: attributedString)
        let newLength = attributedString.length
        location = regexMatch.range.location + regexMatch.range.length + newLength - oldLength
      }
    } catch {}
  }
}
