
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class ChatSectionView: UITableViewHeaderFooterView {
  public var titleLabel = UILabel()
  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func commonUI() {
    contentView.backgroundColor = .ne_lightBackgroundColor
    titleLabel.font = UIFont.systemFont(ofSize: 12)
    titleLabel.textColor = .ne_greyText
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    contentView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 33),
      titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
      titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
      titleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -33),
    ])
  }
}
