
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
@objcMembers
open class ContactBaseTextCell: UITableViewCell {
  public var titleLabel: UILabel = .init()
  public var line = UIView()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.font = UIFont.systemFont(ofSize: 16)
    titleLabel.textColor = UIColor(hexString: "#333333")
    contentView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      titleLabel.widthAnchor.constraint(equalToConstant: 90),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
    titleLabel.text = ""

    line.backgroundColor = UIColor(hexString: "#F5F8FC")
    line.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(line)
    NSLayoutConstraint.activate([
      line.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      line.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      line.heightAnchor.constraint(equalToConstant: 1.0),
      line.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setModel(model: UserItem) {
    titleLabel.text = model.title
  }
}
