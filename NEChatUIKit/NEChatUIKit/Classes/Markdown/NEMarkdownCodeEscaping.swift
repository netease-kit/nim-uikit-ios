// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

open class NEMarkdownCodeEscaping: NEMarkdownElement {
  // 两个分支合并为一个正则，不使用 .dotMatchesLineSeparators：
  // 分支1 — 多反引号(2+)：内容可跨行（用 [\s\S]+? 匹配包含换行的任意字符）
  //         groups: (2)=backticks  (3)=content  (4)=closing backticks
  // 分支2 — 单反引号：内容不含换行和反引号（[^\n`]+），防止跨行误吞 Markdown 语法
  //         groups: (5)=backtick   (6)=content  (7)=closing backtick
  fileprivate static let regex = "(\\s+|^)(?<!\\\\)(?:\\\\\\\\)*+(?:(\\`{2,})([\\s\\S]+?)(\\2)|(\\`)([^\\n`]+)(\\5))"

  open var regex: String {
    NEMarkdownCodeEscaping.regex
  }

  open func regularExpression() throws -> NSRegularExpression {
    // 不使用 .dotMatchesLineSeparators，跨行逻辑已在正则内部通过 [\s\S] 处理
    try NSRegularExpression(pattern: regex, options: [])
  }

  open func match(_ match: NSTextCheckingResult, attributedString: NSMutableAttributedString) {
    // 根据匹配的分支确定 content 所在的 group 索引
    // 分支1（多反引号）：group 3
    // 分支2（单反引号）：group 6
    let contentGroupIndex: Int
    if match.numberOfRanges > 2, match.range(at: 2).location != NSNotFound {
      contentGroupIndex = 3
    } else {
      contentGroupIndex = 6
    }

    let range = match.range(at: contentGroupIndex)
    // escaping all characters
    let matchString = attributedString.attributedSubstring(from: range).string
    let escapedString = [UInt16](matchString.utf16)
      .map { (value: UInt16) -> String in String(format: "%04x", value) }
      .reduce("") { (string: String, character: String) -> String in
        "\(string)\(character)"
      }
    attributedString.replaceCharacters(in: range, with: escapedString)
  }
}
