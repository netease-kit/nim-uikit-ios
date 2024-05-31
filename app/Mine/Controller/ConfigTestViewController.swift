
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

  lazy var tableView: UITableView = {
    let tableView = UITableView()
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .clear
    tableView.dataSource = self
    tableView.delegate = self
    tableView.separatorColor = .clear
    tableView.separatorStyle = .none
    tableView.sectionHeaderHeight = 12.0
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }
    return tableView
  }()

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
    showTeam.switchOpen = IMKitConfigCenter.shared.teamEnable
    showTeam.swichChange = { isOpen in
      IMKitConfigCenter.shared.teamEnable = isOpen
    }
    model.cellModels.append(showTeam)

    let showMessageCollection = SettingCellModel()
    showMessageCollection.cellName = "显示收藏"
    showMessageCollection.type = SettingCellType.SettingSwitchCell.rawValue
    showMessageCollection.switchOpen = IMKitConfigCenter.shared.collectionEnable
    showMessageCollection.swichChange = { isOpen in
//      IMKitConfigCenter.shared.collectionEnable = isOpen
    }
    model.cellModels.append(showMessageCollection)

    let showMessagePin = SettingCellModel()
    showMessagePin.cellName = "显示标记"
    showMessagePin.type = SettingCellType.SettingSwitchCell.rawValue
    showMessagePin.switchOpen = IMKitConfigCenter.shared.pinEnable
    showMessagePin.swichChange = { isOpen in
      IMKitConfigCenter.shared.pinEnable = isOpen
    }
    model.cellModels.append(showMessagePin)

    let showMessageTop = SettingCellModel()
    showMessageTop.cellName = "显示置顶"
    showMessageTop.type = SettingCellType.SettingSwitchCell.rawValue
    showMessageTop.switchOpen = IMKitConfigCenter.shared.topEnable
    showMessageTop.swichChange = { isOpen in
//      IMKitConfigCenter.shared.topEnable = isOpen
    }
    model.cellModels.append(showMessageTop)

    let showOnlineStatus = SettingCellModel()
    showOnlineStatus.cellName = "显示在线状态"
    showOnlineStatus.type = SettingCellType.SettingSwitchCell.rawValue
    showOnlineStatus.switchOpen = IMKitConfigCenter.shared.onlineStatusEnable
    showOnlineStatus.swichChange = { isOpen in
//      IMKitConfigCenter.shared.onlineStatusEnable = isOpen
    }
    model.cellModels.append(showOnlineStatus)

    let strangerCallEnable = SettingCellModel()
    strangerCallEnable.cellName = "是否允许陌生人音视频通话"
    strangerCallEnable.type = SettingCellType.SettingSwitchCell.rawValue
    strangerCallEnable.switchOpen = IMKitConfigCenter.shared.strangerCallEnable
    strangerCallEnable.swichChange = { isOpen in
      IMKitConfigCenter.shared.strangerCallEnable = isOpen
    }
    model.cellModels.append(strangerCallEnable)

    model.setCornerType()
    return model
  }

  func initialConfig() {
    title = "全局配置"
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

    for (key, value) in cellClassDic {
      tableView.register(value, forCellReuseIdentifier: "\(key)")
    }
  }

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
    let headerView = UIView()
    headerView.backgroundColor = .ne_lightBackgroundColor
    return headerView
  }
}
