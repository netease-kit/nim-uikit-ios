// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class TeamMembersController: NEBaseTeamMembersController {
  override open func viewDidLoad() {
    super.viewDidLoad()
    navigationView.backgroundColor = .white
    navigationController?.navigationBar.backgroundColor = .white
    back.backgroundColor = .ne_backcolor
    contentTable.register(TeamMemberCell.self, forCellReuseIdentifier: "\(TeamMemberCell.self)")
  }

  override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(TeamMemberCell.self)",
      for: indexPath
    ) as? TeamMemberCell {
      if let model = getRealModel(indexPath.row) {
        var isShowRemove = false
        if isOwner(model.nimUser?.userId) {
          cell.ownerLabel.isHidden = false
          cell.ownerLabel.text = localizable("team_owner")
          cell.ownerWidth?.constant = 40
        } else if model.teamMember?.type == .manager {
          cell.ownerLabel.isHidden = false
          cell.ownerLabel.text = localizable("team_manager")
          cell.ownerWidth?.constant = 52
          if isOwner(IMKitClient.instance.imAccid()) {
            isShowRemove = true
          }
        } else {
          if isOwner(IMKitClient.instance.imAccid()) || viewmodel.currentMember?.type == .manager {
            isShowRemove = true
          }
          cell.ownerLabel.isHidden = true
        }
        cell.index = indexPath.row
        cell.delegate = self
        cell.configure(model)
        cell.removeBtn.isHidden = !isShowRemove
        cell.removeLabel.isHidden = !isShowRemove
      }
      return cell
    }
    return UITableViewCell()
  }

  override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    64.0
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       // Get the new view controller using segue.destination.
       // Pass the selected object to the new view controller.
   }
   */
}
