// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECoreIMKit
import NECoreKit
import NIMSDK

@objcMembers
open class FunContactUserViewController: NEBaseContactUserViewController {
  func initFun() {
    className = "FunContactUserViewController"
    headerView = FunUserInfoHeaderView()
  }

  override public init(user: User?) {
    super.init(user: user)
    initFun()
  }

  override public init(uid: String) {
    super.init(uid: uid)
    initFun()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func commonUI() {
    super.commonUI()
    tableView.rowHeight = 46
  }

  override open func tableView(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let item = data[indexPath.section][indexPath.row]
    let cell = super.tableView(tableView, cellForRowAt: indexPath)
    if let c = cell as? CenterTextCell, item.title == localizable("chat") || item.title == localizable("add_friend") {
      c.titleLabel.textColor = .funContactUserViewChatTitleTextColor
      return c
    }
    if let c = cell as? TextWithSwitchCell {
      c.switchButton.onTintColor = .funContactThemeColor
      return c
    }
    return cell
  }

  open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let item = data[indexPath.section][indexPath.row]
    if item.title == localizable("sign") {
      return 66
    }
    return 46
  }

  override public func getContactRemakNameViewController() -> NEBaseContactRemakNameViewController {
    FunContactRemakNameViewController()
  }

  override public func deleteFriend(user: User?) {
    let titleAction = NECustomAlertAction(title: localizable("delete_title").replacingOccurrences(of: "XXX", with: user?.showName(true) ?? "")) {}
    titleAction.contentText.font = .systemFont(ofSize: 13)
    titleAction.contentText.textColor = UIColor(hexString: "#8F8F8F")

    let deleteAction = NECustomAlertAction(title: localizable("delete_friend")) { [weak self] in
      self?.deleteFriendAction(user: user)
    }
    deleteAction.contentText.textColor = .ne_redText

    showCustomActionSheet([titleAction, deleteAction])
  }
}
