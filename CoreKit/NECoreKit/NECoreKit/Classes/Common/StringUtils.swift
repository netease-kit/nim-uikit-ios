// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

/// 字符串处理封装
@objcMembers public class NEStringUtils: NSObject {
  /// 脱敏字符串，比如将 "appkey:123456789" 脱敏为 "appkey:123***789"
  /// - Parameters:
  ///   - string: 待脱敏的字符串
  ///   - sensitive: 脱敏关键字
  /// - Returns: 脱敏后的字符串
  public class func desensitize(string: String, sensitive: String) -> String {
    let length = sensitive.count
    if length < 3 {
      return string.replacingOccurrences(of: sensitive, with: "***")
    } else {
      let leave = length > 11 ? 4 : length / 3
      let template = around(string: sensitive, left: leave, right: leave, template: "*")
      return string.replacingOccurrences(of: sensitive, with: template)
    }
  }

  /// 脱敏字符串，比如将 "123456789" 脱敏为 "123***789"
  /// - Parameters:
  ///   - string: 待脱敏的字符串
  ///   - left: 左边显示几个字符
  ///   - right: 右边显示几个字符
  ///   - template: 用什么字符来脱敏，比如 "*"
  /// - Returns: 脱敏后的字符串
  public class func around(string: String, left: Int, right: Int, template: String) -> String {
    let length = string.count
    if length < left + right + 1 {
      return string
    }
    let regex = String(format: "(?<=\\w{%d})\\w(?=\\w{%d})", left, right)
    if let expression = try? NSRegularExpression(pattern: regex, options: .caseInsensitive) {
      return expression.stringByReplacingMatches(in: string, options: .reportProgress, range: NSRange(location: 0, length: length), withTemplate: template)
    }
    return string
  }
}
