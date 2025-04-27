// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

open class NEMarkdownCode: NEMarkdownCommonElement {
  fileprivate static let regex = "(.?|^)(\\`{1,3})(.+?)(\\2)"

  open var font: UIFont?
  open var color: UIColor?
  open var textHighlightColor: UIColor?
  open var textBackgroundColor: UIColor?

  open var regex: String {
    NEMarkdownCode.regex
  }

  public init(font: UIFont? = NEMarkdownCode.defaultFont,
              color: UIColor? = nil,
              textHighlightColor: UIColor? = NEMarkdownCode.defaultHighlightColor,
              textBackgroundColor: UIColor? = NEMarkdownCode.defaultBackgroundColor) {
    self.font = font
    self.color = color
    self.textHighlightColor = textHighlightColor
    self.textBackgroundColor = textBackgroundColor
  }

  open func addAttributes(_ attributedString: NSMutableAttributedString, range: NSRange) {
    let matchString: String = attributedString.attributedSubstring(from: range).string
    guard let unescapedString = matchString.unescapeUTF16() else { return }
    attributedString.replaceCharacters(in: range, with: unescapedString)

    var codeAttributes = attributes

    textHighlightColor.flatMap { codeAttributes[NSAttributedString.Key.foregroundColor] = $0 }
    textBackgroundColor.flatMap { codeAttributes[NSAttributedString.Key.backgroundColor] = $0 }
    font.flatMap { codeAttributes[NSAttributedString.Key.font] = $0 }

    let updatedRange = (attributedString.string as NSString).range(of: unescapedString)
    attributedString.addAttributes(codeAttributes, range: NSRange(location: range.location, length: updatedRange.length))
  }
}
