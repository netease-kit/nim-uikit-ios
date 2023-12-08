
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import NECoreKit
import NETeamUIKit
import UIKit

class ConfigTestViewController: NEBaseViewController, UITableViewDelegate,
  UITableViewDataSource {
  public var cellClassDic =
    [SettingCellType.SettingSwitchCell.rawValue: CustomTeamSettingSwitchCell.self]
  var sectionData = [SettingSectionModel]()

  override func viewDidLoad() {
    super.viewDidLoad()
    sectionData.append(getSectionData())
    setupSubviews()
    initialConfig()
  }

  func getSectionData() -> SettingSectionModel {
    let model = SettingSectionModel()

    let useSysNav = SettingCellModel()
    useSysNav.cellName = "使用系统导航栏"
    useSysNav.type = SettingCellType.SettingSwitchCell.rawValue
    useSysNav.switchOpen = NEConfigManager.instance.getParameter(key: useSystemNav) as? Bool ?? false
    useSysNav.swichChange = { isOpen in
      NEConfigManager.instance.setParameter(key: useSystemNav, value: isOpen)
    }
    model.cellModels.append(useSysNav)

    let showTeam = SettingCellModel()
    showTeam.cellName = "显示群聊"
    showTeam.type = SettingCellType.SettingSwitchCell.rawValue
    showTeam.switchOpen = IMKitClient.instance.getConfigCenter().teamEnable
    showTeam.swichChange = { isOpen in
      IMKitClient.instance.getConfigCenter().teamEnable = isOpen
    }
    model.cellModels.append(showTeam)

    model.setCornerType()
    return model
  }

  func initialConfig() {
    title = "配置测试页"
    if NEStyleManager.instance.isNormalStyle() {
      view.backgroundColor = .ne_backgroundColor
      navigationView.backgroundColor = .ne_backgroundColor
      navigationController?.navigationBar.backgroundColor = .ne_backgroundColor
      navigationView.moreButton.setTitleColor(.ne_greyText, for: .normal)
    } else {
      view.backgroundColor = .funChatBackgroundColor
      navigationView.moreButton.setTitleColor(.funChatThemeColor, for: .normal)
    }
  }

  func setupSubviews() {
    addRightAction("保存", #selector(saveConfig), self)
    navigationView.moreButton.isHidden = false
    navigationView.setMoreButtonTitle("保存")
    navigationView.addMoreButtonTarget(target: self, selector: #selector(saveConfig))

    let tipLabel = UILabel()
    tipLabel.translatesAutoresizingMaskIntoConstraints = false
    tipLabel.text = "点击保存生效"
    tipLabel.textColor = .ne_greyText
    tipLabel.font = UIFont.systemFont(ofSize: 14)
    tipLabel.textAlignment = .center
    view.addSubview(tipLabel)
    NSLayoutConstraint.activate([
      tipLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
      tipLabel.rightAnchor.constraint(equalTo: view.rightAnchor),
      tipLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: NEConstant.navigationAndStatusHeight),
      tipLabel.heightAnchor.constraint(equalToConstant: 20),
    ])

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.topAnchor.constraint(equalTo: tipLabel.bottomAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    cellClassDic.forEach { (key: Int, value: NEBaseTeamSettingCell.Type) in
      tableView.register(value, forCellReuseIdentifier: "\(key)")
    }
  }

  lazy var tableView: UITableView = {
    let table = UITableView()
    table.translatesAutoresizingMaskIntoConstraints = false
    table.backgroundColor = .clear
    table.dataSource = self
    table.delegate = self
    table.separatorColor = .clear
    table.separatorStyle = .none
    table.sectionHeaderHeight = 12.0
    if #available(iOS 15.0, *) {
      table.sectionHeaderTopPadding = 0.0
    }
    return table
  }()

  @objc func saveConfig() {
    NotificationCenter.default.post(
      name: Notification.Name(CHANGE_UI),
      object: nil
    )
  }

  // MARK: UITableViewDelegate, UITableViewDataSource

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if sectionData.count > section {
      let model = sectionData[section]
      return model.cellModels.count
    }
    return 0
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    sectionData.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = sectionData[indexPath.section].cellModels[indexPath.row]
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(model.type)",
      for: indexPath
    ) as? NEBaseTeamSettingCell {
      cell.configure(model)
      return cell
    }
    return UITableViewCell()
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let model = sectionData[indexPath.section].cellModels[indexPath.row]
    return model.rowHeight
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if sectionData.count > section {
      let model = sectionData[section]
      if model.cellModels.count > 0 {
        return 12.0
      }
    }
    return 0
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let header = UIView()
    header.backgroundColor = .ne_lightBackgroundColor
    return header
  }
}
