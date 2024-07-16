
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreKit
import NIMSDK
import UIKit

/// 转发多选-已选页面-协议
public protocol NEBaseMultiSelectedViewControllerDelegate: NSObjectProtocol {
  /// 移除按钮点击事件
  /// - Parameter model: 数据模型
  func removeButtonAction(_ model: MultiSelectModel?)
}

/// 转发多选-已选页面-基类
@objcMembers
open class NEBaseMultiSelectedViewController: NEContactBaseViewController, UITableViewDelegate, UITableViewDataSource {
  public var selectedArray = [MultiSelectModel]() // 已选列表
  public var tableViewTopAnchor: NSLayoutConstraint? // tableView的top约束
  public weak var delegate: NEBaseMultiSelectedViewControllerDelegate?

  init(selectedArray: [MultiSelectModel] = [MultiSelectModel]()) {
    self.selectedArray = selectedArray
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    commonUI()
  }

  /// 设置标题
  func setupTitle() {
    navigationController?.isNavigationBarHidden = true
    navigationView.isHidden = true

    // 取消按钮
    view.addSubview(cancelButton)
    NSLayoutConstraint.activate([
      cancelButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      cancelButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
      cancelButton.widthAnchor.constraint(equalToConstant: 40),
      cancelButton.heightAnchor.constraint(equalToConstant: 18),
    ])

    // 标题文案
    let titleLabel = UILabel()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.text = localizable("selected")
    titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    titleLabel.textAlignment = .center
    titleLabel.textColor = .ne_darkText
    view.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
      titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      titleLabel.heightAnchor.constraint(equalToConstant: 18),
    ])
  }

  func commonUI() {
    view.backgroundColor = .white
    setupTitle()

    view.addSubview(tableView)
    tableViewTopAnchor = tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 58)
    tableViewTopAnchor?.isActive = true
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80),
    ])

    tableView.register(SelectedListCell.self, forCellReuseIdentifier: "\(NSStringFromClass(NEBaseSelectedListCell.self))")

    view.addSubview(emptyView)
    emptyView.setText(commonLocalizable("no_content"))
    NSLayoutConstraint.activate([
      emptyView.topAnchor.constraint(equalTo: view.topAnchor, constant: -60),
      emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      emptyView.leftAnchor.constraint(equalTo: view.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])
  }

  /// 取消按钮
  lazy var cancelButton: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.accessibilityIdentifier = "id.cancel"
    button.setTitle(localizable("alert_cancel"), for: .normal)
    button.setTitleColor(.ne_greyText, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 16)
    button.addTarget(self, action: #selector(cancelButtonClick), for: .touchUpInside)
    return button
  }()

  lazy var tableView: UITableView = {
    var tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
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

  // MARK: - Action

  /// 取消按钮点击事件
  func cancelButtonClick() {
    dismiss(animated: true, completion: nil)
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    selectedArray.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = selectedArray[indexPath.row]

    let cell = tableView.dequeueReusableCell(withIdentifier: "\(NSStringFromClass(NEBaseSelectedListCell.self))", for: indexPath) as! NEBaseSelectedListCell
    cell.setModel(model)
    cell.delegate = self
    return cell
  }

  public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    62
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let model = selectedArray[indexPath.row]
    print("didSelectRowAt: \(model)")
  }
}

// MARK: - NEBaseSelectedListCellDelegate

extension NEBaseMultiSelectedViewController: NEBaseSelectedListCellDelegate {
  /// 移除按钮点击事件
  /// - Parameter model: 数据模型
  func removeButtonAction(_ model: MultiSelectModel?) {
    selectedArray.removeAll { $0 == model }
    emptyView.isHidden = !selectedArray.isEmpty
    tableView.reloadData()

    delegate?.removeButtonAction(model)
  }
}
