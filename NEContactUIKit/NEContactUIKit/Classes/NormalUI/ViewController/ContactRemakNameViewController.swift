
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIMKit
import NECoreKit
import UIKit

@objcMembers
open class ContactRemakNameViewController: NEBaseContactRemakNameViewController {
  override func setupUI() {
    super.setupUI()
    aliasInput.layer.cornerRadius = 8

    let clearItem = UIBarButtonItem(
      title: localizable("save"),
      style: .done,
      target: self,
      action: #selector(saveAlias)
    )
    clearItem.tintColor = UIColor(hexString: "337EFF")
    navigationItem.rightBarButtonItem = clearItem

    NSLayoutConstraint.activate([
      aliasInput.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      aliasInput.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      aliasInput.topAnchor.constraint(equalTo: view.topAnchor, constant: 10 + topConstant),
      aliasInput.heightAnchor.constraint(equalToConstant: 50),
    ])
  }
}
