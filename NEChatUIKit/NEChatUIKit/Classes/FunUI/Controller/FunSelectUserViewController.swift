
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import UIKit

@objcMembers
open class FunSelectUserViewController: NEBaseSelectUserViewController {
  override init(conversationId: String, showSelf: Bool = true, showTeamMembers: Bool = false) {
    super.init(conversationId: conversationId, showSelf: showSelf, showTeamMembers: showTeamMembers)
    className = "FunSelectUserViewController"
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func commonUI() {
    super.commonUI()

    tableView.register(
      FunChatTeamMemberCell.self,
      forCellReuseIdentifier: "\(FunChatTeamMemberCell.self)"
    )
    tableView.rowHeight = 64
  }

  override open func tableView(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(FunChatTeamMemberCell.self)",
      for: indexPath
    ) as! FunChatTeamMemberCell
    if indexPath.section == 0 {
      cell.headerView.image = UIImage.ne_imageNamed(name: "fun_all")
      cell.nameLabel.text = chatLocalizable("user_select_all")
    } else {
      if let model = teamInfo?.users[indexPath.row] {
        cell.configure(model)
      }
    }
    return cell
  }
}
