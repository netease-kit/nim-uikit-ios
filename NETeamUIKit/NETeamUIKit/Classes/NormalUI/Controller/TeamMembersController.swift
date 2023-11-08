// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class TeamMembersController: NEBaseTeamMembersController {
  override open func viewDidLoad() {
    super.viewDidLoad()
    customNavigationView.backgroundColor = .white
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
        cell.configure(model)
        cell.ownerLabel.isHidden = !isOwner(model.nimUser?.userId)
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
