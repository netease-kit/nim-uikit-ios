
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIMKit
import UIKit

@objcMembers
open class SelectUserViewController: NEBaseSelectUserViewController {
  override init(sessionId: String, showSelf: Bool = true) {
    super.init(sessionId: sessionId, showSelf: showSelf)
    className = "SelectUserViewController"
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func commonUI() {
    super.commonUI()

    tableView.register(
      ChatTeamMemberCell.self,
      forCellReuseIdentifier: "\(ChatTeamMemberCell.self)"
    )
    tableView.rowHeight = 62
  }

  override open func tableView(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(ChatTeamMemberCell.self)",
      for: indexPath
    ) as! ChatTeamMemberCell
    if indexPath.row == 0 {
      cell.headerView.image = UIImage.ne_imageNamed(name: "chat_team")
      cell.nameLabel.text = chatLocalizable("user_select_all")
    } else {
      if let model = teamInfo?.users[indexPath.row - 1] {
        cell.configure(model)
      }
    }
    return cell
  }
}
