// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

open class NEMarkdownStrikethrough: NEMarkdownCommonElement {
  fileprivate static let regex = "(.?|^)(\\~\\~|__)(?=\\S)(.+?)(?<=\\S)(\\2)"

  open var font: UIFont?
  open var color: UIColor?
  public var attributes: [NSAttributedString.Key: AnyObject] = [.strikethroughStyle: NSNumber(value: NSUnderlineStyle.single.rawValue)]

  open var regex: String {
    NEMarkdownStrikethrough.regex
  }

  public init(font: UIFont? = nil, color: UIColor? = nil) {
    self.font = font
    self.color = color
  }
}
