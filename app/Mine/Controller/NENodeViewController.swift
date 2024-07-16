
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreKit
import NETeamUIKit
import UIKit

class NENodeViewController: NEBaseViewController, UITableViewDataSource, UITableViewDelegate {
  private var viewModel = NodeViewModel()
  // 记录默认选中的cell
  private var selectIndex = 0

  lazy var tableView: UITableView = {
    let tableView = UITableView()
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .ne_lightBackgroundColor
    tableView.dataSource = self
    tableView.delegate = self
    tableView.separatorColor = .clear
    tableView.separatorStyle = .none
    tableView.sectionHeaderHeight = 12.0
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

  override func viewDidLoad() {
    super.viewDidLoad()
    viewModel.getData()
    setupUI()
  }

  func setupUI() {
    title = NSLocalizedString("node_select", comment: "")
    navigationView.backgroundColor = .ne_lightBackgroundColor

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: NEConstant.navigationAndStatusHeight),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    tableView.register(
      NodeSelectCell.self,
      forCellReuseIdentifier: "\(NSStringFromClass(NodeSelectCell.self))"
    )
  }

  private func showAlert(_ isDomestic: Bool) {
    let alertController = UIAlertController(
      title: NSLocalizedString("change_node", comment: ""),
      message: NSLocalizedString("restart_take_effect", comment: ""),
      preferredStyle: .alert
    )

    let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .default) { action in
    }
    alertController.addAction(cancelAction)
    let sureAction = UIAlertAction(title: NSLocalizedString("restart", comment: ""), style: .default) { action in
      // 设置节点
      SettingRepo.shared.setNodeValue(isDomestic)
      exit(0)
    }
    alertController.addAction(sureAction)
    present(alertController, animated: true, completion: nil)
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
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(NSStringFromClass(NodeSelectCell.self))",
      for: indexPath
    ) as! NodeSelectCell
    cell.configure(model)
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.row == 0 {
      showAlert(true)
    } else {
      showAlert(false)
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
    let headerView = UIView()
    headerView.backgroundColor = .ne_lightBackgroundColor
    return headerView
  }
}
