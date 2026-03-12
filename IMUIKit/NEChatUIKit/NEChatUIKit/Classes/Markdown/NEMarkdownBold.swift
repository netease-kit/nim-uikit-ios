// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

open class NEMarkdownBold: NEMarkdownCommonElement {
  fileprivate static let regex = "(.?|^)(\\*\\*|__)(?=\\S)(.+?)(?<=\\S)(\\2)"

  open var font: UIFont?
  open var color: UIColor?

  open var regex: String {
    NEMarkdownBold.regex
  }

  public init(font: UIFont? = nil, color: UIColor? = nil) {
    self.font = font?.bold()
    self.color = color
  }
}
