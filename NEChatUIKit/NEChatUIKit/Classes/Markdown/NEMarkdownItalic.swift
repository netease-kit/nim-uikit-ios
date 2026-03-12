// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

open class NEMarkdownItalic: NEMarkdownCommonElement {
  fileprivate static let regex = "(\\s|^)(\\*|_)(?![\\*_\\s])(.+?)(?<![\\*_\\s])(\\2)"

  open var font: UIFont?
  open var color: UIColor?

  open var regex: String {
    NEMarkdownItalic.regex
  }

  public init(font: UIFont?, color: UIColor? = nil) {
    self.font = font?.italic()
    self.color = color
  }
}
