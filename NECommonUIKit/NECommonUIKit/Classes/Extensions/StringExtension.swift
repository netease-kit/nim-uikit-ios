
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public extension String {
  static func stringFromTimeInterval(time: TimeInterval) -> String {
    if time <= 0 {
      return ""
    }

    let targetDate = Date(timeIntervalSince1970: time)
    let fmt = DateFormatter()

    if targetDate.isToday() {
      fmt.dateFormat = commonLocalizable("hm")
      return fmt.string(from: targetDate)

    } else {
      if targetDate.isThisYear() {
        fmt.dateFormat = commonLocalizable("mdhm")
        return fmt.string(from: targetDate)

      } else {
        fmt.dateFormat = commonLocalizable("ymdhm")
        return fmt.string(from: targetDate)
      }
    }
  }

  static func stringFromDate(date: Date) -> String {
    let fmt = DateFormatter()
    if Calendar.current.isDateInToday(date) {
      fmt.dateFormat = commonLocalizable("hm")
    } else {
      if let firstDayYear = firstDayInYear() {
        let dur = date.timeIntervalSince(firstDayYear)
        if dur > 0 {
          fmt.dateFormat = commonLocalizable("mdhm")
        } else {
          fmt.dateFormat = commonLocalizable("ymdhm")
        }
      } else {
        fmt.dateFormat = commonLocalizable("ymdhm")
      }
    }
    return fmt.string(from: date)
  }

  static func date24To12(_ string: String?) -> String {
    guard let str = string else {
      return ""
    }
    let fmt = DateFormatter()
    fmt.dateFormat = commonLocalizable("hm")
    if let date = fmt.date(from: str) {
      fmt.dateFormat = commonLocalizable("ahm")
      return fmt.string(from: date)
    }
    fmt.dateFormat = commonLocalizable("mdhm")
    if let date = fmt.date(from: str) {
      fmt.dateFormat = commonLocalizable("amdhm")
      return fmt.string(from: date)
    }
    fmt.dateFormat = commonLocalizable("ymdhm")
    if let date = fmt.date(from: str) {
      fmt.dateFormat = commonLocalizable("aymdhm")
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
