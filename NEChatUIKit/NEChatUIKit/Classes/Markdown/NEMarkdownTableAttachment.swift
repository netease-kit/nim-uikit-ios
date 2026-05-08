// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// 将 `NEMarkdownTableView` 嵌入 `NSAttributedString` 的 `NSTextAttachment` 子类。
///
/// UITextView 渲染 `NSTextAttachment` 有两种方式：
///   A. 实现 `image(forBounds:textContainer:characterIndex:)` → 返回位图（离屏渲染）
///   B. 利用 `UITextView.layoutManager` + `NSLayoutManagerDelegate` → 将子视图直接叠加到 textView
///
/// 本实现采用方案 A（将表格 View 截图为 UIImage），优点是兼容 UILabel，
/// 且不需要侵入 UITextView 的 delegate 链。
/// 缺点：表格内容为静态图片，不支持交互（如滚动）。
///
/// 若需要支持横向滚动大表格，可改用方案 B，参见 `NEMarkdownTableAttachment.embed(into:)`。
open class NEMarkdownTableAttachment: NSTextAttachment {
  /// 持有表格视图（供方案 B 的 embed 使用）
  public let tableView: NEMarkdownTableView
  /// Attachment 占用的尺寸
  public let tableSize: CGSize

  public init(tableView: NEMarkdownTableView, size: CGSize) {
    self.tableView = tableView
    tableSize = size
    super.init(data: nil, ofType: nil)
    // 预先渲染为静态图片（方案 A）
    // 必须在主线程执行 UIKit 操作
    if Thread.isMainThread {
      image = tableView.renderToImage(size: size)
    } else {
      var rendered: UIImage?
      DispatchQueue.main.sync {
        rendered = tableView.renderToImage(size: size)
      }
      image = rendered
    }
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) is not supported for NEMarkdownTableAttachment")
  }

  // MARK: - 占位尺寸

  override open func attachmentBounds(for textContainer: NSTextContainer?,
                                      proposedLineFragment lineFrag: CGRect,
                                      glyphPosition position: CGPoint,
                                      characterIndex charIndex: Int) -> CGRect {
    CGRect(origin: .zero, size: tableSize)
  }

  // MARK: - 方案 B：将表格 View 直接嵌入 UITextView（可选调用）

  //
  // 当 tableSize.width 超出气泡宽度时，可调用此方法将 tableView 叠加到 textView 上，
  // 并用 UIScrollView 包裹以支持横向滚动。
  // 调用时机：UITextView 完成 layout 后，通过 NSLayoutManager 查询 Attachment 的 glyph rect。
  //
  // 示例（在 ChatAIStreamCell 中）：
  //   for attachment in attachments where attachment is NEMarkdownTableAttachment {
  //     attachment.embed(into: textView, at: charIndex)
  //   }

  /// 将表格 View 叠加到 `textView` 的指定 Attachment 位置上（可选，方案 B）。
  /// - Parameters:
  ///   - textView: 目标 UITextView
  ///   - characterIndex: Attachment 字符在 attributedText 中的下标
  public func embed(into textView: UITextView, at characterIndex: Int) {
    let layoutManager = textView.layoutManager
    let glyphIndex = layoutManager.glyphIndexForCharacter(at: characterIndex)
    var glyphRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1),
                                               in: textView.textContainer)
    glyphRect.origin.x += textView.textContainerInset.left
    glyphRect.origin.y += textView.textContainerInset.top

    // 如果已经嵌入过，先移除旧视图
    textView.subviews
      .compactMap { $0 as? NEMarkdownTableScrollWrapper }
      .filter { $0.attachment === self }
      .forEach { $0.removeFromSuperview() }

    let wrapper = NEMarkdownTableScrollWrapper(attachment: self, tableView: tableView, frame: glyphRect)
    textView.addSubview(wrapper)
  }
}

// MARK: - UIView 截图扩展

private extension UIView {
  /// 将视图渲染为 UIImage（用于方案 A 的离屏渲染）。
  func renderToImage(size: CGSize) -> UIImage? {
    // 确保 frame 正确
    if frame.size.width <= 0 || frame.size.height <= 0 {
      frame = CGRect(origin: .zero, size: size)
    }
    // 触发布局
    setNeedsLayout()
    layoutIfNeeded()

    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
      layer.render(in: context.cgContext)
    }
  }
}

// MARK: - 方案 B 使用的滚动包裹视图

/// 包裹 `NEMarkdownTableView` 并支持横向滚动的容器（供方案 B 使用）。
public final class NEMarkdownTableScrollWrapper: UIScrollView {
  /// 关联的 Attachment，用于 embed 时去重识别
  public weak var attachment: NEMarkdownTableAttachment?

  init(attachment: NEMarkdownTableAttachment, tableView: NEMarkdownTableView, frame: CGRect) {
    super.init(frame: frame)
    self.attachment = attachment
    showsVerticalScrollIndicator = false
    showsHorizontalScrollIndicator = true
    bounces = false
    isScrollEnabled = tableView.frame.width > frame.width

    tableView.frame.origin = .zero
    addSubview(tableView)
    contentSize = tableView.frame.size
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }
}
