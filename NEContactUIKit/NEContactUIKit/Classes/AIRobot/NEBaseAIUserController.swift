//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonUIKit
import NECoreKit
import UIKit

@objcMembers
open class NEBaseAIUserController: NEBaseViewController, UITableViewDelegate, UITableViewDataSource {
  let viewModel = AIUserViewModel()

  /// 输入框
  public lazy var searchAIUserTextField: UITextField = {
    let field = UITextField()
    field.translatesAutoresizingMaskIntoConstraints = false
    field.placeholder = commonLocalizable("search")
    field.clearButtonMode = .always
    field.textColor = .ne_greyText
    field.font = UIFont.systemFont(ofSize: 14.0)
    field.backgroundColor = UIColor.ne_backcolor
    if let clearButton = field.value(forKey: "_clearButton") as? UIButton {
      clearButton.accessibilityIdentifier = "id.clear"
    }
    field.accessibilityIdentifier = "id.search"
    return field
  }()

  /// AI 机器人列表
  public lazy var aiUserTableView: UITableView = {
    let tableView = UITableView()
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .clear
    tableView.separatorColor = .clear
    tableView.separatorStyle = .none
    tableView.sectionHeaderHeight = 12.0
    tableView.dataSource = self
    tableView.delegate = self
    tableView
      .tableFooterView =
      UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 12))
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

  /// 无数字人空占位图
  public lazy var aiUserEmptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(imageName: "user_empty", content: localizable("no_ai_user"), frame: .zero)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    return view
  }()

  public var backViewTopAnchor: NSLayoutConstraint?
  lazy var backView: UIView = {
    let view = UIView()
    view.backgroundColor = .clear
    view.translatesAutoresizingMaskIntoConstraints = false
    view.clipsToBounds = true
    view.layer.cornerRadius = 4.0
    return view
  }()

  /// 搜索背景图
  public lazy var searchIconImageView: UIImageView = {
    let searchIconImageView = UIImageView()
    searchIconImageView.image = coreLoader.loadImage("search_icon")
    searchIconImageView.translatesAutoresizingMaskIntoConstraints = false
    return searchIconImageView
  }()

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    backViewTopAnchor?.constant = 8.0 + topConstant
  }

  override open func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    setupAIUserListUI()
    addTextFiledObserver()
    navigationView.moreButton.isHidden = true

    viewModel.getAIUsers { [weak self] error in
      self?.refreshTableView()
    }
  }

  /// UI 初始化
  open func setupAIUserListUI() {
    title = localizable("my_ai_user")

    view.addSubview(backView)
    backViewTopAnchor = backView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8.0 + topConstant)
    backViewTopAnchor?.isActive = true

    NSLayoutConstraint.activate([
      backView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      backView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      backView.heightAnchor.constraint(equalToConstant: 0),
    ])

    backView.addSubview(searchIconImageView)
    NSLayoutConstraint.activate([
      searchIconImageView.centerYAnchor.constraint(equalTo: backView.centerYAnchor),
      searchIconImageView.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 16.0),
    ])

    backView.addSubview(searchAIUserTextField)
    NSLayoutConstraint.activate([
      searchAIUserTextField.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 36.0),
      searchAIUserTextField.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -16.0),
      searchAIUserTextField.topAnchor.constraint(equalTo: backView.topAnchor),
      searchAIUserTextField.bottomAnchor.constraint(equalTo: backView.bottomAnchor),
    ])

    view.addSubview(aiUserTableView)
    NSLayoutConstraint.activate([
      aiUserTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      aiUserTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      aiUserTableView.topAnchor.constraint(equalTo: backView.bottomAnchor, constant: 0),
      aiUserTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    aiUserTableView.register(NEBaseAIUserListCell.self, forCellReuseIdentifier: "\(NEBaseAIUserListCell.self)")

    view.addSubview(aiUserEmptyView)
    NSLayoutConstraint.activate([
      aiUserEmptyView.leftAnchor.constraint(equalTo: aiUserTableView.leftAnchor),
      aiUserEmptyView.rightAnchor.constraint(equalTo: aiUserTableView.rightAnchor),
      aiUserEmptyView.topAnchor.constraint(equalTo: aiUserTableView.topAnchor, constant: 50),
      aiUserEmptyView.bottomAnchor.constraint(equalTo: aiUserTableView.bottomAnchor),
    ])
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if let text = searchAIUserTextField.text, text.count > 0 {
      return viewModel.searchDatas.count
    }
    return viewModel.datas.count
  }

  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    UITableViewCell()
  }

  open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    0
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let info = viewModel.datas[indexPath.row]
    Router.shared.use(
      ContactUserInfoPageRouter,
      parameters: ["nav": navigationController as Any, "nim_user": info.aiUser as Any],
      closure: nil
    )
  }

  func isLastAIUser(_ index: Int) -> Bool {
    if let text = searchAIUserTextField.text, text.count > 0 {
      if viewModel.searchDatas.count - 1 == index {
        return true
      }
    }
    if viewModel.datas.count - 1 == index {
      return true
    }
    return false
  }

  /// 判断该当前是搜索列表还是内容列表
  /// - Parameter index: 列表索引
  func getRealAIUserModel(_ index: Int) -> NEAIUserModel? {
    if let text = searchAIUserTextField.text, text.count > 0 {
      return viewModel.searchDatas[index]
    }
    return viewModel.datas[index]
  }

  /// 添加输入框变更监听
  func addTextFiledObserver() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(textChange),
      name: UITextField.textDidChangeNotification,
      object: nil
    )
  }

  /// 输入变更
  func textChange() {
    viewModel.searchDatas.removeAll()
    if let text = searchAIUserTextField.text, text.count > 0 {
      for model in viewModel.datas {
        if let uid = model.aiUser?.accountId, uid.contains(text) {
          viewModel.searchDatas.append(model)
        } else if let nick = model.aiUser?.name, nick.contains(text) {
          viewModel.searchDatas.append(model)
        }
      }
    } else {
      aiUserEmptyView.isHidden = true
    }
    refreshTableView()
  }

  /// 刷新数据列表
  open func refreshTableView() {
    aiUserTableView.reloadData()
    if viewModel.datas.count <= 0 {
      aiUserEmptyView.isHidden = false
    }
  }
}
