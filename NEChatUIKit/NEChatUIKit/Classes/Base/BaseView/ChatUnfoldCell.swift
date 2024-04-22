
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class ChatUnfoldCell: ChatCornerCell {
  lazy var arrowImageView: UIImageView = {
    let arrowImageView = UIImageView()
    arrowImageView.translatesAutoresizingMaskIntoConstraints = false
    arrowImageView.image = UIImage.ne_imageNamed(name: "arrowDown")
    return arrowImageView
  }()

  lazy var contentLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = .ne_greyText
    label.font = DefaultTextFont(14)
    return label
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    contentView.addSubview(contentLabel)
    NSLayoutConstraint.activate([
      contentLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      contentLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
    ])

    contentView.addSubview(arrowImageView)
    NSLayoutConstraint.activate([
      arrowImageView.leftAnchor.constraint(equalTo: contentLabel.rightAnchor, constant: 5),
      arrowImageView.centerYAnchor.constraint(equalTo: contentLabel.centerYAnchor),
    ])
  }

  func changeToArrowUp() {
    arrowImageView.image = UIImage.ne_imageNamed(name: "arrowUp")
  }

  func changeToArrowDown() {
    arrowImageView.image = UIImage.ne_imageNamed(name: "arrowDown")
  }
}
