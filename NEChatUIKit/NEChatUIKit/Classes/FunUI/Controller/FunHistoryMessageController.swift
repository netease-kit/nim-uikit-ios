
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEBaseUIKit
import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class FunHistoryMessageController: NEBaseHistorySearchController {
  /// 返回按钮：统一返回箭头，原「取消」文案只保留为无障碍标签
  public lazy var cancelButton: NEUnifiedBackButton = {
    let button = NEUnifiedBackButton(accessibilityLabel: commonLocalizable("cancel"))
    button.addTarget(self, action: #selector(backEvent), for: .touchUpInside)
    return button
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

  /// 搜索框左间距约束：侧栏承载时页面返回入口被侧栏接管，需要收回到 12。
  private var searchTextFieldLeftAnchor: NSLayoutConstraint?

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .funChatBackgroundColor
    navigationController?.isNavigationBarHidden = true
    navigationView.isHidden = true
    emptyView.backgroundColor = .funChatBackgroundColor
    emptyView.setEmptyImage(name: "fun_emptyView")
  }

  override open func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updateSearchFieldLeftInset()
  }

  /// 侧栏承载时返回入口由侧栏展示，页面原按钮按 alpha=0 隐藏；
  /// 此处把搜索框左间距从「返回按钮 + 间距」收回到 12，避免留下不可见的空位。
  private func updateSearchFieldLeftInset() {
    guard let searchTextFieldLeftAnchor else { return }
    let hasPageBackEntry = !cancelButton.isHidden && cancelButton.alpha > 0.01
    let inset: CGFloat = hasPageBackEntry ? 58 : 12
    if abs(searchTextFieldLeftAnchor.constant - inset) > 0.5 {
      searchTextFieldLeftAnchor.constant = inset
    }
  }

  override open func setupSubviews() {
    super.setupSubviews()

    // 返回入口统一放在左侧，搜索框紧随其后，避免箭头出现在右侧产生方向歧义。
    view.addSubview(cancelButton)
    NSLayoutConstraint.activate([
      cancelButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
      cancelButton.centerYAnchor.constraint(equalTo: searchTextField.centerYAnchor),
    ])

    let leftImageView = UIImageView(image: coreLoader.loadImage("fun_search"))
    searchTextField.leftView = leftImageView
    searchTextField.font = UIFont.systemFont(ofSize: 16)
    searchTextField.textColor = .black
    searchTextField.layer.cornerRadius = 4
    searchTextField.backgroundColor = .white
    let searchTextFieldLeftAnchor = searchTextField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 58)
    self.searchTextFieldLeftAnchor = searchTextFieldLeftAnchor
    NSLayoutConstraint.activate([
      searchTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: NEConstant.statusBarHeight + 12),
      searchTextFieldLeftAnchor,
      searchTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -12),
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
