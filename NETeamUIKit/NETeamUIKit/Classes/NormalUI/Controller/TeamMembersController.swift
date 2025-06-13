// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class TeamMembersController: NEBaseTeamMembersController {
  override open func viewDidLoad() {
    super.viewDidLoad()
    navigationView.backgroundColor = .white
    navigationController?.navigationBar.backgroundColor = .white
    backView.backgroundColor = .ne_backcolor
    contentTableView.register(TeamMemberCell.self, forCellReuseIdentifier: "\(TeamMemberCell.self)")
  }

  override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(TeamMemberCell.self)",
      for: indexPath
    ) as? TeamMemberCell {
      if let model = getRealModel(indexPath.row) {
        var isShowRemove = false
        if isOwner(model.nimUser?.user?.accountId) {
          cell.ownerLabel.isHidden = false
          cell.ownerLabel.text = localizable("team_owner")
          cell.ownerWidth?.constant = NEAppLanguageUtil.getCurrentLanguage() == .english ? 86 : 40
        } else if model.teamMember?.memberRole == .TEAM_MEMBER_ROLE_MANAGER {
          cell.ownerLabel.isHidden = false
          cell.ownerLabel.text = localizable("team_manager")
          cell.ownerWidth?.constant = NEAppLanguageUtil.getCurrentLanguage() == .english ? 58 : 52
          if isOwner(IMKitClient.instance.account()) {
            isShowRemove = true
          }
        } else {
          if isOwner(IMKitClient.instance.account()) || viewModel.currentMember?.memberRole == .TEAM_MEMBER_ROLE_MANAGER {
            isShowRemove = true
          }
          cell.ownerLabel.isHidden = true
        }
        cell.index = indexPath.row
        cell.delegate = self
        cell.configure(model)
        cell.removeButton.isHidden = !isShowRemove
        cell.removeLabel.isHidden = !isShowRemove

//        if IMKitConfigCenter.shared.enableOnlineStatus {
//          cell.headerView.alpha = 0.5
//
//          if let accountId = model.nimUser?.user?.accountId {
//            if accountId == IMKitClient.instance.account() {
//              cell.headerView.alpha = 1.0
//            } else if let online = viewModel.onLineEventDic[accountId], online == true {
//              cell.headerView.alpha = 1.0
//            }
//
//            if NESubscribeManager.shared.getSubscribeStatus(accountId) == nil || NESubscribeManager.shared.outOfLimit() {
//              weak var weakSelf = self
//              NESubscribeManager.shared.subscribeUsersOnlineState([accountId]) { error in
//
//              }
//            }
//          }
//        }
      }

      return cell
    }
    return UITableViewCell()
  }

  override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    64.0
  }
}
