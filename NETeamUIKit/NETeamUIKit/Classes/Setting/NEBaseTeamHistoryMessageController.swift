
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class NEBaseTeamHistoryMessageController: NEBaseViewController, UITextFieldDelegate,
  UITableViewDelegate, UITableViewDataSource {
  public let viewmodel = TeamSettingViewModel()
  public var teamSession: NIMSession?
  public var searchStr = ""
  var tag = "TeamHistoryMessageController"

  public init(session: NIMSession?) {
    super.init(nibName: nil, bundle: nil)
    teamSession = session
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

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
    title = localizable("historical_record")
  }

  // MARK: lazy method

  public lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.keyboardDismissMode = .onDrag
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
    return tableView
  }()

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
    textField.addTarget(self, action: #selector(searchTextFieldChange), for: .editingChanged)
    textField.delegate = self
    if let clearButton = textField.value(forKey: "_clearButton") as? UIButton {
      clearButton.accessibilityIdentifier = "id.clear"
    }
    textField.accessibilityIdentifier = "id.search"
    return textField

  }()

  public lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(
      imageName: "emptyView",
      content: localizable("no_search_results"),
      frame: CGRect.zero
    )
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    return view

  }()

  // MARK: private method

  func searchTextFieldChange(textfield: SearchTextField) {
    guard let searchText = textfield.text else {
      return
    }
    if searchText.count <= 0 {
      viewmodel.searchResultInfos?.removeAll()
      emptyView.isHidden = true
      tableView.reloadData()
      return
    }
    guard let session = teamSession else {
      return
    }
    weak var weakSelf = self
    searchStr = searchText
    let option = NIMMessageSearchOption()
    option.searchContent = searchText
    weakSelf?.viewmodel.searchMessages(session, option: option) { error, messages in
      NELog.infoLog(
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
        NELog.errorLog(
          ModuleName + " " + (weakSelf?.tag ?? "TeamHistoryMessageController"),
          desc: "❌searchMessages failed, error = \(error!)"
        )
      }
    }
  }

  // MARK: UITableViewDelegate, UITableViewDataSource

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewmodel.searchResultInfos?.count ?? 0
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    UITableViewCell()
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let cellModel = viewmodel.searchResultInfos?[indexPath.row]
    if cellModel?.imMessage?.session?.sessionType == .team {
      if let sid = cellModel?.imMessage?.session?.sessionId,
         let message = cellModel?.imMessage {
        let session = NIMSession(sid, type: .team)
        Router.shared.use(
          PushTeamChatVCRouter,
          parameters: ["nav": navigationController as Any, "session": session as Any,
                       "anchor": message],
          closure: nil
        )
      }
    }
  }
}
