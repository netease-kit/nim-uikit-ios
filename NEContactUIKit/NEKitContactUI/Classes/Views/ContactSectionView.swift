
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

public class ContactSectionView: UITableViewHeaderFooterView {
  public var titleLabel = UILabel()
  var line = UIView()

  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func commonUI() {
    contentView.backgroundColor = .white
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.textColor = NEKitContactConfig.shared.ui.indexTitleColor
    titleLabel.font = UIFont.systemFont(ofSize: 14.0)
    addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 20),
      titleLabel.topAnchor.constraint(equalTo: topAnchor),
      titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
      titleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -20),
    ])

    line.translatesAutoresizingMaskIntoConstraints = false
    line.backgroundColor = NEKitContactConfig.shared.ui.divideLineColor
    addSubview(line)
    NSLayoutConstraint.activate([
      line.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
      line.heightAnchor.constraint(equalToConstant: 1.0),
      line.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1.0),
      line.rightAnchor.constraint(equalTo: rightAnchor),
    ])
  }
}
