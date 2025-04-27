// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

extension String {
  /// Converts each character to its UTF16 form in hexadecimal value (e.g. "H" -> "0048")
  func escapeUTF16() -> String {
    Array(utf16).map {
      String(format: "%04x", $0)
    }.reduce("") {
      $0 + $1
    }
  }

  /// Converts each 4 digit characters to its String form  (e.g. "0048" -> "H")
  func unescapeUTF16() -> String? {
    // This is an hot fix for the crash when a regular string is passed here.
    guard count % 4 == 0 else {
      return self
    }

    var utf16Array = [UInt16]()
    for item in stride(from: 0, to: count, by: 4) {
      let startIndex = index(startIndex, offsetBy: item)
      let endIndex = index(self.startIndex, offsetBy: item + 4)
      let hex4 = String(self[startIndex ..< endIndex])
      if let utf16 = UInt16(hex4, radix: 16) {
        utf16Array.append(utf16)
      }
    }

    return String(utf16CodeUnits: utf16Array, count: utf16Array.count)
  }
}
