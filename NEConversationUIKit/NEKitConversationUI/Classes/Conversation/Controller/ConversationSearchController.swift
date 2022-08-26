
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK

@objcMembers
open class SearchSessionHeaderView: UITableViewHeaderFooterView {
  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)

    addSubview(title)
    addSubview(bottomLine)

    NSLayoutConstraint.activate([
      title.topAnchor.constraint(equalTo: topAnchor),
      title.leftAnchor.constraint(equalTo: leftAnchor, constant: 20),

    ])

    NSLayoutConstraint.activate([
      bottomLine.rightAnchor.constraint(equalTo: rightAnchor, constant: -20),
      bottomLine.leftAnchor.constraint(equalTo: title.leftAnchor),
      bottomLine.bottomAnchor.constraint(equalTo: bottomAnchor),
      bottomLine.heightAnchor.constraint(equalToConstant: 1),
    ])
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setUpTitle(title: String) {
    self.title.text = title
  }

  private lazy var title: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_emptyTitleColor
    label.font = NEConstant.defaultTextFont(14)
    label.textAlignment = .left
    return label
  }()

  private lazy var bottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor(hexString: "0xDBE0E8")
    return view
  }()
}

public class ConversationSearchController: NEBaseViewController,UITableViewDelegate, UITableViewDataSource {
  private var viewModel = ConversationSearchViewModel()
  private let tag = "ConversationSearchController"
  private var searchStr = ""
  private let headTitleArr = ["好友", "讨论组", "高级群"]

  override public func viewDidLoad() {
    super.viewDidLoad()
    setupSubviews()
    initialConfig()
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.isNavigationBarHidden = false
  }

  func setupSubviews() {
    view.addSubview(tableView)
    view.addSubview(searchTextField)
    view.addSubview(emptyView)

    NSLayoutConstraint.activate([
      searchTextField.topAnchor.constraint(
        equalTo: view.topAnchor,
        constant: NEConstant.navigationHeight + NEConstant.statusBarHeight + 20
      ),
      searchTextField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      searchTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      searchTextField.heightAnchor.constraint(equalToConstant: 32),
    ])

    NSLayoutConstraint.activate([
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      tableView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 20),
    ])

    NSLayoutConstraint.activate([
      emptyView.rightAnchor.constraint(equalTo: tableView.rightAnchor),
      emptyView.leftAnchor.constraint(equalTo: tableView.leftAnchor),
      emptyView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
      emptyView.topAnchor.constraint(equalTo: tableView.topAnchor),
    ])
  }

  func initialConfig() {
    title = "搜索"
  }

  // MARK: private method

  @objc func searchTextFieldChange(textfield: SearchTextField) {
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
          NELog.errorLog(self.tag, desc: "❌doSearch failed,error = \(err)")
        } else {
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

  private lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(
      ConversationSearchCell.self,
      forCellReuseIdentifier: "\(NSStringFromClass(ConversationSearchCell.self))"
    )
    tableView.rowHeight = 60
    tableView.backgroundColor = .white
    tableView.register(
      SearchSessionHeaderView.self,
      forHeaderFooterViewReuseIdentifier: "\(NSStringFromClass(SearchSessionHeaderView.self))"
    )
    tableView.sectionHeaderHeight = 30
    tableView.sectionFooterHeight = 0
    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
    return tableView
  }()

  private lazy var searchTextField: SearchTextField = {
    let textField = SearchTextField()
    let leftImageView = UIImageView(image: UIImage
      .ne_imageNamed(name: "conversation_search_icon"))
    textField.contentMode = .center
    textField.leftView = leftImageView
    textField.leftViewMode = .always
    textField.placeholder = localizable("搜索")
    textField.font = UIFont.systemFont(ofSize: 14)
    textField.textColor = UIColor.ne_greyText
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.layer.cornerRadius = 8
    textField.backgroundColor = UIColor(hexString: "0xEFF1F4")
    textField.clearButtonMode = .whileEditing
    textField.returnKeyType = .search
    textField.addTarget(self, action: #selector(searchTextFieldChange), for: .editingChanged)
    textField.placeholder = "请输入你要搜索的关键字"
    return textField
  }()

  private lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(imageName: "user_empty", content: "该用户不存在", frame: CGRect.zero)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    return view

  }()
    
    //MARK: UITableViewDelegate, UITableViewDataSource
    public func numberOfSections(in tableView: UITableView) -> Int {
      return 3
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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

    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: "\(NSStringFromClass(ConversationSearchCell.self))",
        for: indexPath
      ) as! ConversationSearchCell
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

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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

    public func tableView(_ tableView: UITableView,
                          viewForHeaderInSection section: Int) -> UIView? {
      let sectionView = tableView
        .dequeueReusableHeaderFooterView(
          withIdentifier: "\(NSStringFromClass(SearchSessionHeaderView.self))"
        ) as! SearchSessionHeaderView
      sectionView.setUpTitle(title: headTitleArr[section])
      sectionView.backgroundView = UIView()
      return sectionView
    }

    public func tableView(_ tableView: UITableView,
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

