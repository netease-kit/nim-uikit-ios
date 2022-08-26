
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCore
import NEKitTeamUI
import YXLogin
import NIMSDK

class MineSettingViewController: NEBaseViewController,UITableViewDataSource, UITableViewDelegate {
  private var viewModel = MineSettingViewModel()
  public var cellClassDic = [
    SettingCellType.SettingArrowCell.rawValue: TeamArrowSettingCell.self,
    SettingCellType.SettingSwitchCell.rawValue: TeamSettingSwitchCell.self,
  ]
  private var tag = "MineSettingViewController"

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(false, animated: false)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    viewModel.getData()
    setupSubviews()
    initialConfig()
  }

  func initialConfig() {
    title = "设置"
    viewModel.delegate = self
  }

  func setupSubviews() {
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    cellClassDic.forEach { (key: Int, value: BaseTeamSettingCell.Type) in
      tableView.register(value, forCellReuseIdentifier: "\(key)")
    }
  }

  lazy var tableView: UITableView = {
    let table = UITableView()
    table.translatesAutoresizingMaskIntoConstraints = false
    table.backgroundColor = UIColor(hexString: "0xF1F1F6")
    table.dataSource = self
    table.delegate = self
    table.separatorColor = .clear
    table.separatorStyle = .none
    table.sectionHeaderHeight = 12.0
    table.tableFooterView = getFooterView()
    if #available(iOS 15.0, *) {
      table.sectionHeaderTopPadding = 0.0
    }
    return table
  }()

  func getFooterView() -> UIView? {
//        guard let title = getBottomText() else {
//            return nil
//        }
    let footer = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 64.0))
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    footer.addSubview(button)
    button.backgroundColor = .white
    button.clipsToBounds = true
    button.setTitleColor(UIColor(hexString: "0xE6605C"), for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    button.setTitle(title, for: .normal)
    button.addTarget(self, action: #selector(loginOutAction), for: .touchUpInside)
    button.layer.cornerRadius = 8.0
    button.setTitle("退出登录", for: .normal)
    NSLayoutConstraint.activate([
      button.leftAnchor.constraint(equalTo: footer.leftAnchor, constant: 20),
      button.rightAnchor.constraint(equalTo: footer.rightAnchor, constant: -20),
      button.topAnchor.constraint(equalTo: footer.topAnchor, constant: 12),
      button.heightAnchor.constraint(equalToConstant: 40),
    ])
    return footer
  }

    //logout action
    @objc func loginOutAction(){
        
        NIMSDK.shared().loginManager.logout { error in
            NIMSDK.shared().qchatManager.logout { chatError in
                if error != nil {
                    self.view.makeToast(error?.localizedDescription)
                }else {
                    print("logout success")
                    NotificationCenter.default.post(name: Notification.Name("logout"), object: nil)
                }
            }
        }


    }
    
    //MARK: UITableViewDataSource, UITableViewDelegate
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
      ) as? BaseTeamSettingCell {
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
      header.backgroundColor = UIColor(hexString: "0xF1F1F6")
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

  func didClickCleanCache() {}
}

