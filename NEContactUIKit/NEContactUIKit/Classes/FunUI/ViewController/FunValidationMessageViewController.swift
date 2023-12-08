
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIMKit
import NECoreKit
import UIKit

@objcMembers
open class FunValidationMessageViewController: NEBaseValidationMessageViewController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    tag = "FunValidationMessageViewController"
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func setupUI() {
    super.setupUI()
    let clearItem = UIBarButtonItem(
      title: localizable("clear"),
      style: .done,
      target: self,
      action: #selector(clearMessage)
    )
    clearItem.tintColor = .ne_darkText
    let textAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 16, weight: .regular)]

    clearItem.setTitleTextAttributes(textAttributes, for: .normal)
    navigationItem.rightBarButtonItem = clearItem

    navigationView.moreButton.titleLabel?.font = .systemFont(ofSize: 16)

    tableView.register(
      FunSystemNotificationCell.self,
      forCellReuseIdentifier: "\(FunSystemNotificationCell.self)"
    )

    emptyView.setEmptyImage(name: "fun_user_empty")
  }
}

extension FunValidationMessageViewController {
  override open func tableView(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let noti = viewModel.datas[indexPath.row]
    let reuseIdentifier = "\(FunSystemNotificationCell.self)"
    let cell = tableView.dequeueReusableCell(
      withIdentifier: reuseIdentifier,
      for: indexPath
    ) as! FunSystemNotificationCell
    cell.delegate = self
    cell.confige(noti)
    return cell
  }
}
