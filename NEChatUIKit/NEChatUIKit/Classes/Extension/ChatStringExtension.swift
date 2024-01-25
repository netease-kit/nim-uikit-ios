
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

// 缓存的用于计算高度的Label
var tempLabelForCalc: UILabel = {
  let label = UILabel()
  label.numberOfLines = 0
  return label
}()

extension String {
  /// 计算 string 的 size
  static func getTextRectSize(_ text: String, font: UIFont, size: CGSize) -> CGSize {
    let attributes = [NSAttributedString.Key.font: font]
    let option = NSStringDrawingOptions.usesLineFragmentOrigin
    let rect: CGRect = text.boundingRect(with: size, options: option,
                                         attributes: attributes, context: nil)
    return CGSize(width: ceil(rect.width), height: ceil(rect.height))
  }

  /// 计算 string 的行数，使用 font 的 lineHeight
  static func calculateMaxLines(width: CGFloat, string: String?, font: UIFont) -> Int {
    let maxSize = CGSize(width: width, height: CGFloat(Float.infinity))
    let charSize = font.lineHeight
    let textSize = string?.finalSize(font, maxSize) ?? .zero
    let lines = Int(textSize.height / charSize)
    return lines
  }

  /// 计算 label 的行数，使用 font 的 lineHeight
  static func calculateMaxLines(width: CGFloat, attributeString: NSAttributedString?, font: UIFont) -> Int {
    let maxSize = CGSize(width: width, height: CGFloat(Float.infinity))
    let charSize = font.lineHeight
    let textSize = attributeString?.finalSize(font, maxSize) ?? .zero
    let lines = Int(textSize.height / charSize)
    return lines
  }

  static func stringFromDate(date: Date) -> String {
    let fmt = DateFormatter()
    if Calendar.current.isDateInToday(date) {
      fmt.dateFormat = "HH:mm"
    } else {
      if let firstDayYear = firstDayInYear() {
        let dur = date.timeIntervalSince(firstDayYear)
        if dur > 0 {
          fmt.dateFormat = chatLocalizable("mdhm")
        } else {
          fmt.dateFormat = chatLocalizable("ymdhm")
        }
      } else {
        fmt.dateFormat = chatLocalizable("ymdhm")
      }
    }
    return fmt.string(from: date)
  }

  static func date24To12(_ string: String?) -> String {
    guard let str = string else {
      return ""
    }
    let fmt = DateFormatter()
    fmt.dateFormat = "HH:mm"
    if let date = fmt.date(from: str) {
      fmt.dateFormat = "a hh:mm"
      return fmt.string(from: date)
    }
    fmt.dateFormat = chatLocalizable("mdhm")
    if let date = fmt.date(from: str) {
      fmt.dateFormat = "MM月dd日 a hh:mm"
      return fmt.string(from: date)
    }
    fmt.dateFormat = chatLocalizable("ymdhm")
    if let date = fmt.date(from: str) {
      fmt.dateFormat = "yyyy年MM月dd日 a hh:mm"
      return fmt.string(from: date)
    }
    return ""
  }

  static func firstDayInYear() -> Date? {
    let format = DateFormatter()
    format.dateFormat = "yyyy-MM-dd"
    let year = Calendar.current.component(.year, from: Date())
    return format.date(from: "\(year)-01-01")
  }
}
