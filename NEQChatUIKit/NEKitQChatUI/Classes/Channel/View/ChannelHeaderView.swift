
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

class ChannelHeaderView: UIView {
  var titleLabel = UILabel()
  var detailLabel = UILabel()
  var settingButton = UIButton()
  private var prefixLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    prefixLabel.font = .systemFont(ofSize: 16)
    prefixLabel.textColor = .ne_lightText
    prefixLabel.text = "#"
    prefixLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(prefixLabel)
    NSLayoutConstraint.activate([
      prefixLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
      prefixLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 20),
      prefixLabel.widthAnchor.constraint(equalToConstant: 20),
      prefixLabel.heightAnchor.constraint(equalToConstant: 26),
    ])

    titleLabel.font = .systemFont(ofSize: 18)
    titleLabel.textColor = .ne_darkText
    titleLabel.text = "频道1"
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
      titleLabel.leftAnchor.constraint(equalTo: prefixLabel.rightAnchor, constant: 0),
      titleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -81),
      titleLabel.heightAnchor.constraint(equalToConstant: 26),
    ])

    detailLabel.textColor = .ne_greyText
    detailLabel.font = .systemFont(ofSize: 14)
    detailLabel.text = "分享心得"
    detailLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(detailLabel)
    NSLayoutConstraint.activate([
      detailLabel.leftAnchor.constraint(equalTo: prefixLabel.leftAnchor),
      detailLabel.topAnchor.constraint(equalTo: prefixLabel.bottomAnchor, constant: 0),
      detailLabel.heightAnchor.constraint(equalToConstant: 20),
      detailLabel.rightAnchor.constraint(equalTo: titleLabel.rightAnchor),
    ])

    settingButton.setImage(UIImage.ne_imageNamed(name: "Setting"), for: .normal)
    settingButton.translatesAutoresizingMaskIntoConstraints = false
    addSubview(settingButton)
    NSLayoutConstraint.activate([
      settingButton.topAnchor.constraint(equalTo: topAnchor, constant: 10),
      settingButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
      settingButton.widthAnchor.constraint(equalToConstant: 40),
      settingButton.heightAnchor.constraint(equalToConstant: 32),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
