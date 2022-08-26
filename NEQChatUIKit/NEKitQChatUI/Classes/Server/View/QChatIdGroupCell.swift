
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

class QChatIdGroupCell: QChatBaseCell {
  lazy var headImage: UIImageView = {
    let image = UIImageView()
    image.translatesAutoresizingMaskIntoConstraints = false
    image.image = UIImage.ne_imageNamed(name: "id_group_header")
    return image
  }()

  lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_darkText
    label.font = DefaultTextFont(14)
    label.textAlignment = .left
    return label
  }()

  lazy var subTitleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_greyText
    label.font = DefaultTextFont(12)
    label.textAlignment = .left
    return label
  }()

  lazy var countHeadImage: UIImageView = {
    let image = UIImageView()
    image.translatesAutoresizingMaskIntoConstraints = false
    image.image = UIImage.ne_imageNamed(name: "count_header")
    return image
  }()

  lazy var tailImage: UIImageView = {
    let image = UIImageView()
    image.translatesAutoresizingMaskIntoConstraints = false
    image.highlightedImage = UIImage.ne_imageNamed(name: "lock")
    image.image = UIImage.ne_imageNamed(name: "arrowRight")
    return image
  }()

  lazy var dividerLine: UIView = {
    let line = UIView()
    line.backgroundColor = .ne_greyLine
    line.translatesAutoresizingMaskIntoConstraints = false
    return line
  }()

  var leftSpace: NSLayoutConstraint?

  var titleLeftSpace: NSLayoutConstraint?

  var countHeadWidth: NSLayoutConstraint?

  var headWidth: NSLayoutConstraint?

  var headHeight: NSLayoutConstraint?

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
    contentView.addSubview(headImage)
    leftSpace = headImage.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 24)
    leftSpace?.isActive = true

    headWidth = headImage.widthAnchor.constraint(equalToConstant: 29)
    headWidth?.isActive = true
    headHeight = headImage.heightAnchor.constraint(equalToConstant: 33)
    headHeight?.isActive = true

    NSLayoutConstraint.activate([
      headImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])

    contentView.addSubview(tailImage)
    NSLayoutConstraint.activate([
      tailImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      tailImage.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
    ])

    contentView.addSubview(titleLabel)
    titleLeftSpace = titleLabel.leftAnchor.constraint(
      equalTo: headImage.rightAnchor,
      constant: 15.5
    )
    titleLeftSpace?.isActive = true
    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 13.0),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -36.0),
    ])

    contentView.addSubview(countHeadImage)
    countHeadWidth = countHeadImage.widthAnchor.constraint(equalToConstant: 10)
    countHeadWidth?.isActive = true
    NSLayoutConstraint.activate([
      countHeadImage.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
      countHeadImage.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
      countHeadImage.heightAnchor.constraint(equalToConstant: 10),
    ])

    contentView.addSubview(subTitleLabel)
    NSLayoutConstraint.activate([
      subTitleLabel.leftAnchor.constraint(equalTo: countHeadImage.rightAnchor, constant: 6),
      subTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
      subTitleLabel.rightAnchor.constraint(equalTo: titleLabel.rightAnchor),
    ])

    contentView.addSubview(dividerLine)
    NSLayoutConstraint.activate([
      dividerLine.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      dividerLine.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      dividerLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      dividerLine.heightAnchor.constraint(equalToConstant: 1),
    ])
  }

  func configure(_ model: IdGroupModel) {
    titleLabel.text = model.idName
    subTitleLabel.text = model.subTitle
  }
}
