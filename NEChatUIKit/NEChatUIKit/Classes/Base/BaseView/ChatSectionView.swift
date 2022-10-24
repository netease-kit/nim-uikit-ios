
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
public class ChatSectionView: UITableViewHeaderFooterView {
  public var titleLable = UILabel()
  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func commonUI() {
    contentView.backgroundColor = .ne_lightBackgroundColor
    titleLable.font = UIFont.systemFont(ofSize: 12)
    titleLable.textColor = .ne_greyText
    titleLable.translatesAutoresizingMaskIntoConstraints = false

    contentView.addSubview(titleLable)
    NSLayoutConstraint.activate([
      titleLable.leftAnchor.constraint(equalTo: leftAnchor, constant: 33),
      titleLable.topAnchor.constraint(equalTo: topAnchor, constant: 8),
      titleLable.bottomAnchor.constraint(equalTo: bottomAnchor),
      titleLable.rightAnchor.constraint(equalTo: rightAnchor, constant: -33),
    ])
  }
}
