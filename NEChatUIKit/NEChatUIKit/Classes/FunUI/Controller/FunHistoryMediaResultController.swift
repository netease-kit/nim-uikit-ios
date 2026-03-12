
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class FunHistoryMediaResultController: NEBaseHistoryMediaResultController {
  override open func viewDidLoad() {
    super.viewDidLoad()
    emptyView.backgroundColor = .clear
    emptyView.setEmptyImage(name: "fun_emptyView")
  }

  override open func setupUI() {
    super.setupUI()
  }

  override open func showAction(_ message: V2NIMMessage) {
    var actions = [NECustomAlertAction]()
    weak var weakSelf = self

    let copyAction = NECustomAlertAction(title: chatLocalizable("search_result_find_in_chat")) {
      weakSelf?.routerToMessage(message)
    }
    actions.append(copyAction)

    let forwardAction = NECustomAlertAction(title: chatLocalizable("operation_forward")) {
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        weakSelf?.showToast(commonLocalizable("network_error"))
        return
      }

      weakSelf?.forwardMessage(message)
    }
    actions.append(forwardAction)

    showCustomActionSheet(actions)
  }

  /// 获取转发确认弹窗 - 通用版
  override open func getForwardAlertController() -> NEBaseForwardAlertViewController {
    FunForwardAlertViewController()
  }

  override public func didClickMoreAction(_ cell: NEHistorySearchFileCell, _ model: MessageFileModel?) {
    guard let model = model, let message = model.message else { return }

    var actions = [NECustomAlertAction]()
    weak var weakSelf = self

    let forwardAction = NECustomAlertAction(title: chatLocalizable("operation_forward")) {
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        weakSelf?.showToast(commonLocalizable("network_error"))
        return
      }

      weakSelf?.forwardMessage(message)
    }
    actions.append(forwardAction)

    let copyAction = NECustomAlertAction(title: chatLocalizable("operation_collection")) {
      weakSelf?.toCollectMessage(model)
    }
    actions.append(copyAction)

    showCustomActionSheet(actions)
  }

  override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = super.tableView(tableView, cellForRowAt: indexPath) as! NEHistorySearchFileCell
    cell.avatarImageView.layer.cornerRadius = 4
    return cell
  }
}
