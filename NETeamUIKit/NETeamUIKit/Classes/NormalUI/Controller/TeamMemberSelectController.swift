//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class TeamMemberSelectController: NEBaseTeamMemberSelectController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    cellClassDic[0] = TeamMemberSelectCell.self
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    navigationView.backgroundColor = .white
    navigationView.moreButton.setTitleColor(.normalTeamBlueColor, for: .normal)
  }

  override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "\(indexPath.section)", for: indexPath) as! TeamMemberSelectCell
    let member = viewmodel.showDatas[indexPath.row]
    cell.configureMember(member)
    return cell
  }

  override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    52.0
  }
}
