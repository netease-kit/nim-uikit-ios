// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

@objcMembers
open class NELocationAddressCell: UITableViewCell {
  /// 位置指示图片
  public lazy var locationImgView: UIImageView = {
    let locationImageView = UIImageView(image: mapCoreLoader.loadImage("chat_loacaiton_img"))
    locationImageView.translatesAutoresizingMaskIntoConstraints = false
    return locationImageView
  }()

  /// 选中图片
  public lazy var selectImgView: UIImageView = {
    let imgView = UIImageView(image: mapCoreLoader.loadImage("chat_map_select"))
    imgView.translatesAutoresizingMaskIntoConstraints = false
    return imgView
  }()

  /// 位置主标题
  public lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_darkText
    label.font = UIFont.systemFont(ofSize: 16)
    label.text = ""
    return label
  }()

  /// 位子副标题
  public lazy var subTitleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_emptyTitleColor
    label.font = UIFont.systemFont(ofSize: 14)
    label.text = ""
    return label
  }()

  /// 分割线视图
  public lazy var bottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.ne_navLineColor
    return view
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    setupSubviews()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupSubviews() {
    selectionStyle = .none
    contentView.addSubview(locationImgView)
    contentView.addSubview(selectImgView)
    contentView.addSubview(titleLabel)
    contentView.addSubview(subTitleLabel)
    contentView.addSubview(bottomLine)

    NSLayoutConstraint.activate([
      locationImgView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15),
      locationImgView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 17),
      locationImgView.heightAnchor.constraint(equalToConstant: 18),
      locationImgView.widthAnchor.constraint(equalToConstant: 18),
    ])

    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: locationImgView.rightAnchor, constant: 7),
      titleLabel.centerYAnchor.constraint(equalTo: locationImgView.centerYAnchor),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -70),
    ])

    NSLayoutConstraint.activate([
      subTitleLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
      subTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
      subTitleLabel.rightAnchor.constraint(equalTo: titleLabel.rightAnchor),
    ])

    NSLayoutConstraint.activate([
      selectImgView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -13),
      selectImgView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])

    NSLayoutConstraint.activate([
      bottomLine.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12),
      bottomLine.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -12),
      bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -1),
      bottomLine.heightAnchor.constraint(equalToConstant: 1),
    ])
  }

  func configure(_ model: NELocaitonModel, _ select: Bool) {
    titleLabel.attributedText = model.attribute
    var distanceStr = ""
    if model.distance > 0 {
      if model.distance <= 1000 {
        distanceStr = "\(model.distance)m"
      } else {
        let kilometer = model.distance / 1000
        distanceStr = "\(kilometer)km"
      }
      subTitleLabel.text = "\(distanceStr)\(mapLocalizable("distance_inner"))|\(model.address)"
    } else {
      subTitleLabel.text = model.address
    }

    if select == true {
      selectImgView.isHidden = false
    } else {
      selectImgView.isHidden = true
    }
  }
}
