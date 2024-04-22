
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class TextWithRightArrowCell: ContactBaseTextCell {
  public var arrowImageView = UIImageView(image: UIImage.ne_imageNamed(name: "arrowRight"))

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    arrowImageView.translatesAutoresizingMaskIntoConstraints = false
    arrowImageView.contentMode = .center
    contentView.addSubview(arrowImageView)
    NSLayoutConstraint.activate([
      arrowImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      arrowImageView.widthAnchor.constraint(equalToConstant: 20),
      arrowImageView.heightAnchor.constraint(equalToConstant: 20),
      arrowImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func setModel(model: UserItem) {
    super.setModel(model: model)
//        self.detailTitleLabel.text = model.detailTitle
  }
}
