
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objc
public protocol LinkableLabelProtocol {
  @objc optional func didTapLink(url: URL?)
}

@objcMembers
open class NELinkableLabel: UILabel {
  // MARK: - 配置

  public weak var delegate: LinkableLabelProtocol?
  private let detectorTypes: NSTextCheckingResult.CheckingType = [.link, .phoneNumber]
  private let linkAttributes: [NSAttributedString.Key: Any] = [
    .foregroundColor: UIColor.systemBlue,
    .underlineColor: UIColor.systemBlue,
    .underlineStyle: NSUnderlineStyle.single.rawValue,
  ]

  // MARK: - 初始化与设置

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  private func setup() {
    isUserInteractionEnabled = true
    numberOfLines = 0
    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
    tap.cancelsTouchesInView = false
    addGestureRecognizer(tap)
  }

  // MARK: - 链接检测（保留原有属性）

  public func updateLinkDetection() {
    guard let text = text else {
      attributedText = nil
      return
    }

    // 基于现有 attributedText 或新文本初始化
    let baseAttributedString = NSMutableAttributedString(
      attributedString: attributedText ?? NSAttributedString(string: text)
    )

    // 检测链接
    let detector = try! NSDataDetector(types: detectorTypes.rawValue)
    let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

    // 合并链接样式
    for match in matches {
      guard let url = generateURL(for: match) else { continue }
      let range = match.range

      baseAttributedString.enumerateAttributes(in: range) { existingAttributes, subRange, _ in
        var mergedAttributes = existingAttributes
        // 保留非链接相关属性，覆盖链接相关属性
        for (key, value) in linkAttributes {
          mergedAttributes[key] = value
        }
        mergedAttributes[.link] = url
        baseAttributedString.setAttributes(mergedAttributes, range: subRange)
      }
    }

    attributedText = baseAttributedString
  }

  // MARK: - 生成正确 URL

  private func generateURL(for match: NSTextCheckingResult) -> URL? {
    switch match.resultType {
    case .phoneNumber:
      return URL(string: "tel:\(match.phoneNumber!)")
    case .link where match.url?.scheme == "mailto":
      return match.url
    case .link:
      return match.url
    default:
      return nil
    }
  }

  // MARK: - 点击处理（精确计算）

  @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
    guard let attributedText = attributedText else { return }
    let point = gesture.location(in: self)

    // 创建文本布局
    let textContainer = NSTextContainer(size: bounds.size)
    textContainer.lineFragmentPadding = 0
    textContainer.lineBreakMode = lineBreakMode
    textContainer.maximumNumberOfLines = numberOfLines

    let layoutManager = NSLayoutManager()
    layoutManager.addTextContainer(textContainer)

    let textStorage = NSTextStorage(attributedString: attributedText)
    textStorage.addLayoutManager(layoutManager)

    // 计算点击位置
    let charIndex = layoutManager.characterIndex(
      for: point,
      in: textContainer,
      fractionOfDistanceBetweenInsertionPoints: nil
    )

    // 检查点击是否在链接范围内
    var inRange = false
    attributedText.enumerateAttribute(.link, in: NSRange(location: 0, length: attributedText.length)) { value, range, stop in
      if let url = value as? URL, NSLocationInRange(charIndex, range) {
        delegate?.didTapLink?(url: url)
        inRange = true
        stop.pointee = true
        return
      }
    }

    if !inRange {
      delegate?.didTapLink?(url: nil)
    }
  }
}
