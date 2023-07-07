
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECoreKit
import NETeamUIKit
import YXLogin
import NIMSDK

class MineSettingViewController: NEBaseViewController, UITableViewDataSource, UITableViewDelegate {
  private var viewModel = MineSettingViewModel()
  public var cellClassDic = [
    SettingCellType.SettingArrowCell.rawValue: CustomTeamArrowSettingCell.self,
    SettingCellType.SettingSwitchCell.rawValue: CustomTeamSettingSwitchCell.self,
  ]
  private var tag = "MineSettingViewController"
  private let userDefault = UserDefaults.standard

  override func viewDidLoad() {
    super.viewDidLoad()
    if userDefault.value(forKey: "HandSetModeKey") == nil {
      SettingProvider.shared.setHandSetMode(true)
    }

    if userDefault.value(forKey: "MessageHasRead") == nil {
      SettingProvider.shared.setMessageRead(true)
    }

    viewModel.delegate = self
    viewModel.getData()
    setupSubviews()
    initialConfig()
  }

  func initialConfig() {
    title = NSLocalizedString("setting", comment: "")

    if NEStyleManager.instance.isNormalStyle() {
      view.backgroundColor = .ne_backgroundColor
      customNavigationView.backgroundColor = .ne_backgroundColor
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
    table.tableFooterView = getFooterView()
    if #available(iOS 15.0, *) {
      table.sectionHeaderTopPadding = 0.0
    }
    return table
  }()

  func getFooterView() -> UIView? {
    let footer = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 64.0))
    let button = UIButton()
    footer.addSubview(button)
    button.backgroundColor = .white
    button.clipsToBounds = true
    button.setTitleColor(UIColor(hexString: "0xE6605C"), for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    button.setTitle(title, for: .normal)
    button.addTarget(self, action: #selector(loginOutAction), for: .touchUpInside)
    button.setTitle(NSLocalizedString("logout", comment: ""), for: .normal)

    if NEStyleManager.instance.isNormalStyle() {
      button.layer.cornerRadius = 8.0
      button.frame = CGRect(x: 20, y: 12, width: view.frame.size.width - 40, height: 40)
    } else {
      button.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        button.leftAnchor.constraint(equalTo: footer.leftAnchor, constant: 0),
        button.rightAnchor.constraint(equalTo: footer.rightAnchor, constant: 0),
        button.topAnchor.constraint(equalTo: footer.topAnchor, constant: 12),
        button.heightAnchor.constraint(equalToConstant: 40),
      ])
    }

    return footer
  }

  @objc func loginOutAction() {
    AuthorManager.shareInstance()?
      .logout(
        withConfirm: NSLocalizedString("want_to_logout", comment: ""),
        withCompletion: { [weak self] user, error in
          if error != nil {
            self?.view.makeToast(error?.localizedDescription)
          } else {
            weak var weakSelf = self
            NotificationCenter.default.post(
              name: Notification.Name("logout"),
              object: nil
            )
            IMKitEngine.instance.logout { error in
              if error == nil {
                NIMSDK.shared().qchatManager.logout { chatError in
                  if chatError != nil {
                    self?.view.makeToast(chatError?.localizedDescription)
                  } else {
                    print("logout success")
                  }
                }
              } else {
                NELog.errorLog(
                  weakSelf?.tag ?? "",
                  desc: "❌CALLBACK logout failed,error = \(error!)"
                )
              }
            }
          }
        }
      )
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
    let header = UIView()
    header.backgroundColor = .clear
    return header
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
}
