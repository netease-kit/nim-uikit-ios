// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NIMSDK
import UIKit

@objcMembers
open class FunTeamMembersController: NEBaseTeamMembersController {
  let searchGrayBackView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.funTeamBackgroundColor
    return view
  }()

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .funTeamBackgroundColor
    contentTableView.register(FunTeamMemberCell.self, forCellReuseIdentifier: "\(FunTeamMemberCell.self)")
    view.insertSubview(searchGrayBackView, belowSubview: backView)
    NSLayoutConstraint.activate([
      searchGrayBackView.leftAnchor.constraint(equalTo: view.leftAnchor),
      searchGrayBackView.rightAnchor.constraint(equalTo: view.rightAnchor),
      searchGrayBackView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      searchGrayBackView.bottomAnchor.constraint(equalTo: contentTableView.topAnchor),
    ])
    backView.backgroundColor = UIColor.white
    searchTextField.backgroundColor = UIColor.white

    emptyView.setEmptyImage(name: "fun_user_empty")
  }

  override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(FunTeamMemberCell.self)",
      for: indexPath
    ) as? FunTeamMemberCell {
      if let model = getRealModel(indexPath.row) {
        cell.configure(model)
        var isShowRemove = false
        if isOwner(model.nimUser?.user?.accountId) {
          cell.ownerLabel.isHidden = false
          cell.ownerLabel.text = localizable("team_owner")
          cell.setOwnerStyle()
        } else if model.teamMember?.memberRole == .TEAM_MEMBER_ROLE_MANAGER {
          cell.ownerLabel.isHidden = false
          cell.ownerLabel.text = localizable("team_manager")
          cell.setManagerStyle()
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

        if IMKitConfigCenter.shared.onlineStatusEnable {
          cell.headerView.alpha = 0.5

          if let accountId = model.nimUser?.user?.accountId {
            if accountId == IMKitClient.instance.account() {
              cell.headerView.alpha = 1.0
            } else if let event = viewModel.onLineEventDic[accountId] {
              if event.value == NIMSubscribeEventOnlineValue.login.rawValue {
                cell.headerView.alpha = 1.0
              }
            }
          }
        }
      }

      if isLastRow(indexPath.row) {
        cell.dividerLine.isHidden = true
      } else {
        cell.dividerLine.isHidden = false
      }

      return cell
    }
    return UITableViewCell()
  }

  override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    64.0
  }

  func isLastRow(_ index: Int) -> Bool {
    if let text = searchTextField.text, text.count > 0 {
      if viewModel.searchDatas.count - 1 == index {
        return true
      }
    }
    if viewModel.datas.count - 1 == index {
      return true
    }
    return false
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
