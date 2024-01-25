
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECoreIMKit
import NECoreKit
import UIKit

@objcMembers
open class BlackListViewController: NEBaseBlackListViewController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    className = "BlackListViewController"
    navigationView.backgroundColor = .white
    navigationController?.navigationBar.backgroundColor = .white
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func commonUI() {
    super.commonUI()
    tableView.register(
      BlackListCell.self,
      forCellReuseIdentifier: "\(NSStringFromClass(BlackListCell.self))"
    )
    tableView.rowHeight = 62
  }

  override open func getContactSelectVC() -> NEBaseContactsSelectedViewController {
    ContactsSelectedViewController()
  }

  override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(NSStringFromClass(BlackListCell.self))",
      for: indexPath
    ) as! BlackListCell
    cell.delegate = self
    cell.index = indexPath.row
    cell.setModel(blackList?[indexPath.row] as Any)
    return cell
  }
}
