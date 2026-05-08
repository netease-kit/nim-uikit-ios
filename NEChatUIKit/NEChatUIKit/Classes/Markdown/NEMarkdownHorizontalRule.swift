// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// 分隔线渲染 Element。
///
/// 支持标准 GFM 分隔线语法：
/// ```
/// ---
/// ***
/// ___
/// - - -
/// * * *
/// ```
/// （单独一行，由 3 个或以上 `-` `*` `_` 组成，允许中间有空格）
///
/// 渲染效果：将分隔线替换为一行视觉横线。
/// 使用自定义 `NSTextAttachment`，在 `attachmentBounds` 中根据
/// `proposedLineFragment` 自适应气泡宽度，不会超出右边界。
open class NEMarkdownHorizontalRule: NEMarkdownElement {
  // 匹配以 - * _ 组成的分隔线（3 个或以上，允许字符间有空格，整行只有这些字符）
  public let regex = "^[ \\t]*([\\-\\*\\_][ \\t]*){3,}[ \\t]*$"

  public func regularExpression() throws -> NSRegularExpression {
    try NSRegularExpression(pattern: regex, options: [.anchorsMatchLines])
  }

  // MARK: - 样式配置

  /// 分隔线颜色
  open var lineColor: UIColor = .init(red: 0.78, green: 0.78, blue: 0.78, alpha: 1)
  /// 分隔线高度（pt）
  open var lineHeight: CGFloat = 1.0
  /// 分隔线上下的额外间距
  open var verticalPadding: CGFloat = 6.0

  public init(lineColor: UIColor? = nil) {
    if let c = lineColor { self.lineColor = c }
  }

  // MARK: - NEMarkdownElement

  public func match(_ match: NSTextCheckingResult,
                    attributedString: NSMutableAttributedString) {
    let attachment = NEMarkdownHorizontalRuleAttachment(
      lineColor: lineColor,
      lineHeight: lineHeight,
      verticalPadding: verticalPadding
    )
    let lineAttrStr = NSAttributedString(attachment: attachment)
    attributedString.replaceCharacters(in: match.range, with: lineAttrStr)
  }
}

// MARK: - 自适应宽度的分隔线 Attachment

/// 在 `attachmentBounds` 阶段根据 `proposedLineFragment` 动态计算宽度，
/// 确保分隔线始终与气泡内容区域等宽，不会超出右边界。
private class NEMarkdownHorizontalRuleAttachment: NSTextAttachment {
  let lineColor: UIColor
  let lineHeight: CGFloat
  let verticalPadding: CGFloat

  init(lineColor: UIColor, lineHeight: CGFloat, verticalPadding: CGFloat) {
    self.lineColor = lineColor
    self.lineHeight = lineHeight
    self.verticalPadding = verticalPadding
    super.init(data: nil, ofType: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  /// 根据所在文本容器的行宽自适应 Attachment 尺寸
  override func attachmentBounds(for textContainer: NSTextContainer?,
                                 proposedLineFragment lineFrag: CGRect,
                                 glyphPosition position: CGPoint,
                                 characterIndex charIndex: Int) -> CGRect {
    // 宽度 = 当前行的可用宽度（自动匹配气泡宽度）
    let width = lineFrag.width
    let height = lineHeight + verticalPadding * 2
    return CGRect(origin: .zero, size: CGSize(width: width, height: height))
  }

  /// 按实际 bounds 尺寸动态绘制横线图片
  override func image(forBounds imageBounds: CGRect,
                      textContainer: NSTextContainer?,
                      characterIndex charIndex: Int) -> UIImage? {
    let size = imageBounds.size
    guard size.width > 0, size.height > 0 else { return nil }
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { ctx in
      lineColor.setFill()
      let lineRect = CGRect(x: 0,
                            y: verticalPadding,
                            width: size.width,
                            height: lineHeight)
      ctx.fill(lineRect)
    }
  }
}
