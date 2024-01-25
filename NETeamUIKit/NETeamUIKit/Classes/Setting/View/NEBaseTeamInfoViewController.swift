
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class NEBaseTeamInfoViewController: NEBaseViewController, UITableViewDelegate,
  UITableViewDataSource {
  public let viewmodel = TeamInfoViewModel()

  public var team: NIMTeam?

  public var cellClassDic = [Int: NEBaseTeamSettingCell.Type]()

  public lazy var contentTable: UITableView = {
    let table = UITableView()
    table.translatesAutoresizingMaskIntoConstraints = false
    table.backgroundColor = .clear
    table.dataSource = self
    table.delegate = self
    table.separatorStyle = .none
    table.sectionHeaderHeight = 0
    return table
  }()

  init(team: NIMTeam?) {
    super.init(nibName: nil, bundle: nil)
    self.team = team
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if let type = team?.type, type == .normal {
      title = localizable("discuss_info")
    } else {
      title = localizable("group_info")
    }
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    viewmodel.getData(team)
    setupUI()
  }

  open func setupUI() {
    view.addSubview(contentTable)
    NSLayoutConstraint.activate([
      contentTable.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentTable.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentTable.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant + 12),
      contentTable.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    cellClassDic.forEach { (key: Int, value: NEBaseTeamSettingCell.Type) in
      contentTable.register(value, forCellReuseIdentifier: "\(key)")
    }
  }

  // MARK: UITableViewDelegate, UITableViewDataSource

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewmodel.cellDatas.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    UITableViewCell()
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}

  open func tableView(_ tableView: UITableView,
                      heightForRowAt indexPath: IndexPath) -> CGFloat {
    let model = viewmodel.cellDatas[indexPath.row]
    return model.rowHeight
  }
}
