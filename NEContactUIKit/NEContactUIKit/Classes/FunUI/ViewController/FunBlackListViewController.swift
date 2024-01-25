
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECoreIMKit
import NECoreKit
import UIKit

@objcMembers
open class FunBlackListViewController: NEBaseBlackListViewController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    className = "FunBlackListViewController"
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func commonUI() {
    super.commonUI()
    tableView.register(
      FunBlackListCell.self,
      forCellReuseIdentifier: "\(NSStringFromClass(FunBlackListCell.self))"
    )
    tableView.rowHeight = 64
  }

  override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(NSStringFromClass(FunBlackListCell.self))",
      for: indexPath
    ) as! FunBlackListCell
    cell.delegate = self
    cell.index = indexPath.row
    cell.setModel(blackList?[indexPath.row] as Any)
    return cell
  }

  override open func getContactSelectVC() -> NEBaseContactsSelectedViewController {
    FunContactsSelectedViewController()
  }
}
