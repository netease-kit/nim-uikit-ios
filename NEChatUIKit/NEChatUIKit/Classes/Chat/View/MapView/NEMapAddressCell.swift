// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

@objcMembers
open class NEMapAddressCell: UITableViewCell {
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    setupSubviews()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setupSubviews() {
    selectionStyle = .none
    contentView.addSubview(locationImg)
    contentView.addSubview(selectImg)
    contentView.addSubview(title)
    contentView.addSubview(subTitle)
    contentView.addSubview(bottomLine)

    NSLayoutConstraint.activate([
      locationImg.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15),
      locationImg.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 17),
      locationImg.heightAnchor.constraint(equalToConstant: 18),
      locationImg.widthAnchor.constraint(equalToConstant: 18),
    ])

    NSLayoutConstraint.activate([
      title.leftAnchor.constraint(equalTo: locationImg.rightAnchor, constant: 7),
      title.centerYAnchor.constraint(equalTo: locationImg.centerYAnchor),
      title.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -70),
    ])

    NSLayoutConstraint.activate([
      subTitle.leftAnchor.constraint(equalTo: title.leftAnchor),
      subTitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),
      subTitle.rightAnchor.constraint(equalTo: title.rightAnchor),
    ])

    NSLayoutConstraint.activate([
      selectImg.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -13),
      selectImg.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])

    NSLayoutConstraint.activate([
      bottomLine.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12),
      bottomLine.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -12),
      bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -1),
      bottomLine.heightAnchor.constraint(equalToConstant: 1),
    ])
  }

  public lazy var locationImg: UIImageView = {
    let location = UIImageView(image: UIImage.ne_imageNamed(name: "chat_loacaiton_img"))
    location.translatesAutoresizingMaskIntoConstraints = false
    return location
  }()

  public lazy var selectImg: UIImageView = {
    let img = UIImageView(image: UIImage.ne_imageNamed(name: "chat_map_select"))
    img.translatesAutoresizingMaskIntoConstraints = false
    return img
  }()

  public lazy var title: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_darkText
    label.font = UIFont.systemFont(ofSize: 16)
    label.text = ""
    return label
  }()

  public lazy var subTitle: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_emptyTitleColor
    label.font = UIFont.systemFont(ofSize: 14)
    label.text = ""
    return label
  }()

  private lazy var bottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.ne_navLineColor
    return view
  }()

  func configure(_ model: ChatLocaitonModel, _ select: Bool) {
    title.attributedText = model.attribute
    var distanceStr = ""
    if model.distance > 0 {
      if model.distance <= 1000 {
        distanceStr = "\(model.distance)m"
      } else {
        let kilometer = model.distance / 1000
        distanceStr = "\(kilometer)km"
      }
      subTitle.text = "\(distanceStr)\(chatLocalizable("distance_inner"))|\(model.address)"
    } else {
      subTitle.text = model.address
    }

    if select == true {
      selectImg.isHidden = false
    } else {
      selectImg.isHidden = true
    }
  }
}
