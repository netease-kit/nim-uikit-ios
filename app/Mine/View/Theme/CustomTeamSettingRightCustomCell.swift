// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NETeamUIKit
import UIKit

class CustomTeamSettingRightCustomCell: TeamSettingRightCustomCell {
  override func setupUI() {
    if NEStyleManager.instance.isNormalStyle() {
      super.setupUI()
    } else {
      let whiteBgView = UIView()
      whiteBgView.backgroundColor = UIColor.white
      whiteBgView.translatesAutoresizingMaskIntoConstraints = false
      contentView.insertSubview(whiteBgView, belowSubview: dividerLine)
      NSLayoutConstraint.activate([
        whiteBgView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
        whiteBgView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
        whiteBgView.topAnchor.constraint(equalTo: contentView.topAnchor),
        whiteBgView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      ])

      contentView.addSubview(titleLabel)
      contentView.addSubview(subTitleLabel)
      contentView.addSubview(arrowView)

      NSLayoutConstraint.activate([
        titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
        titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
        titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      ])
      titleWidthAnchor = titleLabel.widthAnchor.constraint(equalToConstant: 0)
      titleWidthAnchor?.isActive = true

      NSLayoutConstraint.activate([
        arrowView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        arrowView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
        arrowView.widthAnchor.constraint(equalToConstant: 7),
      ])

      NSLayoutConstraint.activate([
        subTitleLabel.leftAnchor.constraint(equalTo: titleLabel.rightAnchor, constant: 10),
        subTitleLabel.rightAnchor.constraint(equalTo: arrowView.leftAnchor, constant: -10),
        subTitleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      ])

      contentView.addSubview(customRightView)
      NSLayoutConstraint.activate([
        customRightView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        customRightView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
        customRightView.widthAnchor.constraint(equalToConstant: 15),
        customRightView.heightAnchor.constraint(equalToConstant: 15),
      ])
      customRightView.addTarget(
        self,
        action: #selector(customRightViewClick),
        for: .touchUpInside
      )

      dividerLineLeftMargin?.constant = 20
      dividerLineRightMargin?.constant = 0
    }
  }
}
