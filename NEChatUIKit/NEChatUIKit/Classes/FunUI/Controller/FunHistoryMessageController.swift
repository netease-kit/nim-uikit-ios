
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class FunHistoryMessageController: NEBaseHistorySearchController {
  public lazy var cancelButton: ExpandButton = {
    let cancelButton = ExpandButton()
    cancelButton.translatesAutoresizingMaskIntoConstraints = false
    cancelButton.setTitle(commonLocalizable("cancel"), for: .normal)
    cancelButton.setTitleColor(.ne_greyText, for: .normal)
    cancelButton.addTarget(self, action: #selector(backEvent), for: .touchUpInside)
    return cancelButton
  }()

  public lazy var searchView: FunSearchView = {
    let view = FunSearchView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.searchButton.setImage(coreLoader.loadImage("fun_search"), for: .normal)
    view.searchButton.setTitle(chatLocalizable("search"), for: .normal)
    return view
  }()

  override public init(conversationId: String) {
    super.init(conversationId: conversationId)
    viewModel.themeColor = .ne_funTheme
    layout.itemSize = CGSize(width: 90, height: 48)
    tag = "FunTeamHistoryMessageController"
    cellRegisterDic = ChatMessageHelper.getChatCellRegisterDic(isFun: true)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .funChatBackgroundColor
    navigationController?.isNavigationBarHidden = true
    navigationView.isHidden = true
    emptyView.backgroundColor = .funChatBackgroundColor
    emptyView.setEmptyImage(name: "fun_emptyView")
  }

  override open func setupSubviews() {
    super.setupSubviews()

    view.addSubview(cancelButton)
    NSLayoutConstraint.activate([
      cancelButton.centerYAnchor.constraint(equalTo: searchTextField.centerYAnchor),
      cancelButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -12),
      cancelButton.widthAnchor.constraint(equalToConstant: NEAppLanguageUtil.getCurrentLanguage() == .english ? 60 : 40),
    ])

    let leftImageView = UIImageView(image: coreLoader.loadImage("fun_search"))
    searchTextField.leftView = leftImageView
    searchTextField.font = UIFont.systemFont(ofSize: 16)
    searchTextField.textColor = .black
    searchTextField.layer.cornerRadius = 4
    searchTextField.backgroundColor = .white
    NSLayoutConstraint.activate([
      searchTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: NEConstant.statusBarHeight + 12),
      searchTextField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8),
      searchTextField.rightAnchor.constraint(equalTo: cancelButton.leftAnchor, constant: -8),
      searchTextField.heightAnchor.constraint(equalToConstant: 36),
    ])

    collectionView.backgroundColor = .funChatBackgroundColor
    collectionView.register(FunSearchMessageOperationCell.self, forCellWithReuseIdentifier: FunSearchMessageOperationCell.className())
    view.updateLayoutConstraint(firstItem: tipLable, secondItem: searchTextField, attribute: .top, constant: 60)
    view.updateLayoutConstraint(firstItem: view, secondItem: collectionView, attribute: .left, constant: 48)
    view.updateLayoutConstraint(firstItem: view, secondItem: collectionView, attribute: .right, constant: -48)
    view.updateLayoutConstraint(firstItem: collectionView, secondItem: tipLable, attribute: .top, constant: 28)

    tableView.backgroundColor = .funChatBackgroundColor
    tableViewTopAnchor?.constant = 48
  }

  override public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard indexPath.row < viewModel.operationTypes.count else {
      return UICollectionViewCell()
    }

    let model = viewModel.operationTypes[indexPath.row]
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FunSearchMessageOperationCell.className(), for: indexPath) as! FunSearchMessageOperationCell
    cell.model = model
    if (indexPath.row % 3) == 2 {
      cell.lineView.isHidden = true
    } else {
      cell.lineView.isHidden = false
    }
    return cell
  }

  open func getMessageModel(model: MessageModel) {
    if model.type == .tip || model.type == .notification {
      return
    }

    let contentWidth = model.contentSize.width
    let contentHeight = model.contentSize.height
    var subHeight: CGFloat = 0
    if contentHeight < fun_chat_min_h {
      subHeight = fun_chat_min_h - contentHeight
      model.contentSize = CGSize(width: contentWidth, height: fun_chat_min_h)
      model.offset = CGFloat(subHeight)
    }

    if model.isReply {
      model.offset = subHeight + fun_chat_reply_height + chat_content_margin
    }

    if model.type == .rtcCallRecord {
      model.contentSize = CGSize(width: contentWidth, height: contentHeight - 2)
      model.offset = -2
    }
  }

  override open func searchTeamMemberAction() {
    if let conversationId = conversationId,
       let teamId = V2NIMConversationIdUtil.conversationTargetId(conversationId) {
      let teamMemberSearchVC = FunHistoryMessageMemberController(conversationId: conversationId)
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
    let mediaSearchVC = FunHistoryMediaResultController()
    navigationController?.pushViewController(mediaSearchVC, animated: true)
  }

  override open func searchVideoAction() {
    let mediaSearchVC = FunHistoryMediaResultController()
    mediaSearchVC.searchType = .video
    navigationController?.pushViewController(mediaSearchVC, animated: true)
  }

  override open func searchDateAction() {
    let datePickerVC = NEHistoryDatePickerViewController()
    datePickerVC.selectButtonBackgroundColor = UIColor.ne_funTheme
    datePickerVC.delegate = self
    navigationController?.pushViewController(datePickerVC, animated: true)
  }

  override open func searchFileAction() {
    let mediaSearchVC = FunHistoryMediaResultController()
    mediaSearchVC.searchType = .file
    navigationController?.pushViewController(mediaSearchVC, animated: true)
  }
}
