
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseTeamInfoViewController: NEBaseViewController, UITableViewDelegate,
  UITableViewDataSource, NETeamInfoDelegate {
  public let viewModel = TeamInfoViewModel()

  public var team: V2NIMTeam?

  public var registerCellDic = [Int: NEBaseTeamSettingCell.Type]()

  public lazy var contentTableView: UITableView = {
    let tableView = UITableView()
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .clear
    tableView.dataSource = self
    tableView.delegate = self
    tableView.separatorStyle = .none
    tableView.sectionHeaderHeight = 0
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

  init(team: V2NIMTeam?) {
    super.init(nibName: nil, bundle: nil)
    self.team = team
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if team?.serverExtension?.contains(discussTeamKey) == true {
      title = localizable("discuss_info")
    } else {
      title = localizable("group_info")
    }
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    viewModel.delegate = self
    viewModel.getData(team)
    setupUI()
  }

  /// UI 初始化
  open func setupUI() {
    view.addSubview(contentTableView)
    /// 列表视图布局
    NSLayoutConstraint.activate([
      contentTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentTableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant + 12),
      contentTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    /// 列表视图内容注册
    for (key, value) in registerCellDic {
      contentTableView.register(value, forCellReuseIdentifier: "\(key)")
    }
    navigationView.moreButton.isHidden = true
  }

  // MARK: UITableViewDelegate, UITableViewDataSource

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.cellDatas.count
  }

  /// 数据绑定，在子类中绑定
  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    UITableViewCell()
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}

  /// 列表高度回调
  open func tableView(_ tableView: UITableView,
                      heightForRowAt indexPath: IndexPath) -> CGFloat {
    let model = viewModel.cellDatas[indexPath.row]
    return model.rowHeight
  }

  public func teamInfoDidUpdate(_ t: V2NIMTeam) {
    team = t
    contentTableView.reloadData()
  }
}
