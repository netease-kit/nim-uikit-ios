
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class NEBaseConversationSearchController: NEBaseConversationNavigationController, UITableViewDelegate,
  UITableViewDataSource {
  var viewModel = ConversationSearchViewModel()
  var tag = "ConversationSearchBaseController"
  var searchStr = ""
  var headTitleArr = [localizable("friend")]

  override open func viewDidLoad() {
    super.viewDidLoad()
    initialConfig()
    setupSubviews()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: DispatchWorkItem(block: { [weak self] in
      self?.searchTextField.becomeFirstResponder()
    }))
  }

  open func initialConfig() {
    title = localizable("search")

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
      viewModel.searchResult?.friend = [ConversationSearchListModel]()
      viewModel.searchResult?.contactGroup = [ConversationSearchListModel]()
      viewModel.searchResult?.seniorGroup = [ConversationSearchListModel]()
      tableView.reloadData()
      return
    }

    let textRange = textfield.markedTextRange
    if textRange == nil || ((textRange?.isEmpty) == nil) {
      weak var weakSelf = self
      searchStr = searchText
      viewModel.doSearch(searchStr: searchText) { error, tupleInfo in
        if let err = error {
          NELog.errorLog(ModuleName + " " + self.tag, desc: "❌CALLBACK doSearch failed,error = \(err)")
        } else {
          NELog.infoLog(ModuleName + " " + self.tag, desc: "✅CALLBACK doSearch SUCCESS")
          if tupleInfo?.friend.count == 0, tupleInfo?.contactGroup.count == 0,
             tupleInfo?.seniorGroup.count == 0 {
            weakSelf?.emptyView.isHidden = false
          } else {
            weakSelf?.emptyView.isHidden = true
          }
          weakSelf?.tableView.reloadData()
        }
      }
    }
  }

  // MARK: lazy method

  public lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.keyboardDismissMode = .onDrag
    tableView.delegate = self
    tableView.dataSource = self
    tableView.rowHeight = 60
    tableView.backgroundColor = .white
    tableView.sectionHeaderHeight = 30
    tableView.sectionFooterHeight = 0
    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
    return tableView
  }()

  public lazy var searchTextField: SearchTextField = {
    let textField = SearchTextField()
    let leftImageView = UIImageView(image: UIImage
      .ne_imageNamed(name: "conversation_search_icon"))
    textField.contentMode = .center
    textField.leftView = leftImageView
    textField.leftViewMode = .always
    textField.placeholder = localizable("search")
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
    view.isHidden = true
    view.backgroundColor = .clear
    return view
  }()

  // MARK: UITableViewDelegate, UITableViewDataSource

  open func numberOfSections(in tableView: UITableView) -> Int {
    headTitleArr.count
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if let friend = viewModel.searchResult?.friend, section == 0 {
      return friend.count
    } else if let contactGroup = viewModel.searchResult?.contactGroup, section == 1 {
      return contactGroup.count
    } else if let seniorGroup = viewModel.searchResult?.seniorGroup, section == 2 {
      return seniorGroup.count
    } else {
      return 0
    }
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(NSStringFromClass(NEBaseConversationSearchCell.self))",
      for: indexPath
    ) as? NEBaseConversationSearchCell {
      if indexPath.section == 0 {
        cell.searchModel = viewModel.searchResult?.friend[indexPath.row]
      } else if indexPath.section == 1 {
        cell.searchModel = viewModel.searchResult?.contactGroup[indexPath.row]
      } else {
        cell.searchModel = viewModel.searchResult?.seniorGroup[indexPath.row]
      }
      cell.searchText = searchStr
      return cell
    }
    return NEBaseConversationListCell()
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    weak var weakSelf = self
    if indexPath.section == 0 {
      let searchModel = viewModel.searchResult?.friend[indexPath.row]
      if let userId = searchModel?.userInfo?.userId {
        let session = NIMSession(userId, type: .P2P)
        Router.shared.use(
          PushP2pChatVCRouter,
          parameters: ["nav": navigationController as Any, "session": session as Any],
          closure: nil
        )
      }

    } else if indexPath.section == 1 {
      let searchModel = viewModel.searchResult?.contactGroup[indexPath.row]
      if let teamId = searchModel?.teamInfo?.teamId {
        TeamRepo.shared.fetchTeamInfo(teamId) { error, teamInfo in
          if let err = error as? NSError {
            if err.code == noNetworkCode {
              weakSelf?.showToast(commonLocalizable("network_error"))
            } else {
              weakSelf?.showSingleAlert(title: localizable("leave_team"), message: localizable("leave_team_desc")) {}
            }
          } else {
            let session = NIMSession(teamId, type: .team)
            Router.shared.use(
              PushTeamChatVCRouter,
              parameters: ["nav": weakSelf?.navigationController as Any,
                           "session": session as Any],
              closure: nil
            )
          }
        }
      }
    } else {
      let searchModel = viewModel.searchResult?.seniorGroup[indexPath.row]
      if let teamId = searchModel?.teamInfo?.teamId {
        TeamRepo.shared.fetchTeamInfo(teamId) { error, teamInfo in
          if let err = error as? NSError {
            if err.code == noNetworkCode {
              weakSelf?.showToast(commonLocalizable("network_error"))
            } else {
              weakSelf?.showSingleAlert(title: localizable("leave_team"), message: localizable("leave_team_desc")) {}
            }
          } else {
            let session = NIMSession(teamId, type: .team)
            Router.shared.use(
              PushTeamChatVCRouter,
              parameters: ["nav": weakSelf?.navigationController as Any,
                           "session": session as Any],
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
    if let friend = viewModel.searchResult?.friend, friend.count > 0, section == 0 {
      return 30

    } else if let contactGroup = viewModel.searchResult?.contactGroup, contactGroup.count > 0,
              section == 1 {
      return 30
    } else if let seniorGroup = viewModel.searchResult?.seniorGroup, seniorGroup.count > 0,
              section == 2 {
      return 30
    } else {
      return 0
    }
  }
}
