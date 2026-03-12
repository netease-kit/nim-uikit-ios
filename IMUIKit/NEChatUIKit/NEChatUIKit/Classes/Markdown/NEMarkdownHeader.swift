// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation

open class NEMarkdownHeader: NEMarkdownLevelElement {
  fileprivate static let regex = "^(#{1,%@})\\s*(.+)$"

  open var maxLevel: Int
  open var font: UIFont?
  open var color: UIColor?
  open var fontIncrease: Int

  open var regex: String {
    let level: String = maxLevel > 0 ? "\(maxLevel)" : ""
    return String(format: NEMarkdownHeader.regex, level)
  }

  public init(font: UIFont? = NEMarkdownHeader.defaultFont,
              maxLevel: Int = 0, fontIncrease: Int = 2, color: UIColor? = nil) {
    self.maxLevel = maxLevel
    self.font = font
    self.color = color
    self.fontIncrease = fontIncrease
  }

  open func formatText(_ attributedString: NSMutableAttributedString, range: NSRange, level: Int) {
    attributedString.deleteCharacters(in: range)
  }

  open func attributesForLevel(_ level: Int) -> [NSAttributedString.Key: AnyObject] {
    var attributes = attributes
    if let font = font {
      let headerFontSize: CGFloat = font.pointSize + 4 + (-1 * CGFloat(level) * CGFloat(fontIncrease))

      attributes[NSAttributedString.Key.font] = font.withSize(headerFontSize).bold()
    }
    return attributes
  }
}
