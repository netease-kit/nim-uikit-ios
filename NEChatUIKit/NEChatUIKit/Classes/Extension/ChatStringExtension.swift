
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

extension String {
  /// 计算 string 的行数，使用 font 的 lineHeight
  static func calculateMaxLines(width: CGFloat, string: String?, font: UIFont) -> Int {
    let maxSize = CGSize(width: width, height: CGFloat(Float.infinity))
    let charSize = font.lineHeight
    let textSize = String.getRealSize(string, font, maxSize)
    let lines = Int(textSize.height / charSize)
    return lines
  }

  /// 计算 label 的行数，使用 font 的 lineHeight
  static func calculateMaxLines(width: CGFloat, attributeString: NSAttributedString?, font: UIFont) -> Int {
    let maxSize = CGSize(width: width, height: CGFloat(Float.infinity))
    let charSize = font.lineHeight
    let textSize = NSAttributedString.getRealSize(attributeString, font, maxSize)
    let lines = Int(textSize.height / charSize)
    return lines
  }
}
