// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NIMSDK
import UIKit

@objcMembers
open class FunTeamIntroduceViewController: NEBaseTeamIntroduceViewController {
  override open func setupUI() {
    super.setupUI()
    view.backgroundColor = .funTeamBackgroundColor
    addRightAction(localizable("save"), #selector(saveIntr), self, .funTeamThemeColor)
    navigationController?.navigationBar.backgroundColor = .funTeamBackgroundColor
    navigationView.backgroundColor = .funTeamBackgroundColor
    navigationView.moreButton.setTitleColor(.funTeamThemeColor, for: .normal)

    NSLayoutConstraint.activate([
      backView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
      backView.topAnchor.constraint(equalTo: view.topAnchor, constant: NEConstant.navigationAndStatusHeight),
      backView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
      backView.heightAnchor.constraint(equalToConstant: 142),
    ])

    NSLayoutConstraint.activate([
      textView.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 16.0),
      textView.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -32.0),
      textView.topAnchor.constraint(equalTo: backView.topAnchor, constant: 16.0),
      textView.heightAnchor.constraint(equalToConstant: 110),
    ])

    NSLayoutConstraint.activate([
      clearButton.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -16),
      clearButton.bottomAnchor.constraint(equalTo: countLabel.topAnchor, constant: -6),
      clearButton.widthAnchor.constraint(equalToConstant: 16),
      clearButton.heightAnchor.constraint(equalToConstant: 16),
    ])
  }
}
