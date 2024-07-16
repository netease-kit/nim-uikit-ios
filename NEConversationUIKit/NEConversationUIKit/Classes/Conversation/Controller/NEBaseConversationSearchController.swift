
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseConversationSearchController: NEConversationBaseViewController, UITableViewDelegate,
  UITableViewDataSource {
  var viewModel = ConversationSearchViewModel()
  var tag = "ConversationSearchBaseController"
  var searchStr = ""
  var headTitleArr = [localizable("friend")]

  public lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.rowHeight = 60
    tableView.backgroundColor = .white
    tableView.sectionHeaderHeight = 30
    tableView.sectionFooterHeight = 0
    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
    tableView.keyboardDismissMode = .onDrag

    if #available(iOS 11.0, *) {
      tableView.estimatedRowHeight = 0
      tableView.estimatedSectionHeaderHeight = 0
      tableView.estimatedSectionFooterHeight = 0
    }
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }
    return tableView
  }()

  public var searchTextFieldTopAnchor: NSLayoutConstraint?
  public lazy var searchTextField: SearchTextField = {
    let textField = SearchTextField()
    let leftImageView = UIImageView(image: UIImage
      .ne_imageNamed(name: "conversation_search_icon"))
    textField.contentMode = .center
    textField.leftView = leftImageView
    textField.leftViewMode = .always
    textField.placeholder = commonLocalizable("search")
    textField.font = UIFont.systemFont(ofSize: 14)
    textField.textColor = UIColor.ne_greyText
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.layer.cornerRadius = 8
    textField.backgroundColor = .ne_lightBackgroundColor
    textField.clearButtonMode = .always
    textField.returnKeyType = .search
    textField.addTarget(self, action: #selector(searchTextFieldChange), for: .editingChanged)

    if let clearButton = textField.value(forKey: "_clearButton") as? UIButton {
      clearButton.accessibilityIdentifier = "id.clear"
    }
    textField.accessibilityIdentifier = "id.search"
    return textField
  }()

  public lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(
      imageName: "user_empty",
      content: localizable("user_not_exist"),
      frame: CGRect.zero
    )
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isUserInteractionEnabled = false
    view.isHidden = true
    view.backgroundColor = .clear
    return view
  }()

  override open func viewDidLoad() {
    super.viewDidLoad()
    initialConfig()
    setupSubviews()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: DispatchWorkItem(block: { [weak self] in
      self?.searchTextField.becomeFirstResponder()
    }))
  }

  open func initialConfig() {
    title = commonLocalizable("search")

    // 可在此处选择是否展示群聊结果
    headTitleArr.append(contentsOf: [localizable("discussion_group"),
                                     localizable("senior_group")])
  }

  open func setupSubviews() {
    view.addSubview(tableView)
    view.addSubview(searchTextField)
    view.addSubview(emptyView)

    NSLayoutConstraint.activate([
      emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      emptyView.topAnchor.constraint(equalTo: view.topAnchor),
      emptyView.widthAnchor.constraint(equalToConstant: 200),
      emptyView.heightAnchor.constraint(equalToConstant: 200),
    ])
  }

  // MARK: private method

  open func searchTextFieldChange(textfield: SearchTextField) {
    guard let searchText = textfield.text else {
      return
    }
    if searchText.count <= 0 {
      emptyView.isHidden = true
      viewModel.friendDatas.removeAll()
      viewModel.discussionDatas.removeAll()
      viewModel.seniorDatas.removeAll()
      tableView.reloadData()
      return
    }

    let textRange = textfield.markedTextRange
    if textRange == nil || ((textRange?.isEmpty) == nil) {
      weak var weakSelf = self
      searchStr = searchText
      viewModel.doSearch(searchText) {
        if weakSelf?.viewModel.friendDatas.count == 0, weakSelf?.viewModel.discussionDatas.count == 0, weakSelf?.viewModel.seniorDatas.count == 0 {
          weakSelf?.emptyView.isHidden = false
        } else {
          weakSelf?.emptyView.isHidden = true
        }
        weakSelf?.tableView.reloadData()
      }
    }
  }

  // MARK: UITableViewDelegate, UITableViewDataSource

  open func numberOfSections(in tableView: UITableView) -> Int {
    headTitleArr.count
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return viewModel.friendDatas.count
    } else if section == 1 {
      return viewModel.discussionDatas.count
    } else if section == 2 {
      return viewModel.seniorDatas.count
    }
    return 0
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(NSStringFromClass(NEBaseConversationSearchCell.self))",
      for: indexPath
    ) as? NEBaseConversationSearchCell {
      if indexPath.section == 0 {
        cell.searchModel = viewModel.friendDatas[indexPath.row]
      } else if indexPath.section == 1 {
        cell.searchModel = viewModel.discussionDatas[indexPath.row]
      } else {
        cell.searchModel = viewModel.seniorDatas[indexPath.row]
      }
      cell.searchText = searchStr
      return cell
    }
    return NEBaseConversationListCell()
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    weak var weakSelf = self
    if indexPath.section == 0 {
      let searchModel = viewModel.friendDatas[indexPath.row]
      if let userId = searchModel.userInfo?.user?.accountId {
        let conversationId = V2NIMConversationIdUtil.p2pConversationId(userId)
        Router.shared.use(
          PushP2pChatVCRouter,
          parameters: ["nav": navigationController as Any, "conversationId": conversationId as Any],
          closure: nil
        )
      }

    } else if indexPath.section == 1 {
      let searchModel = viewModel.discussionDatas[indexPath.row]
      if let teamId = searchModel.team?.teamId {
        TeamRepo.shared.getTeamInfo(teamId) { team, error in
          if let err = error {
            if err.code == protocolSendFailed {
              weakSelf?.showToast(commonLocalizable("network_error"))
            } else {
              weakSelf?.showSingleAlert(title: localizable("leave_team"), message: localizable("leave_team_desc")) {}
            }
          } else {
            if team?.isValidTeam == false {
              weakSelf?.showSingleAlert(title: localizable("leave_team"), message: localizable("leave_team_desc")) {}
              return
            }
            let conversationId = V2NIMConversationIdUtil.teamConversationId(teamId)
            Router.shared.use(
              PushTeamChatVCRouter,
              parameters: ["nav": weakSelf?.navigationController as Any,
                           "conversationId": conversationId as Any],
              closure: nil
            )
          }
        }
      }
    } else {
      let searchModel = viewModel.seniorDatas[indexPath.row]
      if let teamId = searchModel.team?.teamId {
        TeamRepo.shared.getTeamInfo(teamId) { team, error in
          if let err = error {
            if err.code == protocolSendFailed {
              weakSelf?.showToast(commonLocalizable("network_error"))
            } else {
              weakSelf?.showSingleAlert(title: localizable("leave_team"), message: localizable("leave_team_desc")) {}
            }
          } else {
            if team?.isValidTeam == false {
              weakSelf?.showSingleAlert(title: localizable("leave_team"), message: localizable("leave_team_desc")) {}
              return
            }
            let conversationId = V2NIMConversationIdUtil.teamConversationId(teamId)
            Router.shared.use(
              PushTeamChatVCRouter,
              parameters: ["nav": weakSelf?.navigationController as Any,
                           "conversationId": conversationId as Any],
              closure: nil
            )
          }
        }
      }
    }
  }

  open func tableView(_ tableView: UITableView,
                      viewForHeaderInSection section: Int) -> UIView? {
    let sectionView = tableView
      .dequeueReusableHeaderFooterView(
        withIdentifier: "\(NSStringFromClass(SearchSessionBaseView.self))"
      ) as! SearchSessionBaseView
    sectionView.setUpTitle(title: headTitleArr[section])
    sectionView.backgroundView = UIView()
    sectionView.backgroundView?.backgroundColor = .white
    return sectionView
  }

  open func tableView(_ tableView: UITableView,
                      heightForHeaderInSection section: Int) -> CGFloat {
    if section == 0, viewModel.friendDatas.count > 0 {
      return 30
    } else if section == 1, viewModel.discussionDatas.count > 0 {
      return 30
    } else if section == 2, viewModel.seniorDatas.count > 0 {
      return 30
    } else {
      return 0
    }
  }
}
