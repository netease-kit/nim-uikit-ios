
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class HistoryMediaResultController: NEBaseHistoryMediaResultController {
  override open func viewDidLoad() {
    super.viewDidLoad()
    emptyView.backgroundColor = .clear
    emptyView.setEmptyImage(name: "emptyView")
  }

  override open func setupUI() {
    super.setupUI()
  }

  override open func showAction(_ message: V2NIMMessage) {
    var actions = [UIAlertAction]()
    weak var weakSelf = self

    let copyAction = UIAlertAction(title: chatLocalizable("search_result_find_in_chat"), style: .default) { _ in
      weakSelf?.routerToMessage(message)
    }
    actions.append(copyAction)

    let forwardAction = UIAlertAction(title: chatLocalizable("operation_forward"), style: .default) { _ in
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        weakSelf?.showToast(commonLocalizable("network_error"))
        return
      }

      weakSelf?.forwardMessage(message)
    }
    actions.append(forwardAction)

    let cancelAction = UIAlertAction(title: commonLocalizable("cancel"), style: .cancel) { _ in }
    actions.append(cancelAction)

    showActionSheet(actions)
  }

  /// 获取转发确认弹窗 - 协同版
  override open func getForwardAlertController() -> NEBaseForwardAlertViewController {
    ForwardAlertViewController()
  }

  override public func didClickMoreAction(_ cell: NEHistorySearchFileCell, _ model: MessageFileModel?) {
    guard let model = model, let message = model.message else { return }

    var actions = [UIAlertAction]()
    weak var weakSelf = self

    let forwardAction = UIAlertAction(title: chatLocalizable("operation_forward"), style: .default) { _ in
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        weakSelf?.showToast(commonLocalizable("network_error"))
        return
      }

      weakSelf?.forwardMessage(message)
    }
    actions.append(forwardAction)

    let copyAction = UIAlertAction(title: chatLocalizable("operation_collection"), style: .default) { _ in
      weakSelf?.toCollectMessage(model)
    }
    actions.append(copyAction)

    let cancelAction = UIAlertAction(title: commonLocalizable("cancel"), style: .cancel) { _ in }
    actions.append(cancelAction)

    showActionSheet(actions)
  }
}
