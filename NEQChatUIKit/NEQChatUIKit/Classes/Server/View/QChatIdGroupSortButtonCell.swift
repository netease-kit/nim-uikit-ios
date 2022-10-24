
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

class QChatIdGroupSortButtonCell: QChatBaseCell {
  lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = .ne_greyText
    label.font = DefaultTextFont(12)
    return label
  }()

  lazy var sortImage: UIImageView = {
    let image = UIImageView()
    image.translatesAutoresizingMaskIntoConstraints = false
    image.image = UIImage.ne_imageNamed(name: "id_group_sort")
    return image
  }()

  lazy var sortBtn: ExpandButton = {
    let btn = ExpandButton()
    btn.translatesAutoresizingMaskIntoConstraints = false
    return btn
  }()

  lazy var sortLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = DefaultTextFont(12)
    label.textColor = .ne_blueText
    label.text = localizable("qchat_sort")
    return label
  }()

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
    setupUI()
  }

  func setupUI() {
    contentView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
    ])

    contentView.addSubview(sortLabel)
    NSLayoutConstraint.activate([
      sortLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
      sortLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
    ])

    contentView.addSubview(sortImage)
    NSLayoutConstraint.activate([
      sortImage.centerYAnchor.constraint(equalTo: sortLabel.centerYAnchor),
      sortImage.rightAnchor.constraint(equalTo: sortLabel.leftAnchor, constant: -6),
    ])

    contentView.addSubview(sortBtn)
    NSLayoutConstraint.activate([
      sortBtn.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      sortBtn.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      sortBtn.topAnchor.constraint(equalTo: contentView.topAnchor),
      sortBtn.leftAnchor.constraint(equalTo: sortImage.leftAnchor, constant: -10),
    ])
  }
}
