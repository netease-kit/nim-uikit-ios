
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK

public class TeamHistoryMessageController: NEBaseViewController,UITextFieldDelegate,UITableViewDelegate, UITableViewDataSource {
  private let viewmodel = TeamSettingViewModel()
  private var teamSession: NIMSession?
  private var searchStr = ""
  private var tag = "TeamHistoryMessageController"

  public init(session: NIMSession?) {
    super.init(nibName: nil, bundle: nil)
    teamSession = session
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    setupSubviews()
    initialConfig()
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
    title = "历史记录"
  }

  // MARK: lazy method

  private lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(
      HistoryMessageCell.self,
      forCellReuseIdentifier: "\(NSStringFromClass(HistoryMessageCell.self))"
    )
    tableView.rowHeight = 65
    tableView.backgroundColor = .white
    tableView.sectionHeaderHeight = 30
    tableView.sectionFooterHeight = 0
    return tableView
  }()

  private lazy var searchTextField: SearchTextField = {
    let textField = SearchTextField()
    let leftImageView = UIImageView(image: coreLoader.loadImage("search_icon"))
    textField.contentMode = .center
    textField.leftView = leftImageView
    textField.leftViewMode = .always
    textField.placeholder = localizable("搜索")
    textField.font = UIFont.systemFont(ofSize: 14)
    textField.textColor = UIColor.ne_greyText
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.layer.cornerRadius = 8
    textField.backgroundColor = UIColor(hexString: "0xF2F4F5")
    textField.clearButtonMode = .whileEditing
    textField.returnKeyType = .search
    textField.addTarget(self, action: #selector(searchTextFieldChange), for: .editingChanged)
    textField.delegate = self
    return textField

  }()

  private lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(imageName: "emptyView", content: "暂无搜索结果", frame: CGRect.zero)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    return view

  }()

  // MARK: private method

  @objc func searchTextFieldChange(textfield: SearchTextField) {
    if textfield.text?.count == 0 {
      viewmodel.searchResultInfos?.removeAll()
      tableView.reloadData()
    }
  }
    
    //MARK: UITextFieldDelegate
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
      guard let searchText = textField.text else {
        return false
      }
      if searchText.count <= 0 {
        return false
      }
      guard let session = teamSession else {
        return false
      }
      weak var weakSelf = self
      searchStr = searchText
      let option = NIMMessageSearchOption()
      option.searchContent = searchText
      weakSelf?.viewmodel.searchMessages(session, option: option) { error, messages in
        if error == nil {
          if let msg = messages, msg.count > 0 {
            weakSelf?.emptyView.isHidden = true
          } else {
            weakSelf?.emptyView.isHidden = false
          }
          weakSelf?.tableView.reloadData()
        } else {
          NELog.errorLog(
            weakSelf?.tag ?? "TeamHistoryMessageController",
            desc: "❌searchMessages failed, error = \(error!)"
          )
        }
      }

      return true
    }
    
    //MARK: UITableViewDelegate, UITableViewDataSource
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      viewmodel.searchResultInfos?.count ?? 0
    }

    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: "\(NSStringFromClass(HistoryMessageCell.self))",
        for: indexPath
      ) as! HistoryMessageCell
      let cellModel = viewmodel.searchResultInfos?[indexPath.row]
      cell.searchText = searchStr
      cell.configData(message: cellModel)
      return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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




