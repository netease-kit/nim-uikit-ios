
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

@objcMembers
open class SelectUserViewController: NEBaseSelectUserViewController {
  override open var searchIconName: String { "textField_search_icon" }
  override open var searchFieldBackgroundColor: UIColor { UIColor(hexString: "#F2F4F5") }
  override open var searchFieldTextColor: UIColor { .ne_darkText }
  override open var searchFieldFont: UIFont { .systemFont(ofSize: 14) }
  override open var searchFieldCornerRadius: CGFloat { 4 }
  override open var searchFieldHorizontalInset: CGFloat { 20 }
  override open var searchFieldHeight: CGFloat { 32 }
  override open var searchEmptyImageName: String { "user_empty" }

  override public init(conversationId: String, showSelf: Bool = true, showTeamMembers: Bool = false) {
    super.init(conversationId: conversationId, showSelf: showSelf, showTeamMembers: showTeamMembers)
    logClassName = "SelectUserViewController"
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
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
    if indexPath.section == 0 {
      cell.configureAll(
        title: chatLocalizable("user_select_all"),
        image: UIImage.ne_imageNamed(name: "chat_at_all")
      )
    } else {
      let member = visibleMembers[indexPath.row]
      cell.configure(member, searchResult: searchResult(for: member))
    }
    return cell
  }
}
