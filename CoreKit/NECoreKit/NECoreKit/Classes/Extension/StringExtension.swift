
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
extension String {
  /// Inital of string, return "#" if the initials are not within A - Z
  /// - Returns: Inital Letter of string
  public func initalLetter() -> String? {
    if isEmpty {
      return nil
    }
    if isChinese() {
      let string = transformToLatin()
      let ch = string[string.startIndex]
      return String(ch).uppercased()
    } else {
      let ch = self[startIndex]
      return String(ch).uppercased()
    }
  }

  func isChinese() -> Bool {
    for ch in unicodeScalars {
      // Chinese：0x4e00 ~ 0x9fff
      if ch.value > 0x4E00, ch.value < 0x9FFF {
        return true
      }
    }
    return false
  }

  func transformToLatin() -> String {
    let stringRef = NSMutableString(string: self) as CFMutableString
    CFStringTransform(stringRef, nil, kCFStringTransformToLatin, false)
    CFStringTransform(stringRef, nil, kCFStringTransformStripCombiningMarks, false)
    let string = stringRef as String
    return string.trimmingCharacters(in: .whitespaces)
  }

  public var isBlank: Bool {
    /// 字符串中的所有字符都符合block中的条件，则返回true
    let _blank = allSatisfy {
      let _blank = $0.isWhitespace
      print("字符：\($0) \(_blank)")
      return _blank
    }
    return _blank
  }

  /// 通过裁剪字符串中的空格和换行符，将得到的结过进行isEmpty
  var isReBlank: Bool {
    let str = trimmingCharacters(in: .whitespacesAndNewlines)
    return str.isEmpty
  }

  /// 指定关键词高亮
  /// - Parameter keyWords: 关键词
  /// - Parameter color: 高亮颜色
  public func highlight(keyWords: String?, highlightColor color: UIColor) -> NSMutableAttributedString {
    let string: String = self
    let attributeString = NSMutableAttributedString(string: string)
    guard let keyWords = keyWords else { return attributeString }
    let attribute: [NSAttributedString.Key: Any] = [.foregroundColor: color]
    // 需要改变的文本
    let ranges = ranges(of: keyWords, options: .caseInsensitive)
    for range in ranges where range.location + range.length <= string.count {
      attributeString.addAttributes(attribute, range: range)
    }
    return attributeString
  }

  /// 查找字符串中子字符串的NSRange
  /// - Parameters:
  ///   - substring: 子字符串
  ///   - options: 匹配选项
  ///   - locale: 本地化
  /// - Returns: 子字符串的NSRange数组
  func ranges(of substring: String, options: CompareOptions = [], locale: Locale? = nil) -> [NSRange] {
    var ranges: [Range<Index>] = []
    while let range = range(of: substring, options: options, range: (ranges.last?.upperBound ?? startIndex) ..< endIndex, locale: locale) {
      ranges.append(range)
    }
    // [range]转换为[NSRange]返回
    return ranges.compactMap { NSRange($0, in: self) }
  }

  /// range转换为NSRange
  func toNSRange(from range: Range<String.Index>) -> NSRange {
    NSRange(range, in: self)
  }
}
