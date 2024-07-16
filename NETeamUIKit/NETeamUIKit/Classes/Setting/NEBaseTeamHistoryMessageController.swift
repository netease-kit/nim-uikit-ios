
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseTeamHistoryMessageController: NEBaseViewController, UITextFieldDelegate,
  UITableViewDelegate, UITableViewDataSource {
  public let viewModel = TeamHistoryMessageViewModel()

  /// 群id
  public var teamId: String?
  public var searchStr = ""
  var tag = "TeamHistoryMessageController"

  /// 历史消息列表
  public lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(
      NEBaseHistoryMessageCell.self,
      forCellReuseIdentifier: "\(NSStringFromClass(NEBaseHistoryMessageCell.self))"
    )
    tableView.rowHeight = 65
    tableView.backgroundColor = .white
    tableView.sectionHeaderHeight = 30
    tableView.sectionFooterHeight = 0
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

  /// 搜索文本框
  public lazy var searchTextField: SearchTextField = {
    let textField = SearchTextField()
    let leftImageView = UIImageView(image: coreLoader.loadImage("search_icon"))
    textField.contentMode = .center
    textField.leftView = leftImageView
    textField.leftViewMode = .always
    textField.placeholder = localizable("search")
    textField.font = UIFont.systemFont(ofSize: 14)
    textField.textColor = UIColor.ne_greyText
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.layer.cornerRadius = 8
    textField.backgroundColor = UIColor(hexString: "0xF2F4F5")
    textField.clearButtonMode = .always
    textField.returnKeyType = .search
    textField.delegate = self
    textField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)

    if let clearButton = textField.value(forKey: "_clearButton") as? UIButton {
      clearButton.accessibilityIdentifier = "id.clear"
    }
    textField.accessibilityIdentifier = "id.search"
    return textField

  }()

  /// 空占位图
  public lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(
      imageName: "emptyView",
      content: localizable("no_search_results"),
      frame: CGRect.zero
    )
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isUserInteractionEnabled = false
    view.isHidden = true
    return view

  }()

  /// 正在搜索标志，防止多次点击多次搜索
  public var isSearching = false

  public init(teamId: String?) {
    super.init(nibName: nil, bundle: nil)
    self.teamId = teamId
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    weak var weakSelf = self

    viewModel.getTeamInfo(teamId) { team, error in
      if team?.isValidTeam == false || team == nil {
        weakSelf?.view.makeToast(localizable("team_not_exist"))
      }
    }
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

    navigationView.moreButton.isHidden = true
  }

  open func initialConfig() {
    title = localizable("historical_record")
  }

  /// 搜索历史消息
  func toSearchHistory() {
    guard let searchText = searchTextField.text else {
      return
    }
    if searchText.count <= 0 {
      viewModel.searchResultInfos?.removeAll()
      emptyView.isHidden = true
      tableView.reloadData()
      return
    }
    guard let teamId = teamId else {
      return
    }
    if isSearching == true {
      return
    }
    weak var weakSelf = self
    searchStr = searchText
    isSearching = true
    weakSelf?.viewModel.searchHistoryMessages(teamId, searchText) { error, messages in
      weakSelf?.isSearching = false
      NEALog.infoLog(
        ModuleName + " " + self.tag,
        desc: "CALLBACK searchMessages " + (error?.localizedDescription ?? "no error")
      )
      if error == nil {
        if let msg = messages, msg.count > 0 {
          weakSelf?.emptyView.isHidden = true
        } else {
          weakSelf?.emptyView.isHidden = false
        }
        weakSelf?.tableView.reloadData()
      } else {
        NEALog.errorLog(
          ModuleName + " " + (weakSelf?.tag ?? "TeamHistoryMessageController"),
          desc: "searchMessages failed, error = \(error!)"
        )
      }
    }
  }

  /// 监听键盘搜索按钮点击
  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return false
    }
    toSearchHistory()
    return true
  }

  /// 监听键盘内容变化
  func searchTextChanged() {
    if searchTextField.text?.isEmpty == true {
      toSearchHistory()
    }
  }

  // MARK: UITableViewDelegate, UITableViewDataSource

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.searchResultInfos?.count ?? 0
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    UITableViewCell()
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let cellModel = viewModel.searchResultInfos?[indexPath.row]
    if cellModel?.imMessage?.conversationType == .CONVERSATION_TYPE_TEAM {
      if let message = cellModel?.imMessage, let conversationId = message.conversationId {
        Router.shared.use(
          PushTeamChatVCRouter,
          parameters: ["nav": navigationController as Any,
                       "conversationId": conversationId as Any,
                       "anchor": message],
          closure: nil
        )
      }
    }
  }
}
