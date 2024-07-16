
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECoreIM2Kit
import NECoreKit
import UIKit

@objcMembers
open class BlackListViewController: NEBaseBlackListViewController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func commonUI() {
    super.commonUI()
    navigationView.backgroundColor = .white
    navigationController?.navigationBar.backgroundColor = .white

    tableView.register(
      BlackListCell.self,
      forCellReuseIdentifier: "\(NSStringFromClass(BlackListCell.self))"
    )
    tableView.rowHeight = 62
  }

  /// 黑名单选择页面
  /// - Returns: 人员选择控制器
  override open func getContactSelectVC() -> NEBaseContactSelectedViewController {
    var filterUsers = Set<String>()
    filterUsers.insert(IMKitClient.instance.account())
    return ContactSelectedViewController(filterUsers: filterUsers)
  }

  override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(NSStringFromClass(BlackListCell.self))",
      for: indexPath
    ) as! BlackListCell
    cell.delegate = self
    cell.index = indexPath.row
    cell.setModel(viewModel.blockList[indexPath.row] as Any)
    return cell
  }
}
