
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class HistoryMessageController: NEBaseHistorySearchController {
  override public init(conversationId: String) {
    super.init(conversationId: conversationId)
    viewModel.themeColor = .ne_normalTheme
    tag = "TeamHistoryMessageController"
    cellRegisterDic = ChatMessageHelper.getChatCellRegisterDic(isFun: false)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func setupSubviews() {
    super.setupSubviews()
    navigationView.backgroundColor = .white
    navigationController?.navigationBar.backgroundColor = .white

    NSLayoutConstraint.activate([
      searchTextField.topAnchor.constraint(
        equalTo: view.topAnchor,
        constant: NEConstant.navigationHeight + NEConstant.statusBarHeight + 20
      ),
      searchTextField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      searchTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      searchTextField.heightAnchor.constraint(equalToConstant: 32),
    ])

    collectionView.register(NormalSearchMessageOperationCell.self, forCellWithReuseIdentifier: NormalSearchMessageOperationCell.className())

    tableViewTopAnchor?.constant = 50
  }

  override public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard indexPath.row < viewModel.operationTypes.count else {
      return UICollectionViewCell()
    }

    let model = viewModel.operationTypes[indexPath.row]
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NormalSearchMessageOperationCell.className(), for: indexPath) as! NormalSearchMessageOperationCell
    cell.model = model
    return cell
  }

  open func getMessageModel(model: MessageModel) {
    if model.isReply {
      let normalMoreHeight = chat_reply_height + chat_content_margin
      model.contentSize = CGSize(
        width: model.contentSize.width,
        height: model.contentSize.height + normalMoreHeight
      )
      model.height += normalMoreHeight
    }
  }

  override open func searchTeamMemberAction() {
    if let conversationId = conversationId,
       let teamId = V2NIMConversationIdUtil.conversationTargetId(conversationId) {
      let teamMemberSearchVC = HistoryMessageMemberController(conversationId: conversationId)
      let callback: NESelectTeamMemberBlock = { [weak self] datas in
        if let accountId = datas.first?.nimUser?.user?.accountId {
          if let count = self?.navigationController?.viewControllers.count, count > 0 {
            self?.navigationController?.viewControllers.insert(teamMemberSearchVC, at: count - 1)
          }

          self?.navigationController?.popViewController(animated: true)

          let params = V2NIMMessageSearchExParams()
          params.senderAccountIds = [accountId]
          teamMemberSearchVC.messageSearchExParams = params
          teamMemberSearchVC.loadData(params, true)
        }
      }

      Router.shared.use(TeamMemberSelectViewRouter, parameters: ["nav": navigationController as Any,
                                                                 "teamId": teamId,
                                                                 "navTitle": chatLocalizable("group_memmber"),
                                                                 "memberLimit": 1,
                                                                 "showAllMembers": true,
                                                                 "selectMemberBlock": callback])
    }
  }

  override open func searchImageAction() {
    let mediaSearchVC = HistoryMediaResultController()
    navigationController?.pushViewController(mediaSearchVC, animated: true)
  }

  override open func searchVideoAction() {
    let mediaSearchVC = HistoryMediaResultController()
    mediaSearchVC.searchType = .video
    navigationController?.pushViewController(mediaSearchVC, animated: true)
  }

  override open func searchDateAction() {
    let datePickerVC = NEHistoryDatePickerViewController()
    datePickerVC.selectButtonBackgroundColor = UIColor.normalSearchDateButtonBg
    datePickerVC.delegate = self
    navigationController?.pushViewController(datePickerVC, animated: true)
  }

  override open func searchFileAction() {
    let mediaSearchVC = HistoryMediaResultController()
    mediaSearchVC.searchType = .file
    navigationController?.pushViewController(mediaSearchVC, animated: true)
  }
}
