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
    customNavigationView.backgroundColor = .funTeamBackgroundColor
    customNavigationView.moreButton.setTitleColor(.funTeamThemeColor, for: .normal)

    NSLayoutConstraint.activate([
      backView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
      backView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -0),
      backView.topAnchor.constraint(equalTo: view.topAnchor, constant: NEConstant.navigationAndStatusHeight),
      backView.heightAnchor.constraint(equalToConstant: 60),
    ])

    NSLayoutConstraint.activate([
      textView.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 16),
      textView.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -32),
      textView.centerYAnchor.constraint(equalTo: backView.centerYAnchor, constant: 0),
      textView.heightAnchor.constraint(equalToConstant: 60),
    ])

    NSLayoutConstraint.activate([
      clearButton.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -16),
      clearButton.topAnchor.constraint(equalTo: backView.topAnchor, constant: 16),
      clearButton.widthAnchor.constraint(equalToConstant: 16),
      clearButton.heightAnchor.constraint(equalToConstant: 16),
    ])
  }

  override open func disableSubmit() {
    rightNavBtn.setTitleColor(.funTeamThemeDisableColor, for: .normal)
    rightNavBtn.isEnabled = false
    customNavigationView.moreButton.setTitleColor(.funTeamThemeDisableColor, for: .normal)
    customNavigationView.moreButton.isEnabled = false
  }

  override open func enableSubmit() {
    rightNavBtn.setTitleColor(.funTeamThemeColor, for: .normal)
    rightNavBtn.isEnabled = true
    customNavigationView.moreButton.setTitleColor(.funTeamThemeColor, for: .normal)
    customNavigationView.moreButton.isEnabled = true
  }
}
