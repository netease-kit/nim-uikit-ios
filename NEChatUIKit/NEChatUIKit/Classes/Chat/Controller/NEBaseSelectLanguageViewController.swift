//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objc
public protocol SelectLanguageDelegate: NSObjectProtocol {
  /// 语言选择回调
  /// - Parameter language: 语言
  /// - Parameter controller: 控制器
  @objc optional func didSelectLanguage(_ language: String?, _ controller: UIViewController?)
}

@objcMembers
open class NEBaseSelectLanguageViewController: NEChatBaseViewController, UITableViewDelegate, UITableViewDataSource {
  /// 数据模型
  public let viewModel = SelectLanguageViewModel()

  /// 代理协议
  public weak var delegate: SelectLanguageDelegate?

  /// 当前选择语言，从外部传入
  public var currentContent = ""

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.datas.count
  }

  open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    48
  }

  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(withIdentifier: "\(NEBaseLanguageCell.self)", for: indexPath) as? NEBaseLanguageCell {
      let model = viewModel.datas[indexPath.row]
      model.isSelect = (model.language == currentContent)
      cell.configureData(model)
      return cell
    }
    let cell = UITableViewCell()
    return cell
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let model = viewModel.datas[indexPath.row]
    delegate?.didSelectLanguage?(model.language, self)
    dismiss(animated: true)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupLanguageUI()
  }

  /// 语言列表
  public lazy var languageTableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.backgroundColor = .clear
    tableView.delegate = self
    tableView.dataSource = self
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

  /// UI 初始化
  open func setupLanguageUI() {
    navigationController?.isNavigationBarHidden = true
    navigationView.isHidden = true
  }

  open func cancelClick() {
    dismiss(animated: true)
  }
}
