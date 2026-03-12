
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit

@objcMembers
open class NEEmptyDataView: UIView {
  private var imageName: String?
  private var image: UIImage?
  private var content: String?
  public var widthConstraint: NSLayoutConstraint?
  public var heightConstraint: NSLayoutConstraint?

  /// 空占位图
  public lazy var emptyImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFit
    imageView.accessibilityIdentifier = "id.emptyImageView"
    return imageView
  }()

  /// 空提示标签
  private lazy var contentLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_emptyTitleColor
    label.font = UIFont.systemFont(ofSize: 14)
    label.numberOfLines = 0
    label.textAlignment = .center
    label.accessibilityIdentifier = "id.emptyContentLabel"

    return label
  }()

  public init(imageName: String, content: String, frame: CGRect) {
    self.imageName = imageName
    self.content = content
    super.init(frame: frame)
    setupSubviews()
    setupSubviewStyle()
  }

  public init(image: UIImage?, content: String, frame: CGRect) {
    self.image = image
    self.content = content
    super.init(frame: frame)
    setupSubviews()
    setupSubviewStyle()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupSubviews() {
    backgroundColor = .clear
    addSubview(emptyImageView)
    addSubview(contentLabel)

    widthConstraint = emptyImageView.widthAnchor.constraint(equalToConstant: 122)
    widthConstraint?.isActive = true
    heightConstraint = emptyImageView.heightAnchor.constraint(equalToConstant: 91)
    heightConstraint?.isActive = true
    NSLayoutConstraint.activate([
      emptyImageView.topAnchor.constraint(equalTo: topAnchor, constant: 176),
      emptyImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
    ])

    NSLayoutConstraint.activate([
      contentLabel.topAnchor.constraint(equalTo: emptyImageView.bottomAnchor, constant: 8),
      contentLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 20),
      contentLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -20),
    ])
  }

  func setupSubviewStyle() {
    if let imgName = imageName {
      emptyImageView.image = coreLoader.loadImage(imgName)
    } else {
      emptyImageView.image = image
    }
    contentLabel.text = content
  }

  /// 设置字符串
  /// - Parameter text: 字符串
  open func setText(_ text: String?) {
    contentLabel.text = text
  }

  /// 设置富文本
  /// - Parameter att: 富文本
  open func setAttributedText(_ att: NSAttributedString?) {
    contentLabel.attributedText = att
  }

  /// 设置占位图（根据图片名称，仅支持 NECommonUIKit 库中的图片）
  /// - Parameter name: （NECommonUIKit 库中的）图片名称
  open func setEmptyImage(name: String) {
    emptyImageView.image = coreLoader.loadImage(name)
  }

  /// 设置占位图（支持外部传递）
  /// - Parameter image: 图片
  open func setEmptyImage(image: UIImage?) {
    emptyImageView.image = image
  }
}
