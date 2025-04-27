
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import NECommonUIKit
import NECoreKit
import NETeamUIKit
import UIKit

class LanguageViewController: NEBaseViewController, UITableViewDelegate,
  UITableViewDataSource {
  public var cellClassDic =
    [SettingCellType.SettingSubtitleCustomCell.rawValue: CustomTeamSettingRightCustomCell.self]
  private var viewModel = LanguageViewModel()
  private var selectedModel: SettingCellModel?

  lazy var tableView: UITableView = {
    let tableView = UITableView()
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .clear
    tableView.dataSource = self
    tableView.delegate = self
    tableView.separatorColor = .clear
    tableView.separatorStyle = .none
    tableView.sectionHeaderHeight = 12.0
    tableView.keyboardDismissMode = .onDrag

    tableView.estimatedRowHeight = 0
    tableView.estimatedSectionHeaderHeight = 0
    tableView.estimatedSectionFooterHeight = 0

    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }
    return tableView
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    viewModel.getData()
    setupSubviews()
    initialConfig()
  }

  /// 导航栏配置
  func initialConfig() {
    title = localizable("app_language")
    if NEStyleManager.instance.isNormalStyle() {
      view.backgroundColor = .ne_backgroundColor
      navigationView.backgroundColor = .ne_backgroundColor
      navigationController?.navigationBar.backgroundColor = .ne_backgroundColor
      navigationView.setMoreButtonTitle(localizable("save"))
      navigationView.moreButton.setTitleColor(.ne_normalTheme, for: .normal)
    } else {
      view.backgroundColor = .funChatBackgroundColor
      navigationView.setMoreButtonTitle(localizable("complete"))
      navigationView.setMoreButtonWidth(NEAppLanguageUtil.getCurrentLanguage() == .english ? 80 : 34)
      navigationView.moreButton.setTitleColor(.ne_funTheme, for: .normal)
    }
    navigationView.addMoreButtonTarget(target: self, selector: #selector(saveButtonAction))
  }

  /// 页面主题元素初始化以及布局
  func setupSubviews() {
    view.addSubview(tableView)
    if NEStyleManager.instance.isNormalStyle() {
      topConstant += 12
    }
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    for (key, value) in cellClassDic {
      tableView.register(value, forCellReuseIdentifier: "\(key)")
    }
  }

  @objc func saveButtonAction() {
    if let lan = selectedModel?.defaultHeadData,
       let lanType = NEAppLanguage(rawValue: lan) {
      NEAppLanguageUtil.setCurrentLanguage(lanType)
      NotificationCenter.default.post(
        name: NENotificationName.changeLanguage,
        object: nil
      )
    } else {
      showToast(commonLocalizable("failed_operation"))
    }
    navigationController?.popViewController(animated: true)
  }

  // MARK: UITableViewDelegate, UITableViewDataSource

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if viewModel.sectionData.count > section {
      let model = viewModel.sectionData[section]
      return model.cellModels.count
    }
    return 0
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    viewModel.sectionData.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = viewModel.sectionData[indexPath.section].cellModels[indexPath.row]
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(model.type)",
      for: indexPath
    ) as? NEBaseTeamSettingCell {
      cell.configure(model)
      return cell
    }
    return UITableViewCell()
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    for (index, model) in viewModel.sectionData[indexPath.section].cellModels.enumerated() {
      if index == indexPath.row {
        model.rightCustomViewIcon = UIImage(named: "language_select")
        selectedModel = model
      } else {
        model.rightCustomViewIcon = UIImage()
      }
    }
    tableView.reloadData()
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let model = viewModel.sectionData[indexPath.section].cellModels[indexPath.row]
    return model.rowHeight
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if section == 0 {
      return 0
    }
    if viewModel.sectionData.count > section {
      let model = viewModel.sectionData[section]
      if model.cellModels.count > 0 {
        return 12.0
      }
    }
    return 0
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let headerView = UIView()
    headerView.backgroundColor = .ne_lightBackgroundColor
    return headerView
  }
}
