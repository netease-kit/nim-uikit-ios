// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class BotSubSessionListViewController: NEBaseBotSubSessionListViewController {
  override public init(conversationId: String, sessionId: String, sessionName: String) {
    super.init(conversationId: conversationId, sessionId: sessionId, sessionName: sessionName)
    deleteButtonBackgroundColor = NEConstant.hexRGB(0xA8ABB6)
    renameButtonBackgroundColor = NEConstant.hexRGB(0x337EFF)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func setupUI() {
    super.setupUI()
    navigationView.backgroundColor = .white
    navigationController?.navigationBar.backgroundColor = .white
    tableView.backgroundColor = .white
  }

  override open var defaultEmptyImageName: String {
    "user_empty"
  }

  override open func enterTopic(_ topic: V2NIMTopic?) {
    let controller = BotSubSessionChatViewController(conversationId: conversationId,
                                                     sessionId: sessionId,
                                                     sessionName: sessionName,
                                                     topic: topic)
    if let vm = controller.viewModel as? TopicChatViewModel {
      vm.delegate = controller
    }
    navigationController?.pushViewController(controller, animated: true)
  }

  override open func getUserSettingViewController() -> NEBaseUserSettingViewController? {
    UserSettingViewController(userId: sessionId)
  }
}
