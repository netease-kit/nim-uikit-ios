
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonUIKit
import NECoreIM2Kit
import NIMSDK
import UIKit

/// 消息已读未读页面 - 基类
@objcMembers
open class NEBaseReadViewController: NEChatBaseViewController, UITableViewDelegate,
  UITableViewDataSource {
  private let viewModel = ReadViewModel()
  private var message: V2NIMMessage
  private var teamId: String

  /// 已读按钮
  public lazy var readButton: UIButton = {
    let button = UIButton(type: .custom)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    button.setTitle(chatLocalizable("read"), for: .normal)
    button.setTitleColor(UIColor.ne_darkText, for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(readButtonEvent), for: .touchUpInside)
    button.accessibilityIdentifier = "id.tabHasRead"
    return button
  }()

  /// 未读按钮
  public lazy var unreadButton: UIButton = {
    let button = UIButton(type: .custom)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    button.setTitle(chatLocalizable("unread"), for: .normal)
    button.setTitleColor(UIColor.ne_darkText, for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(unreadButtonEvent), for: .touchUpInside)
    button.accessibilityIdentifier = "id.tabUnRead"
    return button
  }()

  /// 已读/未读 按钮下方横线的左侧布局约束
  public var bottonBottomLineLeftAnchor: NSLayoutConstraint?
  /// 已读/未读 按钮下方横线
  public lazy var bottonBottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  /// 已读/未读  tab 视图顶部布局约束
  public var tabViewTopAnchor: NSLayoutConstraint?
  /// 已读未读 tab 视图
  public lazy var tabView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(readButton)
    NSLayoutConstraint.activate([
      readButton.topAnchor.constraint(equalTo: view.topAnchor),
      readButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      readButton.heightAnchor.constraint(equalToConstant: 48),
      readButton.widthAnchor.constraint(equalToConstant: kScreenWidth / 2.0),
    ])

    view.addSubview(unreadButton)
    NSLayoutConstraint.activate([
      unreadButton.topAnchor.constraint(equalTo: readButton.topAnchor),
      unreadButton.leadingAnchor.constraint(equalTo: readButton.trailingAnchor),
      unreadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      unreadButton.heightAnchor.constraint(equalToConstant: 48),
    ])

    view.addSubview(bottonBottomLine)
    bottonBottomLineLeftAnchor = bottonBottomLine.leadingAnchor.constraint(equalTo: view.leadingAnchor)
    NSLayoutConstraint.activate([
      bottonBottomLine.topAnchor.constraint(equalTo: readButton.bottomAnchor, constant: 0),
      bottonBottomLine.heightAnchor.constraint(equalToConstant: 1),
      bottonBottomLine.widthAnchor.constraint(equalTo: readButton.widthAnchor),
      bottonBottomLineLeftAnchor!,
    ])
    return view
  }()

  /// 已读 tableView
  public lazy var readTableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.delegate = self
    tableView.dataSource = self
    tableView.sectionHeaderHeight = 0
    tableView.sectionFooterHeight = 0
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
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

  /// 未读 tableView
  public lazy var unreadTableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.delegate = self
    tableView.dataSource = self
    tableView.sectionHeaderHeight = 0
    tableView.sectionFooterHeight = 0
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.isHidden = true
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

  /// 空视图
  public lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(
      imageName: "emptyView",
      content: chatLocalizable("message_all_unread"),
      frame: .zero
    )
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isUserInteractionEnabled = false
    self.view.addSubview(view)
    return view
  }()

  init(message: V2NIMMessage, teamId: String) {
    self.message = message
    self.teamId = teamId
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) {
    message = V2NIMMessage()
    teamId = ""
    super.init(coder: coder)
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    tabViewTopAnchor?.constant = topConstant
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    commonUI()
    loadData()
  }

  open func commonUI() {
    title = chatLocalizable("message_read")
    navigationView.moreButton.isHidden = true

    view.addSubview(tabView)
    tabViewTopAnchor = tabView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant)
    tabViewTopAnchor?.isActive = true
    NSLayoutConstraint.activate([
      tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabView.heightAnchor.constraint(equalToConstant: 48),
    ])

    view.addSubview(readTableView)
    NSLayoutConstraint.activate([
      readTableView.topAnchor.constraint(equalTo: readButton.bottomAnchor, constant: 1),
      readTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      readTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      readTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    view.addSubview(unreadTableView)
    NSLayoutConstraint.activate([
      unreadTableView.topAnchor.constraint(equalTo: readButton.bottomAnchor, constant: 1),
      unreadTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      unreadTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      unreadTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.topAnchor.constraint(equalTo: readButton.bottomAnchor, constant: 1),
      emptyView.leftAnchor.constraint(equalTo: view.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: view.rightAnchor),
      emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  /// 加载数据
  open func loadData() {
    viewModel.getTeamMessageReceiptDetail(message, teamId) { [weak self] error in
      if let err = error as? NSError {
        if err.code == protocolSendFailed {
          self?.showToast(commonLocalizable("network_error"))
        } else {
          self?.showToast(err.localizedDescription)
        }
      } else {
        self?.readButton.setTitle("已读 (" + "\(self?.viewModel.readUsers.count ?? 0)" + ")", for: .normal)
        self?.unreadButton.setTitle("未读 (" + "\(self?.viewModel.unReadUsers.count ?? 0)" + ")", for: .normal)
        self?.readTableView.reloadData()
        self?.emptyView.isHidden = self?.viewModel.readUsers.isEmpty == false
      }
    }
  }

  /// 已读按钮点击事件
  /// - Parameter button: 按钮
  open func readButtonEvent(button: UIButton) {
    if readTableView.isHidden == false {
      return
    }

    bottonBottomLineLeftAnchor?.constant = 0
    UIView.animate(withDuration: 0.5) {
      self.view.layoutIfNeeded()
    }

    readTableView.reloadData()
    readTableView.isHidden = false
    unreadTableView.isHidden = true
    emptyView.isHidden = !viewModel.readUsers.isEmpty
  }

  /// 未读按钮点击事件
  /// - Parameter button: 按钮
  open func unreadButtonEvent(button: UIButton) {
    if unreadTableView.isHidden == false {
      return
    }

    bottonBottomLineLeftAnchor?.constant = button.width
    UIView.animate(withDuration: 0.5) {
      self.view.layoutIfNeeded()
    }

    unreadTableView.reloadData()
    unreadTableView.isHidden = false
    readTableView.isHidden = true
    emptyView.isHidden = !viewModel.unReadUsers.isEmpty
  }

  // MARK: - UITableViewDelegate, UITableViewDataSource

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if tableView == readTableView {
      return viewModel.readUsers.count
    } else {
      return viewModel.unReadUsers.count
    }
  }

  func cellSetModel(tableView: UITableView, cell: UserBaseTableViewCell, indexPath: IndexPath) -> UITableViewCell {
    if tableView == readTableView {
      let model = viewModel.readUsers[indexPath.row]
      cell.setModel(model)
    } else {
      let model = viewModel.unReadUsers[indexPath.row]
      cell.setModel(model)
    }
    return cell
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(UserBaseTableViewCell.self)",
      for: indexPath
    ) as! UserBaseTableViewCell
    return cellSetModel(tableView: tableView, cell: cell, indexPath: indexPath)
  }
}
