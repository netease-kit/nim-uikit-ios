
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class ChatHeaderView: UIView {
  public lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.font = DefaultTextFont(12)
    label.textColor = .ne_greyText
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    clipsToBounds = false
    addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
      titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 33),
    ])
    backgroundColor = .clear
  }

  open func setTitle(_ name: String) {
    titleLabel.text = name
      .count > 2 ? String(name[name.index(name.endIndex, offsetBy: -2)...]) : name
  }
}
