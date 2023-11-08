
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
  var headTitleArr = [
    localizable("friend"),
    localizable("discussion_group"),
    localizable("senior_group"),
  ]

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupSubviews()
    initialConfig()
  }

  open func setupSubviews() {
    view.addSubview(tableView)
    view.addSubview(searchTextField)
    view.addSubview(emptyView)

    NSLayoutConstraint.activate([
      emptyView.rightAnchor.constraint(equalTo: tableView.rightAnchor),
      emptyView.leftAnchor.constraint(equalTo: tableView.leftAnchor),
      emptyView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
      emptyView.topAnchor.constraint(equalTo: tableView.topAnchor),
    ])
  }

  open func initialConfig() {
    title = localizable("search")
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
    textField.placeholder = localizable("search")
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
    3
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
        let session = NIMSession(teamId, type: .team)
        Router.shared.use(
          PushTeamChatVCRouter,
          parameters: ["nav": navigationController as Any, "session": session as Any],
          closure: nil
        )
      }
    } else {
      let searchModel = viewModel.searchResult?.seniorGroup[indexPath.row]
      if let teamId = searchModel?.teamInfo?.teamId {
        let session = NIMSession(teamId, type: .team)
        Router.shared.use(
          PushTeamChatVCRouter,
          parameters: ["nav": navigationController as Any, "session": session as Any],
          closure: nil
        )
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
