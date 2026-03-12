// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NIMSDK
import UIKit

@objcMembers
open class FunTeamNameViewController: NEBaseTeamNameViewController {
  override open func setupUI() {
    super.setupUI()
    view.backgroundColor = .funTeamBackgroundColor
    navigationController?.navigationBar.backgroundColor = .funTeamBackgroundColor
    addRightAction(localizable("save"), #selector(saveName), self, .funTeamThemeColor)
    navigationView.backgroundColor = .funTeamBackgroundColor
    navigationView.moreButton.setTitleColor(.funTeamThemeColor, for: .normal)

    NSLayoutConstraint.activate([
      backView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
      backView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -0),
      backView.topAnchor.constraint(equalTo: view.topAnchor, constant: NEConstant.navigationAndStatusHeight),
      backView.heightAnchor.constraint(equalToConstant: 60),
    ])

    NSLayoutConstraint.activate([
      textInputView.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 16),
      textInputView.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -32),
      textInputView.centerYAnchor.constraint(equalTo: backView.centerYAnchor, constant: 0),
      textInputView.heightAnchor.constraint(equalToConstant: 60),
    ])

    NSLayoutConstraint.activate([
      clearButton.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -16),
      clearButton.topAnchor.constraint(equalTo: backView.topAnchor, constant: 16),
      clearButton.widthAnchor.constraint(equalToConstant: 16),
      clearButton.heightAnchor.constraint(equalToConstant: 16),
    ])
  }

  override open func disableSubmit() {
    rightNavButton.setTitleColor(.funTeamThemeDisableColor, for: .normal)
    rightNavButton.isEnabled = false
    navigationView.moreButton.setTitleColor(.funTeamThemeDisableColor, for: .normal)
    navigationView.moreButton.isEnabled = false
  }

  override open func enableSubmit() {
    rightNavButton.setTitleColor(.funTeamThemeColor, for: .normal)
    rightNavButton.isEnabled = true
    navigationView.moreButton.setTitleColor(.funTeamThemeColor, for: .normal)
    navigationView.moreButton.isEnabled = true
  }
}
