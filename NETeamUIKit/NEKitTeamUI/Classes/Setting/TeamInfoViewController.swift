
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK

public class TeamInfoViewController: NEBaseViewController,UITableViewDelegate, UITableViewDataSource {
  let viewmodel = TeamInfoViewModel()

  var team: NIMTeam?

  public var cellClassDic = [
    SettingCellType.SettingArrowCell.rawValue: TeamArrowSettingCell.self,
    SettingCellType.SettingHeaderCell.rawValue: TeamSettingHeaderCell.self,
  ]

  lazy var contentTable: UITableView = {
    let table = UITableView()
    table.translatesAutoresizingMaskIntoConstraints = false
    table.backgroundColor = NEConstant.hexRGB(0xF1F1F6)
    table.dataSource = self
    table.delegate = self
    table.separatorColor = .clear
    table.separatorStyle = .none
    table.sectionHeaderHeight = 12.0
    table
      .tableFooterView =
      UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 12))
    return table
  }()

  override public func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    if let type = team?.type, type == .normal {
      title = "讨论组信息"
    } else {
      title = "群信息"
    }
    viewmodel.getData(team)
    setupUI()
  }

  func setupUI() {
    view.backgroundColor = NEConstant.hexRGB(0xF1F1F6)
    view.addSubview(contentTable)
    NSLayoutConstraint.activate([
      contentTable.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentTable.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentTable.topAnchor.constraint(equalTo: view.topAnchor),
      contentTable.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    cellClassDic.forEach { (key: Int, value: BaseTeamSettingCell.Type) in
      contentTable.register(value, forCellReuseIdentifier: "\(key)")
    }
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       // Get the new view controller using segue.destination.
       // Pass the selected object to the new view controller.
   }
   */
    //MARK: UITableViewDelegate, UITableViewDataSource
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      viewmodel.cellDatas.count
    }

    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let model = viewmodel.cellDatas[indexPath.row]
      if let cell = tableView.dequeueReusableCell(
        withIdentifier: "\(model.type)",
        for: indexPath
      ) as? BaseTeamSettingCell {
        cell.configure(model)
        return cell
      }
      return UITableViewCell()
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      if indexPath.row == 0 {
        let avatar = TeamAvatarViewController()
        avatar.team = team
        weak var weakSelf = self
        avatar.block = {
          if let t = weakSelf?.team {
            weakSelf?.viewmodel.getData(t)
            weakSelf?.contentTable.reloadData()
          }
        }
        navigationController?.pushViewController(avatar, animated: true)

      } else if indexPath.row == 1 {
        let nameController = TeamNameViewController()
        nameController.team = team
        navigationController?.pushViewController(nameController, animated: true)
      } else if indexPath.row == 2 {
        let intr = TeamIntroduceViewController()
        intr.team = team
        navigationController?.pushViewController(intr, animated: true)
      }
    }

    public func tableView(_ tableView: UITableView,
                          heightForRowAt indexPath: IndexPath) -> CGFloat {
      let model = viewmodel.cellDatas[indexPath.row]
      return model.rowHeight
    }

    public func tableView(_ tableView: UITableView,
                          heightForHeaderInSection section: Int) -> CGFloat {
      12.0
    }
    
}

