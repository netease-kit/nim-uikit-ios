//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunTeamMemberSelectController: NEBaseTeamMemberSelectController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    cellClassDic[0] = FunTeamMemberSelectCell.self
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    navigationView.moreButton.setTitleColor(.funTeamThemeColor, for: .normal)
    // Do any additional setup after loading the view.
    emptyView.setEmptyImage(image: coreLoader.loadImage("fun_user_empty"))
  }

  override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "\(indexPath.section)", for: indexPath) as! FunTeamMemberSelectCell
    let member = viewmodel.showDatas[indexPath.row]
    cell.configureMember(member)
    return cell
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
