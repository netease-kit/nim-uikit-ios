//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class AIUserController: NEBaseAIUserController {
  override open func viewDidLoad() {
    super.viewDidLoad()
    navigationView.backgroundColor = .white
    navigationController?.navigationBar.backgroundColor = .white
    backView.backgroundColor = .ne_backcolor
    aiUserTableView.register(AIUserListCell.self, forCellReuseIdentifier: "\(AIUserListCell.self)")
  }

  override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(AIUserListCell.self)",
      for: indexPath
    ) as? AIUserListCell {
      if let model = getRealAIUserModel(indexPath.row) {
        cell.configure(model)

        return cell
      }
    }
    return UITableViewCell()
  }

  override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    64.0
  }
}
