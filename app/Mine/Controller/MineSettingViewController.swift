
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import NECoreKit
import NETeamUIKit
import NIMSDK
import UIKit

class MineSettingViewController: NEBaseViewController, UITableViewDataSource, UITableViewDelegate {
  private var viewModel = MineSettingViewModel()
  public var cellClassDic = [
    SettingCellType.SettingArrowCell.rawValue: CustomTeamArrowSettingCell.self,
    SettingCellType.SettingSwitchCell.rawValue: CustomTeamSettingSwitchCell.self,
  ]
  private var tag = "MineSettingViewController"
  private let userDefault = UserDefaults.standard

  /// 设置列表
  lazy var tableView: UITableView = {
    let tableView = UITableView()
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .clear
    tableView.dataSource = self
    tableView.delegate = self
    tableView.separatorColor = .clear
    tableView.separatorStyle = .none
    tableView.tableFooterView = getFooterView()
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

  /// 退出登录按钮
  let logoutButton = UIButton()

  override func viewDidLoad() {
    super.viewDidLoad()
    viewModel.delegate = self
    viewModel.getData()
    setupSubviews()
    initialConfig()
  }

  func initialConfig() {
    title = NSLocalizedString("setting", comment: "")

    if NEStyleManager.instance.isNormalStyle() {
      view.backgroundColor = .ne_backgroundColor
      navigationView.backgroundColor = .ne_backgroundColor
      navigationController?.navigationBar.backgroundColor = .ne_backgroundColor
    } else {
      view.backgroundColor = .funChatBackgroundColor
    }
  }

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

    navigationView.moreButton.isHidden = true
  }

  func getFooterView() -> UIView? {
    let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 64.0))
    footerView.addSubview(logoutButton)
    logoutButton.backgroundColor = .white
    logoutButton.clipsToBounds = true
    logoutButton.setTitleColor(UIColor(hexString: "0xE6605C"), for: .normal)
    logoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    logoutButton.setTitle(title, for: .normal)
    logoutButton.addTarget(self, action: #selector(loginOutAction), for: .touchUpInside)
    logoutButton.setTitle(NSLocalizedString("logout", comment: ""), for: .normal)
    logoutButton.accessibilityIdentifier = "id.logout"
    if NEStyleManager.instance.isNormalStyle() {
      logoutButton.layer.cornerRadius = 8.0
      logoutButton.frame = CGRect(x: 20, y: 12, width: view.frame.size.width - 40, height: 40)
    } else {
      logoutButton.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        logoutButton.leftAnchor.constraint(equalTo: footerView.leftAnchor, constant: 0),
        logoutButton.rightAnchor.constraint(equalTo: footerView.rightAnchor, constant: 0),
        logoutButton.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 12),
        logoutButton.heightAnchor.constraint(equalToConstant: 40),
      ])
    }

    return footerView
  }

    @objc func loginOutAction() {
            weak var weakSelf = self
            logoutButton.isEnabled = false
            IMKitClient.instance.logoutIM { error in
                weakSelf?.logoutButton.isEnabled = true
                if error != nil {
                    NEALog.infoLog(weakSelf?.className() ?? "", desc: "logout im  error : \(error?.localizedDescription ?? "")")
                    weakSelf?.view.makeToast(error?.localizedDescription)
                    NEALog.errorLog(
                        weakSelf?.tag ?? "",
                        desc: "CALLBACK logout SUCCESS = \(error!)"
                    )
                } else {
                    NEALog.infoLog(weakSelf?.className() ?? "", desc: "logout im  success ")
                    NotificationCenter.default.post(
                        name: Notification.Name("logout"),
                        object: nil
                    )
                    NEALog.infoLog(
                        weakSelf?.tag ?? "",
                        desc: "CALLBACK logout SUCCESS"
                    )
                    NEFriendUserCache.shared.removeAllFriendInfo()
                }
            }
        }

  // MARK: UITableViewDataSource, UITableViewDelegate

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
    let model = viewModel.sectionData[indexPath.section].cellModels[indexPath.row]
    if let block = model.cellClick {
      block()
    }
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
    headerView.backgroundColor = .clear
    return headerView
  }

  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    if section == viewModel.sectionData.count - 1 {
      return 12.0
    }
    return 0
  }
}

extension MineSettingViewController: MineSettingViewModelDelegate {
  func didMessageRemindClick() {
    let messageRemindCtrl = MessageRemindViewController()
    navigationController?.pushViewController(messageRemindCtrl, animated: true)
  }

  func didStyleClick() {
    let styleSelectionCtrl = StyleSelectionViewController()
    navigationController?.pushViewController(styleSelectionCtrl, animated: true)
  }

  func didClickCleanCache() {}

  func didClickConfigTest() {
    let configTestVC = ConfigTestViewController()
    navigationController?.pushViewController(configTestVC, animated: true)
  }

  func didClickSDKConfig() {
    
  }
}
