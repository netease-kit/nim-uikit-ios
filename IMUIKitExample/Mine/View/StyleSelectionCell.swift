// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

open class StyleSelectionCell: UICollectionViewCell {
  var styleName = "default"
  var stylePreview = UIImageView()
  var styleTitleLabel = UILabel()
  var selectButton = UIButton()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    self.frame = CGRect(x: 0, y: 0, width: 102, height: 252)
    setupSubviews()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupSubviews() {
    stylePreview.translatesAutoresizingMaskIntoConstraints = false
    stylePreview.layer.cornerRadius = 8
    addSubview(stylePreview)

    styleTitleLabel.translatesAutoresizingMaskIntoConstraints = false
    styleTitleLabel.accessibilityIdentifier = "id.styleTitle"
    addSubview(styleTitleLabel)

    selectButton.translatesAutoresizingMaskIntoConstraints = false
    selectButton.setImage(UIImage(named: "unclicked"), for: .normal)
    // 交互在外部 cell 中处理，避免内部拦截点击事件
    selectButton.isUserInteractionEnabled = false
    addSubview(selectButton)

    NSLayoutConstraint.activate([
      stylePreview.topAnchor.constraint(equalTo: topAnchor),
      stylePreview.centerXAnchor.constraint(equalTo: centerXAnchor),
      stylePreview.widthAnchor.constraint(equalToConstant: 102),
      stylePreview.heightAnchor.constraint(equalToConstant: 180),
    ])

    NSLayoutConstraint.activate([
      styleTitleLabel.topAnchor.constraint(equalTo: stylePreview.bottomAnchor, constant: 16),
      styleTitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
      styleTitleLabel.heightAnchor.constraint(equalToConstant: 18),
    ])

    NSLayoutConstraint.activate([
      selectButton.topAnchor.constraint(equalTo: styleTitleLabel.bottomAnchor, constant: 16),
      selectButton.centerXAnchor.constraint(equalTo: centerXAnchor),
      selectButton.widthAnchor.constraint(equalToConstant: 22),
      selectButton.heightAnchor.constraint(equalToConstant: 22),
    ])
  }

  func configData(model: StyleCellModel) {
    styleName = model.styleName
    stylePreview.image = UIImage(named: model.styleImageName)
    styleTitleLabel.text = model.styleTitle
    selectButton.setImage(UIImage(named: model.selectedImageName), for: .selected)
    selectButton.isSelected = model.selected
  }

  /// 获取大小
  /// - Returns: 返回单元大小
  public static func getSize() -> CGSize {
    CGSize(width: 102, height: 252)
  }
}
