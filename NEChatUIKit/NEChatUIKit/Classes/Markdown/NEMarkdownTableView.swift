// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

// MARK: - 数据模型

/// Markdown 表格对齐方式
public enum NEMarkdownTableAlignment {
  case left, center, right
}

/// 表格的解析结果（行优先存储）
public struct NEMarkdownTableData {
  /// 表头行文字（已 trim）
  public let headers: [String]
  /// 每列的对齐方式
  public let alignments: [NEMarkdownTableAlignment]
  /// 数据行（每行是一组 cell 文字，已 trim）
  public let rows: [[String]]

  /// 列数
  public var columnCount: Int { headers.count }
}

// MARK: - 渲染视图

/// 将一个 `NEMarkdownTableData` 渲染为网格表格的 UIView。
/// 布局采用「等宽列 + 自适应行高」方案：
///   - 列宽 = (totalWidth - borderWidth) / columnCount，最小 60 pt
///   - 单元格内文字自动换行，行高由最高的那个单元格决定
///   - 表头行背景色与数据行交替区分
open class NEMarkdownTableView: UIView {
  // MARK: - 样式可配置项

  /// 表格最大宽度（调用者传入，默认为屏幕宽度 - 32）
  open var maxWidth: CGFloat = UIScreen.main.bounds.width - 32

  open var headerBackgroundColor: UIColor = .init(red: 0.90, green: 0.92, blue: 0.96, alpha: 1)
  open var oddRowBackgroundColor: UIColor = .init(red: 0.98, green: 0.98, blue: 0.98, alpha: 1)
  open var evenRowBackgroundColor: UIColor = .white
  open var borderColor: UIColor = .init(red: 0.80, green: 0.82, blue: 0.86, alpha: 1)
  open var borderWidth: CGFloat = 0.5
  open var cellPadding: CGFloat = 8
  open var headerFont: UIFont = .boldSystemFont(ofSize: 14)
  open var cellFont: UIFont = .systemFont(ofSize: 14)
  open var headerTextColor: UIColor = .black
  open var cellTextColor: UIColor = .init(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)

  // MARK: - 私有属性

  private var tableData: NEMarkdownTableData?

  // MARK: - 初始化

  public init(data: NEMarkdownTableData, maxWidth: CGFloat) {
    super.init(frame: .zero)
    self.maxWidth = maxWidth
    tableData = data
    setupTable()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  // MARK: - 构建表格

  private func setupTable() {
    guard let data = tableData else { return }
    backgroundColor = .clear

    let colCount = data.columnCount
    guard colCount > 0 else { return }

    // 计算列宽：等分最大宽度
    let totalBorderWidth = borderWidth * CGFloat(colCount + 1)
    let colWidth = max(60, (maxWidth - totalBorderWidth) / CGFloat(colCount))
    let tableWidth = colWidth * CGFloat(colCount) + totalBorderWidth

    var currentY: CGFloat = 0

    // ── 渲染一行（isHeader 决定字体/背景）──
    func renderRow(_ cells: [String], isHeader: Bool, rowIndex: Int) {
      let font = isHeader ? headerFont : cellFont
      let textColor = isHeader ? headerTextColor : cellTextColor
      let bgColor: UIColor
      if isHeader {
        bgColor = headerBackgroundColor
      } else {
        bgColor = rowIndex % 2 == 0 ? oddRowBackgroundColor : evenRowBackgroundColor
      }

      // 先计算本行的最大高度
      var maxCellHeight: CGFloat = 0
      var cellHeights = [CGFloat]()
      for (colIdx, text) in cells.enumerated() {
        let alignment = colIdx < data.alignments.count ? data.alignments[colIdx] : .left
        let cellSize = cellTextSize(text, font: font, colWidth: colWidth, alignment: alignment)
        cellHeights.append(cellSize.height)
        maxCellHeight = max(maxCellHeight, cellSize.height)
      }
      let rowHeight = maxCellHeight + cellPadding * 2

      // 绘制行背景
      let rowBg = UIView(frame: CGRect(x: 0, y: currentY, width: tableWidth, height: rowHeight))
      rowBg.backgroundColor = bgColor
      addSubview(rowBg)

      // 绘制顶部边框线
      let topLine = UIView(frame: CGRect(x: 0, y: currentY, width: tableWidth, height: borderWidth))
      topLine.backgroundColor = borderColor
      addSubview(topLine)

      // 绘制每个单元格
      var currentX: CGFloat = 0
      // 左边框
      let leftBorder = UIView(frame: CGRect(x: 0, y: currentY, width: borderWidth, height: rowHeight))
      leftBorder.backgroundColor = borderColor
      addSubview(leftBorder)
      currentX += borderWidth

      for (colIdx, text) in cells.enumerated() {
        let alignment = colIdx < data.alignments.count ? data.alignments[colIdx] : .left
        let cellLabel = makeCellLabel(text, font: font, textColor: textColor,
                                      colWidth: colWidth, alignment: alignment)
        cellLabel.frame = CGRect(x: currentX + cellPadding,
                                 y: currentY + cellPadding,
                                 width: colWidth - cellPadding * 2,
                                 height: rowHeight - cellPadding * 2)
        addSubview(cellLabel)
        currentX += colWidth

        // 右边框
        let rightBorder = UIView(frame: CGRect(x: currentX, y: currentY, width: borderWidth, height: rowHeight))
        rightBorder.backgroundColor = borderColor
        addSubview(rightBorder)
        currentX += borderWidth
      }

      currentY += rowHeight
    }

    // 渲染表头
    renderRow(data.headers, isHeader: true, rowIndex: -1)

    // 渲染数据行
    for (i, row) in data.rows.enumerated() {
      // 补齐/截断列数
      var cells = row
      while cells.count < colCount {
        cells.append("")
      }
      if cells.count > colCount { cells = Array(cells.prefix(colCount)) }
      renderRow(cells, isHeader: false, rowIndex: i)
    }

    // 底部边框
    let bottomLine = UIView(frame: CGRect(x: 0, y: currentY, width: tableWidth, height: borderWidth))
    bottomLine.backgroundColor = borderColor
    addSubview(bottomLine)

    currentY += borderWidth

    // 设置自身尺寸
    frame = CGRect(origin: .zero, size: CGSize(width: tableWidth, height: currentY))
  }

  // MARK: - 辅助

  private func makeCellLabel(_ text: String, font: UIFont, textColor: UIColor,
                             colWidth: CGFloat, alignment: NEMarkdownTableAlignment) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = font
    label.textColor = textColor
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    switch alignment {
    case .left: label.textAlignment = .left
    case .center: label.textAlignment = .center
    case .right: label.textAlignment = .right
    }
    return label
  }

  private func cellTextSize(_ text: String, font: UIFont, colWidth: CGFloat,
                            alignment: NEMarkdownTableAlignment) -> CGSize {
    let availableWidth = colWidth - cellPadding * 2
    let constraintSize = CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude)
    let boundingRect = (text as NSString).boundingRect(
      with: constraintSize,
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: [.font: font],
      context: nil
    )
    return CGSize(width: availableWidth, height: ceil(boundingRect.height))
  }

  // MARK: - 计算表格所需高度（静态方法，供外部预计算）

  /// 在给定最大宽度和样式参数下，提前计算表格总高度。
  public static func calculateHeight(data: NEMarkdownTableData,
                                     maxWidth: CGFloat,
                                     headerFont: UIFont = .boldSystemFont(ofSize: 14),
                                     cellFont: UIFont = .systemFont(ofSize: 14),
                                     cellPadding: CGFloat = 8,
                                     borderWidth: CGFloat = 0.5) -> CGFloat {
    let colCount = data.columnCount
    guard colCount > 0 else { return 0 }

    let totalBorderWidth = borderWidth * CGFloat(colCount + 1)
    let colWidth = max(60, (maxWidth - totalBorderWidth) / CGFloat(colCount))

    var totalHeight: CGFloat = 0

    func rowHeight(cells: [String], font: UIFont) -> CGFloat {
      var maxH: CGFloat = 0
      let available = colWidth - cellPadding * 2
      for text in cells {
        let rect = (text as NSString).boundingRect(
          with: CGSize(width: available, height: .greatestFiniteMagnitude),
          options: [.usesLineFragmentOrigin, .usesFontLeading],
          attributes: [.font: font],
          context: nil
        )
        maxH = max(maxH, ceil(rect.height))
      }
      return maxH + cellPadding * 2
    }

    totalHeight += rowHeight(cells: data.headers, font: headerFont) + borderWidth
    for row in data.rows {
      var cells = row
      while cells.count < colCount {
        cells.append("")
      }
      totalHeight += rowHeight(cells: Array(cells.prefix(colCount)), font: cellFont) + borderWidth
    }
    totalHeight += borderWidth // 底部边框
    return totalHeight
  }
}
