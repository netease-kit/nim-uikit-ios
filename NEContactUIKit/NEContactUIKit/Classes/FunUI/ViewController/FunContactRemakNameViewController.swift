// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIMKit
import NECoreKit
import UIKit

@objcMembers
open class FunContactRemakNameViewController: NEBaseContactRemakNameViewController {
  override func setupUI() {
    super.setupUI()
    let clearItem = UIBarButtonItem(
      title: localizable("save"),
      style: .done,
      target: self,
      action: #selector(saveAlias)
    )
    clearItem.tintColor = .funContactThemeColor
    navigationItem.rightBarButtonItem = clearItem

    navigationView.moreButton.setTitleColor(.funContactThemeColor, for: .normal)

    NSLayoutConstraint.activate([
      aliasInput.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
      aliasInput.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
      aliasInput.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      aliasInput.heightAnchor.constraint(equalToConstant: 60),
    ])
  }
}
