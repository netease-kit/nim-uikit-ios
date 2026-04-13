// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// Markdown 表格解析（GFM 表格语法）
///
/// 采用**以分隔行为锚点**的扫描策略，兼容 AI 流式回复中常见的非标准格式：
///   - 标准格式：表头行 → 分隔行 → 数据行
///   - 非标准格式：`## 标题| 表头 |` 和分隔行在不同行
///   - 无表头格式：直接 分隔行 → 数据行
// MARK: - 内部辅助类型

/// 表格区间描述（以分隔行为锚点）
struct NEMarkdownTableRegion {
  var headerLineIndex: Int       // -1 = 无独立表头行
  var headerCellsFromTail: [String] // 从混合行尾部提取的表头（可能为空）
  var separatorLineIndex: Int
  var dataLineIndices: [Int]
}

open class NEMarkdownTable: NEMarkdownElement {
  // MARK: - NEMarkdownElement 协议（保留兼容性，实际逻辑在 preprocess）

  public var regex: String { "(?!x)x" } // 永不匹配
  public func regularExpression() throws -> NSRegularExpression {
    try NSRegularExpression(pattern: regex)
  }

  public func match(_ match: NSTextCheckingResult,
                    attributedString: NSMutableAttributedString) {}

  // MARK: - 样式配置

  open var maxWidth: CGFloat = UIScreen.main.bounds.width - 72
  open var headerFont: UIFont = .boldSystemFont(ofSize: 14)
  open var cellFont: UIFont = .systemFont(ofSize: 14)
  open var cellPadding: CGFloat = 8
  open var borderWidth: CGFloat = 0.5

  public init(maxWidth: CGFloat = UIScreen.main.bounds.width - 72) {
    self.maxWidth = maxWidth
  }

  // MARK: - 纯文本预处理（被 NEMarkdownParser 在所有 element 之前调用）

  /// 扫描原始 Markdown 字符串，将 GFM 表格块替换为 NSTextAttachment。
  /// 非表格内容保留为纯文本，由后续 Element 继续处理。
  public func preprocess(_ rawText: String,
                         font: UIFont,
                         color: UIColor) -> NSAttributedString {
    let textAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]

    // ── 第一步：以分隔行为锚点，收集所有表格区间 ──
    let lines = rawText.components(separatedBy: "\n")
    var regions = [NEMarkdownTableRegion]()
    var coveredLines = Set<Int>() // 已归属某个表格区间的行

    for (i, line) in lines.enumerated() {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      guard isSeparatorLine(trimmed) else { continue }
      guard !coveredLines.contains(i) else { continue }

      // 找到分隔行，向前找表头行
      var headerLineIndex = -1
      var headerCellsFromTail = [String]()
      if i > 0 {
        let prevTrimmed = lines[i - 1].trimmingCharacters(in: .whitespaces)
        if prevTrimmed.hasPrefix("|") {
          // 完整的独立表头行
          headerLineIndex = i - 1
        } else if prevTrimmed.contains("|") {
          // 混合行（如 "## 标题 | 列A | 列B |"）—— 提取最后一个完整 | ... | 段
          headerCellsFromTail = extractTrailingTableCells(from: prevTrimmed)
        }
      }

      // 向后收集数据行
      var dataIndices = [Int]()
      var j = i + 1
      while j < lines.count {
        let dataLine = lines[j].trimmingCharacters(in: .whitespaces)
        // 数据行：以 | 开头，且不是另一个分隔行
        if dataLine.hasPrefix("|"), !isSeparatorLine(dataLine) {
          dataIndices.append(j)
          j += 1
        } else {
          break
        }
      }

      let region = NEMarkdownTableRegion(
        headerLineIndex: headerLineIndex,
        headerCellsFromTail: headerCellsFromTail,
        separatorLineIndex: i,
        dataLineIndices: dataIndices
      )
      regions.append(region)

      // 标记已覆盖行
      if headerLineIndex >= 0 { coveredLines.insert(headerLineIndex) }
      coveredLines.insert(i)
      dataIndices.forEach { coveredLines.insert($0) }
    }

    // ── 第二步：逐行重建，把表格行替换为 Attachment ──
    let result = NSMutableAttributedString()
    var lineIdx = 0
    // 按表格区间排序（按分隔行位置）
    let sortedRegions = regions.sorted { $0.separatorLineIndex < $1.separatorLineIndex }
    var regionIter = sortedRegions.makeIterator()
    var nextRegion = regionIter.next()

    while lineIdx < lines.count {
      // 判断当前行是否属于某个表格区间
      if let region = nextRegion {
        // 跳过：当前行是表格区间内的行（不含表头行，表头行原文内容保留，只截断末尾的表格部分）
        if lineIdx == region.separatorLineIndex || region.dataLineIndices.contains(lineIdx) {
          // 当分隔行是第一个属于此区间的行时，插入 Attachment
          if lineIdx == region.separatorLineIndex {
            if let tableData = buildTableData(region: region, lines: lines) {
              if result.length > 0 { result.append(NSAttributedString(string: "\n", attributes: textAttrs)) }
              let attachment = buildAttachment(data: tableData)
              result.append(NSAttributedString(attachment: attachment))
              result.append(NSAttributedString(string: "\n", attributes: textAttrs))
            }
            // 跳过整个区间（包括数据行）
            let maxLine = (region.dataLineIndices.max() ?? region.separatorLineIndex)
            lineIdx = maxLine + 1
            nextRegion = regionIter.next()
            continue
          }
          // 不应走到这里（数据行已被上面跳过）
          lineIdx += 1
          continue
        }

        // 如果当前行是混合行（表头被嵌入其中）：截断末尾的 | ... | 部分后再追加
        if lineIdx == region.headerLineIndex {
          let trimmed = lines[lineIdx].trimmingCharacters(in: .whitespaces)
          if trimmed.hasPrefix("|") {
            // 独立表头行：跳过（已在分隔行处理时包含进表格）
            lineIdx += 1
            continue
          } else if trimmed.contains("|") {
            // 混合行：保留 | 之前的文本
            let beforePipe = trimmed.components(separatedBy: "|").first?.trimmingCharacters(in: .whitespaces) ?? trimmed
            if !beforePipe.isEmpty {
              result.append(NSAttributedString(string: beforePipe + "\n", attributes: textAttrs))
            }
            lineIdx += 1
            continue
          }
        }
      }

      // 普通行
      let suffix = lineIdx < lines.count - 1 ? "\n" : ""
      result.append(NSAttributedString(string: lines[lineIdx] + suffix, attributes: textAttrs))
      lineIdx += 1
    }

    return result
  }

  // MARK: - 辅助：表格识别

  /// 判断一行是否为 GFM 分隔行（仅含 `| : - 空格 制表符`，且含至少一个 `-`）
  private func isSeparatorLine(_ line: String) -> Bool {
    guard line.hasPrefix("|"), line.contains("-") else { return false }
    let allowed = CharacterSet(charactersIn: "|:- \t")
    return line.unicodeScalars.allSatisfy { allowed.contains($0) }
  }

  /// 从混合行（如 `## 标题 | 列A | 列B |`）的末尾提取表格单元格
  private func extractTrailingTableCells(from line: String) -> [String] {
    // 找到第一个完整的 | cell | 模式的起始位置
    guard let firstPipe = line.firstIndex(of: "|") else { return [] }
    let tableSection = String(line[firstPipe...])
    return parseCells(from: tableSection)
  }

  // MARK: - 辅助：数据提取

  private func buildTableData(region: NEMarkdownTableRegion,
                              lines: [String]) -> NEMarkdownTableData? {
    let sepLine = lines[region.separatorLineIndex].trimmingCharacters(in: .whitespaces)
    let colCount = parseCellCount(from: sepLine)
    guard colCount > 0 else { return nil }
    let alignments = parseAlignments(from: sepLine, count: colCount)

    // 确定表头
    var headers: [String]
    if region.headerLineIndex >= 0 {
      let hLine = lines[region.headerLineIndex].trimmingCharacters(in: .whitespaces)
      headers = parseCells(from: hLine)
    } else if !region.headerCellsFromTail.isEmpty {
      headers = region.headerCellsFromTail
    } else {
      headers = (1 ... colCount).map { "列\($0)" }
    }
    // 对齐列数
    while headers.count < colCount { headers.append("") }
    if headers.count > colCount { headers = Array(headers.prefix(colCount)) }

    let rows = region.dataLineIndices.map { idx -> [String] in
      var cells = parseCells(from: lines[idx].trimmingCharacters(in: .whitespaces))
      while cells.count < colCount { cells.append("") }
      return Array(cells.prefix(colCount))
    }

    return NEMarkdownTableData(headers: headers, alignments: alignments, rows: rows)
  }

  /// 提取单元格内容（去首尾 `|`，按 `|` 分割并 trim）
  private func parseCells(from line: String) -> [String] {
    var s = line.trimmingCharacters(in: .whitespaces)
    if s.hasPrefix("|") { s = String(s.dropFirst()) }
    if s.hasSuffix("|") { s = String(s.dropLast()) }
    return s.components(separatedBy: "|")
      .map { $0.trimmingCharacters(in: .whitespaces) }
  }

  /// 计算分隔行的列数
  private func parseCellCount(from sep: String) -> Int {
    var s = sep
    if s.hasPrefix("|") { s = String(s.dropFirst()) }
    if s.hasSuffix("|") { s = String(s.dropLast()) }
    return s.components(separatedBy: "|").count
  }

  /// 解析对齐方式（`:---` left，`:---:` center，`---:` right）
  private func parseAlignments(from sep: String, count: Int) -> [NEMarkdownTableAlignment] {
    var s = sep
    if s.hasPrefix("|") { s = String(s.dropFirst()) }
    if s.hasSuffix("|") { s = String(s.dropLast()) }
    var result = s.components(separatedBy: "|").map { cell -> NEMarkdownTableAlignment in
      let c = cell.trimmingCharacters(in: .whitespaces)
      let l = c.hasPrefix(":")
      let r = c.hasSuffix(":")
      if l && r { return .center }
      if r { return .right }
      return .left
    }
    while result.count < count { result.append(.left) }
    return Array(result.prefix(count))
  }

  // MARK: - Attachment 构建

  private func buildAttachment(data: NEMarkdownTableData) -> NSTextAttachment {
    let tableHeight = NEMarkdownTableView.calculateHeight(
      data: data, maxWidth: maxWidth,
      headerFont: headerFont, cellFont: cellFont,
      cellPadding: cellPadding, borderWidth: borderWidth
    )
    let size = CGSize(width: maxWidth, height: max(tableHeight, 1))
    let tableView = NEMarkdownTableView(data: data, maxWidth: maxWidth)
    tableView.headerFont = headerFont
    tableView.cellFont = cellFont
    tableView.cellPadding = cellPadding
    tableView.borderWidth = borderWidth
    return NEMarkdownTableAttachment(tableView: tableView, size: size)
  }
}