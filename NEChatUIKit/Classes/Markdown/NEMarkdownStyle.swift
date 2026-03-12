// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

/// Styling protocol for all NEMarkdownElements
public protocol NEMarkdownStyle {
  var font: UIFont? { get }
  var color: UIColor? { get }
  var attributes: [NSAttributedString.Key: AnyObject] { get }
}

public extension NEMarkdownStyle {
  var attributes: [NSAttributedString.Key: AnyObject] {
    var attributes = [NSAttributedString.Key: AnyObject]()
    if let font = font {
      attributes[NSAttributedString.Key.font] = font
    }
    if let color = color {
      attributes[NSAttributedString.Key.foregroundColor] = color
    }
    return attributes
  }
}
