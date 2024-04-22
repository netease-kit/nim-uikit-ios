// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objc
public protocol NELocationBottomViewDelegate: NSObjectProtocol {
  func didClickGuide()
}

@objcMembers
open class NELocationGuideBottomView: UIView {
  public weak var delegate: NELocationBottomViewDelegate?

  /// 引导按钮
  lazy var guideButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(mapCoreLoader.loadImage("chat_map_path"), for: .normal)
    button.setImage(mapCoreLoader.loadImage("chat_map_path"), for: .highlighted)
    button.addTarget(self, action: #selector(guideBtnClick), for: .touchUpInside)
    return button
  }()

  /// 位置标题
  lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 16)
    label.textColor = UIColor.ne_darkText
    label.text = ""
    return label
  }()

  /// 位置副标题
  lazy var subtitleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 14)
    label.textColor = UIColor.ne_emptyTitleColor
    label.text = ""
    return label
  }()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupSubviews()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupSubviews() {
    backgroundColor = .white
    addSubview(guideButton)
    addSubview(titleLabel)
    addSubview(subtitleLabel)

    NSLayoutConstraint.activate([
      guideButton.topAnchor.constraint(equalTo: topAnchor, constant: 16),
      guideButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -12),
      guideButton.widthAnchor.constraint(equalToConstant: 40),
      guideButton.heightAnchor.constraint(equalToConstant: 40),
    ])

    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 12),
      titleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -52),
      titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
    ])

    NSLayoutConstraint.activate([
      subtitleLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
      subtitleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -52),
    ])
  }

  func guideBtnClick() {
    if let delegate = delegate {
      delegate.didClickGuide()
    }
  }
}
