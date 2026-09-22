// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEBaseUIKit
import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class FunBotSubSessionListViewController: NEBaseBotSubSessionListViewController {
  override public init(conversationId: String, sessionId: String, sessionName: String) {
    super.init(conversationId: conversationId, sessionId: sessionId, sessionName: sessionName)
    deleteButtonBackgroundColor = UIColor(hexString: "#E75E58")
    renameButtonBackgroundColor = NEConstant.hexRGB(0x337EFF)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open var pageBackgroundColor: UIColor {
    .funChatBackgroundColor
  }

  override open var listItemBackgroundColor: UIColor {
    .white
  }

  override open var showsListItemDivider: Bool {
    true
  }

  override open var emptyActionTitleColor: UIColor {
    .funChatThemeColor
  }

  override open var defaultEmptyImageName: String {
    "fun_user_empty"
  }

  override open var emptyActionBackgroundColor: UIColor {
    .white
  }

  override open var searchHighlightColor: UIColor {
    .funChatThemeColor
  }

  override open var searchEmptyImageName: String {
    "fun_emptyView"
  }

  override open func setupUI() {
    super.setupUI()
    view.backgroundColor = pageBackgroundColor
    applyFunBotSubSessionListBackground()
    tableView.backgroundColor = pageBackgroundColor
    tableView.rowHeight = 64
    tableViewTopAnchor?.constant = listTopSpacing
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    applyFunBotSubSessionListBackground()
    tableViewTopAnchor?.constant = listTopSpacing
  }

  open func applyFunBotSubSessionListBackground() {
    navigationView.backgroundColor = pageBackgroundColor
    navigationView.titleBarBottomLine.backgroundColor = .funChatNavigationDivideBg
    navigationController?.navigationBar.backgroundColor = pageBackgroundColor
    if #available(iOS 13.0, *) {
      let appearance = UINavigationBarAppearance()
      appearance.configureWithOpaqueBackground()
      appearance.backgroundColor = pageBackgroundColor
      appearance.shadowColor = .funChatNavigationDivideBg
      navigationController?.navigationBar.standardAppearance = appearance
      navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
  }

  override open func enterTopic(_ topic: V2NIMTopic?) {
    let controller = FunBotSubSessionChatViewController(conversationId: conversationId,
                                                        sessionId: sessionId,
                                                        sessionName: sessionName,
                                                        topic: topic)
    if let vm = controller.viewModel as? TopicChatViewModel {
      vm.delegate = controller
    }
    navigationController?.pushViewController(controller, animated: true)
  }

  override open func showRenameAlert(topic: V2NIMTopic) {
    let topicName = topic.topicName?.trimmingCharacters(in: .whitespacesAndNewlines)
    let displayName = (topicName?.isEmpty == false) ? topicName! : chatLocalizable("bot_sub_session_new_conversation")
    let controller = BotSubSessionRenameDialogController(name: displayName, saveButtonBackgroundColor: UIColor(hexString: "#58BE6B"))
    controller.onSave = { [weak self, weak controller] (name: String) in
      if name.isEmpty {
        self?.showToast(chatLocalizable("bot_sub_session_input_name"))
        return
      }
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        self?.showToast(commonLocalizable("network_error"))
        return
      }
      self?.viewModel.updateTopicName(topic: topic, topicName: name) { _, error in
        if error != nil {
          self?.showToast(chatLocalizable("bot_sub_session_rename_failed"))
        } else {
          controller?.dismiss(animated: false)
        }
      }
    }
    present(controller, animated: false)
  }

  override open func showDeleteAlert(topic: V2NIMTopic) {
    let topicName = topic.topicName?.trimmingCharacters(in: .whitespacesAndNewlines)
    let displayName = (topicName?.isEmpty == false) ? topicName! : chatLocalizable("bot_sub_session_new_conversation")
    let controller = BotSubSessionDeleteDialogController(title: chatLocalizable("bot_sub_session_delete_title"), message: String(format: chatLocalizable("bot_sub_session_delete_topic"), displayName), confirmButtonBackgroundColor: UIColor(hexString: "#58BE6B"))
    controller.onDelete = { [weak self, weak controller] in
      controller?.dismiss(animated: false)
      self?.viewModel.removeTopic(topic: topic) { error in
        if error != nil {
          self?.showToast(chatLocalizable("bot_sub_session_delete_failed"))
        }
      }
    }
    present(controller, animated: false)
  }

  override open func getUserSettingViewController() -> NEBaseUserSettingViewController? {
    FunUserSettingViewController(userId: sessionId)
  }
}
