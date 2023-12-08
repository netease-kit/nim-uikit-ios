
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NIMSDK
import UIKit

@objcMembers
open class TeamIntroduceViewController: NEBaseTeamIntroduceViewController {
  override open func setupUI() {
    super.setupUI()
    view.backgroundColor = .ne_lightBackgroundColor
    navigationView.backgroundColor = .ne_lightBackgroundColor
    navigationController?.navigationBar.backgroundColor = .ne_lightBackgroundColor
    addRightAction(localizable("save"), #selector(saveIntr), self)
    navigationView.setBackButtonTitle(localizable("cancel"))
    navigationView.backButton.setTitleColor(.ne_greyText, for: .normal)

    backView.layer.cornerRadius = 8.0
    NSLayoutConstraint.activate([
      backView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      backView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12.0 + NEConstant.navigationAndStatusHeight),
      backView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      backView.heightAnchor.constraint(equalToConstant: 170),
    ])

    NSLayoutConstraint.activate([
      textView.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 16.0),
      textView.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -32.0),
      textView.topAnchor.constraint(equalTo: backView.topAnchor, constant: 16.0),
      textView.heightAnchor.constraint(equalToConstant: 120),
    ])

    NSLayoutConstraint.activate([
      clearButton.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -16),
      clearButton.bottomAnchor.constraint(equalTo: countLabel.topAnchor, constant: -6),
      clearButton.widthAnchor.constraint(equalToConstant: 16),
      clearButton.heightAnchor.constraint(equalToConstant: 16),
    ])
  }
}
