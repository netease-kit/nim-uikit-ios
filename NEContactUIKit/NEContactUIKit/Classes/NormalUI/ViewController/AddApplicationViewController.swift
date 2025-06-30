
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import NECoreKit
import UIKit

@objcMembers
open class AddApplicationViewController: NEBaseAddApplicationViewController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
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

extension AddApplicationViewController {
  override open func tableView(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let noti = viewModel.friendAddApplications[indexPath.row]
    let reuseIdentifier = "\(SystemNotificationCell.self)"
    let cell = tableView.dequeueReusableCell(
      withIdentifier: reuseIdentifier,
      for: indexPath
    ) as! SystemNotificationCell
    cell.delegate = self
    cell.confige(application: noti)
    return cell
  }
}
