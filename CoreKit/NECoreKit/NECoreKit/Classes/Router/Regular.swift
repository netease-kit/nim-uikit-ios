
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

/// Regular matching result
public struct RegularResult {
  fileprivate var _isMatch: Bool = false
  var isMatch: Bool { _isMatch }
  var params = [String: String]()
}

private enum PatternKeys {
  /// match :xxxx(xx)、:xxxx
  static let param: String = ":[a-z0-9A-Z-_][^/]+"
  /// match :xxxx
  static let paramName: String = ":[a-z0-9A-Z-_]+"
  /// match (xxx)
  static let paramMatch: String = "([^/]+)"
}

public class Regular: NSRegularExpression {
  var transformPattern: String?
  var paramNames = [String]()
  override public init(pattern: String, options: NSRegularExpression.Options = []) throws {
    let transformPattern = Regular.transform(from: pattern)
    try super.init(pattern: transformPattern, options: options)
    self.transformPattern = transformPattern
    paramNames = Self.paramNames(pattern)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @discardableResult
  public static func regular(with pattern: String) -> Regular? {
    do {
      return try Regular(pattern: pattern, options: .caseInsensitive)
    } catch {
      return nil
    }
  }

  // MARK: - ------------ Public method --------------------

  public func result(with string: String?) -> RegularResult {
    guard let string = string else { return RegularResult() }
    let array = matches(
      in: string,
      options: .reportProgress,
      range: NSRange(location: 0, length: string.count)
    )
    guard array.count > 0 else { return RegularResult() }

    var result = RegularResult()
    result._isMatch = true
    var dic = [String: String]()
    for check in array {
      var k = 0
      for index in 1 ..< check.numberOfRanges {
        let range: NSRange = check.range(at: index)
        if check.range(at: index).length == 0 { continue }
        if string[string.toRange(range)!].contains("://") { continue }
        let paramName = paramNames[k]
        let paramValue = String(string[string.toRange(range)!])
        dic[paramName] = paramValue
        k += 1
      }
    }
    result.params = dic
    return result
  }

  static func match(_ expression: String, original: String) -> [String] {
    do {
      let regularExp = try NSRegularExpression(pattern: expression, options: .caseInsensitive)
      let results = regularExp.matches(
        in: original,
        options: .reportProgress,
        range: NSRange(location: 0, length: original.count)
      )
      return results.map {
        String(original[original.toRange($0.range)!])
      }
    } catch {
      return []
    }
  }

  // MARK: - ------------ Private method --------------------

  static func transform(from pattern: String?) -> String {
    guard var pattern = pattern else { return "" }
    // 获取 :xxx() 部分
    let paramPatterns = Self.paramStrings(pattern)
    do {
      let expression = try NSRegularExpression(
        pattern: PatternKeys.paramName,
        options: .caseInsensitive
      )
      /*
       * 实例：user/login/:account/:password([a-z0-9A-Z]+)
       *替换后：user/login/([^/]+)/([a-z0-9A-Z]+)
       */
      for paramPattern in paramPatterns {
        var patternStr = paramPattern
        if let result = expression.matches(
          in: paramPattern,
          options: .reportProgress,
          range: NSRange(location: 0, length: paramPattern.count)
        ).first {
          let paramName = String(paramPattern[patternStr.toRange(result.range)!])
          patternStr = patternStr.replacingOccurrences(of: paramName, with: "")
        }
        // 替换之后 如果为空字符串，直接改为默认的正则
        if patternStr.count == 0 { patternStr = PatternKeys.paramMatch }
        pattern = pattern.replacingOccurrences(of: paramPattern, with: patternStr)
      }
      // 添加 正则的 ^$
      if pattern.count > 0, pattern[pattern.startIndex] == "/" { pattern = "^" + pattern }
      pattern += "$"
      return pattern
    } catch {
      return ""
    }
  }

  static func paramNames(_ pattern: String?) -> [String] {
    guard let pattern = pattern else { return [] }
    do {
      let expression = try NSRegularExpression(
        pattern: PatternKeys.paramName,
        options: .caseInsensitive
      )
      let paramPatterns = Self.paramStrings(pattern)
      return paramPatterns.map { string -> String in
        let paramNamesResult = expression.matches(
          in: string,
          options: .reportProgress,
          range: NSRange(location: 0, length: string.count)
        ).first
        if let result = paramNamesResult {
          let paramName = String(string[string.toRange(result.range)!])
          return paramName.replacingOccurrences(of: ":", with: "")
        } else { return "" }
      }
    } catch {
      return []
    }
  }

  static func paramStrings(_ pattern: String?) -> [String] {
    guard let pattern = pattern else { return [] }
    do {
      let expression = try NSRegularExpression(
        pattern: PatternKeys.param,
        options: .caseInsensitive
      )
      let matchs = expression.matches(
        in: pattern,
        options: .reportProgress,
        range: NSRange(location: 0, length: pattern.count)
      )
      return matchs.map { (pattern as NSString).substring(with: $0.range) }
    } catch {
      return []
    }
  }
}

private extension String {
  func toNSRange(_ range: Range<String.Index>) -> NSRange {
    guard let from = range.lowerBound.samePosition(in: utf16),
          let to = range.upperBound.samePosition(in: utf16) else {
      return NSMakeRange(0, 0)
    }
    return NSMakeRange(
      utf16.distance(from: utf16.startIndex, to: from),
      utf16.distance(from: from, to: to)
    )
  }

  func toRange(_ range: NSRange) -> Range<String.Index>? {
    guard let from16 = utf16.index(
      utf16.startIndex,
      offsetBy: range.location,
      limitedBy: utf16.endIndex
    ) else { return nil }
    guard let to16 = utf16.index(from16, offsetBy: range.length, limitedBy: utf16.endIndex)
    else { return nil }
    guard let from = String.Index(from16, within: self) else { return nil }
    guard let to = String.Index(to16, within: self) else { return nil }
    return from ..< to
  }
}
