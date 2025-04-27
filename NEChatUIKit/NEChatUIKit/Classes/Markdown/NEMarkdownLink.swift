// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

open class NEMarkdownLink: NEMarkdownLinkElement {
  fileprivate static let regex = "\\[[^\\]]+\\]\\(\\S+(?=\\))\\)"

  // This regex is eager if does not count even trailing Parentheses.
  fileprivate static let onlyLinkRegex = "\\(\\S+(?=\\))\\)"

  open var font: UIFont?
  open var color: UIColor?

  open var regex: String {
    NEMarkdownLink.regex
  }

  open func regularExpression() throws -> NSRegularExpression {
    try NSRegularExpression(pattern: regex, options: .dotMatchesLineSeparators)
  }

  public init(font: UIFont? = nil, color: UIColor? = NEMarkdownLink.defaultColor) {
    self.font = font
    self.color = color
  }

  open func formatText(_ attributedString: NSMutableAttributedString, range: NSRange,
                       link: String) {
    guard let encodedLink = link.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
    else {
      return
    }
    guard let url = URL(string: link) ?? URL(string: encodedLink) else { return }
    attributedString.addAttribute(NSAttributedString.Key.link, value: url, range: range)
  }

  open func match(_ match: NSTextCheckingResult, attributedString: NSMutableAttributedString) {
    let nsString = (attributedString.string as NSString)
    let urlString = nsString.substring(with: match.range)

    guard let onlyLinkRegex = try? NSRegularExpression(pattern: NEMarkdownLink.onlyLinkRegex, options: .dotMatchesLineSeparators) else {
      return
    }

    guard let linkMatch = onlyLinkRegex.firstMatch(in: urlString,
                                                   options: .withoutAnchoringBounds,
                                                   range: NSRange(location: 0, length: urlString.count)) else {
      return
    }

    let urlLinkAbsoluteStart = match.range.location

    let linkURLString = nsString
      .substring(with: NSRange(location: urlLinkAbsoluteStart + linkMatch.range.location + 1, length: linkMatch.range.length - 2))

    // deleting trailing markdown
    // needs to be called before formattingBlock to support modification of length
    let trailingMarkdownRange = NSRange(location: urlLinkAbsoluteStart + linkMatch.range.location - 1, length: linkMatch.range.length + 1)
    attributedString.deleteCharacters(in: trailingMarkdownRange)

    // deleting leading markdown
    // needs to be called before formattingBlock to provide a stable range
    let leadingMarkdownRange = NSRange(location: match.range.location, length: 1)
    attributedString.deleteCharacters(in: leadingMarkdownRange)

    let formatRange = NSRange(location: match.range.location,
                              length: linkMatch.range.location - 2)

    formatText(attributedString, range: formatRange, link: linkURLString)
    addAttributes(attributedString, range: formatRange, link: linkURLString)
  }

  open func addAttributes(_ attributedString: NSMutableAttributedString, range: NSRange,
                          link: String) {
    attributedString.addAttributes(attributes, range: range)
  }
}
