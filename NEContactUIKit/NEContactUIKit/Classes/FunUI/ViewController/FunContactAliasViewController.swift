// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import NECoreKit
import UIKit

@objcMembers
open class FunContactAliasViewController: NEBaseContactAliasViewController {
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

    aliasInputTopAnchor = aliasInput.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant)
    aliasInputTopAnchor?.isActive = true
    NSLayoutConstraint.activate([
      aliasInput.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
      aliasInput.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
      aliasInput.heightAnchor.constraint(equalToConstant: 60),
    ])
  }
}
