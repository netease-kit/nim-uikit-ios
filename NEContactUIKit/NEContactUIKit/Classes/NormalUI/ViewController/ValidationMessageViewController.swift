
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import NECoreKit
import UIKit

@objcMembers
open class ValidationMessageViewController: NEBaseValidationMessageViewController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func initNav() {
    super.initNav()
    let clearItem = UIBarButtonItem(
      title: localizable("clear"),
      style: .done,
      target: self,
      action: #selector(toSetting)
    )
    clearItem.tintColor = .ne_darkText
    var textAttributes = [NSAttributedString.Key: Any]()
    textAttributes[.font] = UIFont.systemFont(ofSize: 14, weight: .regular)

    clearItem.setTitleTextAttributes(textAttributes, for: .normal)
    navigationItem.rightBarButtonItem = clearItem

    navigationView.moreButton.titleLabel?.font = .systemFont(ofSize: 16)
  }

  override open func setupUI() {
    super.setupUI()
    navigationView.backgroundColor = .white
    navigationController?.navigationBar.backgroundColor = .white

    tableView.register(
      SystemNotificationCell.self,
      forCellReuseIdentifier: "\(SystemNotificationCell.self)"
    )
  }
}

extension ValidationMessageViewController {
  override open func tableView(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let noti = viewModel.datas[indexPath.row]
    let reuseIdentifier = "\(SystemNotificationCell.self)"
    let cell = tableView.dequeueReusableCell(
      withIdentifier: reuseIdentifier,
      for: indexPath
    ) as! SystemNotificationCell
    cell.delegate = self
    cell.confige(noti)
    return cell
  }
}
