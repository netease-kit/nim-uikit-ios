
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class TeamCenterTextCell: UITableViewCell {
  public var titleLabel: UILabel = .init()
  public var line = UIView()
  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    titleLabel.font = UIFont.systemFont(ofSize: 16)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.textColor = .red
    titleLabel.textAlignment = .center
    titleLabel.accessibilityIdentifier = "id.titleLabel"
    contentView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 36),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -36),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 66),
    ])
    titleLabel.text = "title"
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
    super.init(coder: coder)
  }

  open func setModel(model: TeamDetailItem) {
    titleLabel.text = model.title
    titleLabel.textColor = model.textColor
  }
}
