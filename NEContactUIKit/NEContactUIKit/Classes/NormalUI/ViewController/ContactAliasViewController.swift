
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import NECoreKit
import UIKit

@objcMembers
open class ContactAliasViewController: NEBaseContactAliasViewController {
  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if let useSystemNav = NEConfigManager.instance.getParameter(key: useSystemNav) as? Bool, useSystemNav {
      topConstant = 10
      aliasInputTopAnchor?.constant = topConstant
    }
  }

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

    aliasInputTopAnchor = aliasInput.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant + 10)
    aliasInputTopAnchor?.isActive = true
    NSLayoutConstraint.activate([
      aliasInput.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      aliasInput.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      aliasInput.heightAnchor.constraint(equalToConstant: 50),
    ])
  }
}
