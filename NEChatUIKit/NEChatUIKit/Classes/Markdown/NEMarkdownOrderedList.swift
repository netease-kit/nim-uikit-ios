// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

/// 有序列表渲染 Element，支持多级缩进（`1.` `2.` 等数字序号）。
///
/// 支持语法：
/// ```
/// 1. 第一项
/// 2. 第二项
///    1. 嵌套第一项
/// ```
///
/// 渲染效果：保留原始序号，添加首行缩进与悬挂缩进，与 `NEMarkdownList` 无序列表风格一致。
open class NEMarkdownOrderedList: NEMarkdownLevelElement {
  // 匹配：可选前导空格（用于判断缩进级别）+ 数字 + 点 + 空格 + 内容
  // group(1)：前导空格（level 由空格数决定）
  // group(2)：数字序号（如 "1"、"2"）
  // group(3)：列表内容
  fileprivate static let regex = "^( {0,%@})(\\d+)\\.\\s+(.+)$"

  open var maxLevel: Int
  open var font: UIFont?
  open var color: UIColor?

  open var regex: String {
    let level: String = maxLevel > 0 ? "\(maxLevel)" : ""
    return String(format: NEMarkdownOrderedList.regex, level)
  }

  public init(font: UIFont? = nil, maxLevel: Int = 6, color: UIColor? = nil) {
    self.maxLevel = maxLevel
    self.font = font
    self.color = color
  }

  // MARK: - NEMarkdownLevelElement

  /// 将前导空格 + 序号替换为缩进后的 "序号. " 格式，并应用悬挂缩进段落样式。
  open func formatText(_ attributedString: NSMutableAttributedString,
                       range: NSRange,
                       level: Int) {
    // range 是 group(1)（前导空格），range 之后紧跟 group(2)（序号）
    // 取出原始序号文字（range 右侧的数字部分）
    let nsString = attributedString.string as NSString
    // 找到序号：在 range 结束位置开始，读取到 '.' 之前
    let afterIndent = range.location + range.length
    var dotPos = afterIndent
    while dotPos < nsString.length, nsString.character(at: dotPos) != 46 /* ASCII '.' */ {
      dotPos += 1
    }
    let numberStr = nsString.substring(with: NSRange(location: afterIndent, length: dotPos - afterIndent))

    // 根据缩进级别（每2个空格算一级）计算前置空格
    let indentLevel = max(1, level) // level 是前导空格数，最小为1
    let indentDepth = (indentLevel - 1) / 2 // 0-based depth
    let prefix = String(repeating: "  ", count: indentDepth)

    // 替换整个前缀区域（前导空格）为缩进 + 序号保留格式
    let replacement = "\(prefix)\(numberStr). "
    attributedString.replaceCharacters(in: range, with: replacement)

    // 计算悬挂缩进宽度
    let indentPt = CGFloat(8 + indentDepth * 16)
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.firstLineHeadIndent = indentPt
    paragraphStyle.headIndent = indentPt + 16
    paragraphStyle.paragraphSpacing = 4

    // 应用段落样式到已替换的前缀区域
    let newRange = NSRange(location: range.location, length: replacement.count)
    attributedString.addAttributes([.paragraphStyle: paragraphStyle], range: newRange)
  }

  // MARK: - NEMarkdownLevelElement match override

  //
  // 有序列表的正则分组与 NEMarkdownLevelElement 默认 match 不同：
  //   group(1) = 前导空格（level = 空格数）
  //   group(2) = 数字序号（不是内容！）
  //   group(3) = 内容
  // 需要覆写 match，把内容和前缀分别处理。

  public func match(_ match: NSTextCheckingResult,
                    attributedString: NSMutableAttributedString) {
    // group(3)：内容文字范围 —— 应用字体/颜色属性
    let contentRange = match.range(at: 3)
    addAttributes(attributedString, range: contentRange, level: 1)

    // group(1)：前导空格范围 —— 传给 formatText 做缩进处理
    let indentRange = match.range(at: 1)
    let level = indentRange.length + 1 // level = 空格数 + 1（最小为1）
    formatText(attributedString, range: indentRange, level: level)
  }
}
