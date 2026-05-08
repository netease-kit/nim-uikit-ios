// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// Markdown 图片下载完成通知
/// userInfo 包含 "url" (String) 和 "image" (UIImage)
public let NEMarkdownImageDidLoadNotification = Notification.Name("NEMarkdownImageDidLoadNotification")

/// Markdown 图片解析 Element。
///
/// 支持标准 Markdown 图片语法：`![alt text](url)`
/// 解析后将图片替换为 `NSTextAttachment`，图片宽度不超过 `maxWidth`，保持宽高比。
/// 首次渲染使用占位图，异步下载完成后发送通知，由 Cell 层刷新。
open class NEMarkdownImage: NEMarkdownElement {
  // 匹配 ![alt](url) 或 ![alt](url "title")，同时兼容 URL 被引号包裹的情况 ![alt]("url")
  public let regex = "!\\[[^\\[\\]]*\\]\\(\\s*\"?(\\S+?)\"?(?:\\s+\"[^\"]*\")?\\s*\\)"

  /// 图片最大宽度（不超过气泡内容区域），由外部注入
  public var maxWidth: CGFloat = 200

  /// 图片最大高度限制，防止超长图撑爆气泡
  public var maxHeight: CGFloat = 300

  /// 占位图尺寸
  public var placeholderSize: CGSize = .init(width: 120, height: 80)

  public init() {}

  public func regularExpression() throws -> NSRegularExpression {
    try NSRegularExpression(pattern: regex, options: [])
  }

  public func match(_ match: NSTextCheckingResult, attributedString: NSMutableAttributedString) {
    let nsString = attributedString.string as NSString

    // 提取 URL（第 1 个捕获组）
    guard match.numberOfRanges > 1 else { return }
    let urlRange = match.range(at: 1)
    let urlString = nsString.substring(with: urlRange)

    // 创建图片 Attachment
    let attachment = NEMarkdownImageAttachment(
      imageURL: urlString,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      placeholderSize: placeholderSize
    )

    // 用 Attachment 替换整个 ![alt](url) 语法
    let imageAttrStr = NSAttributedString(attachment: attachment)
    attributedString.replaceCharacters(in: match.range, with: imageAttrStr)

    // 异步下载图片
    attachment.startDownload()
  }
}

// MARK: - NEMarkdownImageAttachment

/// 图片 Attachment：管理占位图 → 真实图片的切换。
///
/// 下载完成后：
/// 1. 更新自身的 `image` 属性
/// 2. 发送 `NEMarkdownImageDidLoadNotification` 通知
/// 3. Cell 收到通知后重算高度并刷新
open class NEMarkdownImageAttachment: NSTextAttachment {
  /// 图片 URL 字符串
  public let imageURL: String
  /// 最大宽度
  public let maxWidth: CGFloat
  /// 最大高度
  public let maxHeight: CGFloat
  /// 占位图尺寸
  public let placeholderSize: CGSize

  /// 下载后的真实图片尺寸（已约束到 maxWidth/maxHeight）
  private var displaySize: CGSize

  /// 是否已下载完成
  public private(set) var isLoaded: Bool = false

  /// 全局图片缓存（URL → UIImage），避免重复下载
  private static var imageCache = NSCache<NSString, UIImage>()

  public init(imageURL: String, maxWidth: CGFloat, maxHeight: CGFloat, placeholderSize: CGSize) {
    self.imageURL = imageURL
    self.maxWidth = maxWidth
    self.maxHeight = maxHeight
    self.placeholderSize = placeholderSize
    displaySize = placeholderSize
    super.init(data: nil, ofType: nil)

    // 生成占位图
    image = Self.generatePlaceholder(size: placeholderSize)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) is not supported for NEMarkdownImageAttachment")
  }

  // MARK: - 占位尺寸

  override open func attachmentBounds(for textContainer: NSTextContainer?,
                                      proposedLineFragment lineFrag: CGRect,
                                      glyphPosition position: CGPoint,
                                      characterIndex charIndex: Int) -> CGRect {
    CGRect(origin: .zero, size: displaySize)
  }

  // MARK: - 下载

  /// 开始异步下载图片
  public func startDownload() {
    // 1. 缓存命中，同步设置图片（不发送通知，避免无限递归）
    // 此时 parse() 尚未返回，AttributedString 正在构建中，直接设置即可
    if let cached = Self.imageCache.object(forKey: imageURL as NSString) {
      applyCachedImage(cached)
      return
    }

    // 2. 异步下载
    guard let url = URL(string: imageURL) else { return }

    URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
      guard let self = self,
            error == nil,
            let data = data,
            let downloadedImage = UIImage(data: data) else {
        return
      }

      // 缓存
      Self.imageCache.setObject(downloadedImage, forKey: self.imageURL as NSString)

      DispatchQueue.main.async {
        self.applyDownloadedImage(downloadedImage)
      }
    }.resume()
  }

  // MARK: - 应用图片

  /// 缓存命中时同步设置图片，不发送通知
  /// parse() 返回的 NSAttributedString 已包含正确图片，无需触发 Cell 刷新
  private func applyCachedImage(_ cachedImage: UIImage) {
    let constrainedSize = Self.constrainSize(
      imageSize: cachedImage.size,
      maxWidth: maxWidth,
      maxHeight: maxHeight
    )
    displaySize = constrainedSize
    isLoaded = true
    image = Self.resizeImage(cachedImage, to: constrainedSize)
  }

  /// 异步下载完成后设置图片并发送通知，通知 Cell 层刷新
  private func applyDownloadedImage(_ downloadedImage: UIImage) {
    let constrainedSize = Self.constrainSize(
      imageSize: downloadedImage.size,
      maxWidth: maxWidth,
      maxHeight: maxHeight
    )
    displaySize = constrainedSize
    isLoaded = true

    // 将图片缩放到目标尺寸，减少内存占用
    image = Self.resizeImage(downloadedImage, to: constrainedSize)

    // 发送通知，通知 Cell 层刷新（仅异步下载完成时发送）
    NotificationCenter.default.post(
      name: NEMarkdownImageDidLoadNotification,
      object: nil,
      userInfo: [
        "url": imageURL,
        "image": image as Any,
      ]
    )
  }

  // MARK: - 工具方法

  /// 约束图片尺寸，不超过 maxWidth/maxHeight，保持宽高比
  public static func constrainSize(imageSize: CGSize, maxWidth: CGFloat, maxHeight: CGFloat) -> CGSize {
    guard imageSize.width > 0, imageSize.height > 0 else {
      return CGSize(width: maxWidth, height: maxWidth * 0.6)
    }

    var width = imageSize.width
    var height = imageSize.height

    // 先按宽度约束
    if width > maxWidth {
      height = height * maxWidth / width
      width = maxWidth
    }

    // 再按高度约束
    if height > maxHeight {
      width = width * maxHeight / height
      height = maxHeight
    }

    return CGSize(width: ceil(width), height: ceil(height))
  }

  /// 生成灰色占位图（带图片图标提示）
  private static func generatePlaceholder(size: CGSize) -> UIImage? {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { ctx in
      // 背景
      UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0).setFill()
      let bgRect = CGRect(origin: .zero, size: size)
      let bgPath = UIBezierPath(roundedRect: bgRect, cornerRadius: 4)
      bgPath.fill()

      // 中心绘制一个简易图片图标
      let iconSize: CGFloat = min(size.width, size.height) * 0.3
      let iconRect = CGRect(
        x: (size.width - iconSize) / 2,
        y: (size.height - iconSize) / 2,
        width: iconSize,
        height: iconSize
      )
      UIColor(red: 0.78, green: 0.78, blue: 0.78, alpha: 1.0).setFill()
      let iconPath = UIBezierPath(roundedRect: iconRect, cornerRadius: 2)
      iconPath.fill()
    }
  }

  /// 将图片缩放到指定尺寸
  private static func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { _ in
      image.draw(in: CGRect(origin: .zero, size: size))
    }
  }
}
