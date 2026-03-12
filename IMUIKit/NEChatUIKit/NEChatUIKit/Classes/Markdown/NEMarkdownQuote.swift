// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

open class NEMarkdownQuote: NEMarkdownLevelElement {
  fileprivate static let regex = "^(\\>{1,%@})\\s*(.+)$"

  open var maxLevel: Int
  open var font: UIFont?
  open var color: UIColor?
  open var separator: String
  open var indicator: String

  open var regex: String {
    let level: String = maxLevel > 0 ? "\(maxLevel)" : ""
    return String(format: NEMarkdownQuote.regex, level)
  }

  public init(font: UIFont? = nil, maxLevel: Int = 0, indicator: String = ">",
              separator: String = "  ", color: UIColor? = nil) {
    self.maxLevel = maxLevel
    self.indicator = indicator
    self.separator = separator
    self.font = font
    self.color = color
  }

  open func formatText(_ attributedString: NSMutableAttributedString, range: NSRange, level: Int) {
    var string = (0 ..< level).reduce("") { (string: String, _: Int) -> String in
      "\(string)\(separator)"
    }
    string = "\(string)\(indicator) "
    attributedString.replaceCharacters(in: range, with: string)
  }
}
