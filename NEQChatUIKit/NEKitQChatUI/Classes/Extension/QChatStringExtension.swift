
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

extension String {
  // 计算文字size
  static func getTextRectSize(_ text: String, font: UIFont, size: CGSize) -> CGSize {
    let attributes = [NSAttributedString.Key.font: font]
    let option = NSStringDrawingOptions.usesLineFragmentOrigin
    let rect: CGRect = text.boundingRect(with: size, options: option,
                                         attributes: attributes, context: nil)
    return rect.size
  }

  static func stringFromDate(date: Date) -> String {
    let fmt = DateFormatter()
    if Calendar.current.isDateInToday(date) {
      fmt.dateFormat = "HH:mm"
    } else {
      if let firstDayYear = firstDayInYear() {
        let dur = date.timeIntervalSince(firstDayYear)
        if dur > 0 {
          fmt.dateFormat = "MM月dd日 HH:mm"
        } else {
          fmt.dateFormat = "yyyy年MM月dd日 HH:mm"
        }
      } else {
        fmt.dateFormat = "yyyy年MM月dd日 HH:mm"
      }
    }
    return fmt.string(from: date)
  }

  static func firstDayInYear() -> Date? {
    let format = DateFormatter()
    format.dateFormat = "yyyy-MM-dd"
    let year = Calendar.current.component(.year, from: Date())
    return format.date(from: "\(year)-01-01")
  }
}
