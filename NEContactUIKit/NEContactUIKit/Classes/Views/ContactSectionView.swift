
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class ContactSectionView: UITableViewHeaderFooterView {
  public var titleLabel = UILabel()
  var line = UIView()

  override public init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func commonUI() {
    contentView.backgroundColor = .white
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.backgroundColor = .white
    titleLabel.textColor = ContactUIConfig.shared.contactProperties.indexTitleColor ?? UIColor.ne_emptyTitleColor
    titleLabel.font = UIFont.systemFont(ofSize: 14.0)
    contentView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 20),
    ])

    line.translatesAutoresizingMaskIntoConstraints = false
    line.backgroundColor = ContactUIConfig.shared.contactProperties.divideLineColor
    contentView.addSubview(line)
    NSLayoutConstraint.activate([
      line.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
      line.heightAnchor.constraint(equalToConstant: 1.0),
      line.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
      line.rightAnchor.constraint(equalTo: contentView.rightAnchor),
    ])
  }
}
