// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NETeamUIKit
import UIKit

class CustomTeamSettingSwitchCell: TeamSettingSwitchCell {
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
      NSLayoutConstraint.activate([
        titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
        titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -68),
      ])

      contentView.addSubview(tSwitch)
      NSLayoutConstraint.activate([
        tSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        tSwitch.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      ])
      tSwitch.onTintColor = .ne_funTheme

      tSwitch.addTarget(self, action: #selector(switchChange(_:)), for: .touchUpInside)

      dividerLineLeftMargin?.constant = 20
      dividerLineRightMargin?.constant = 0
    }
  }
}
