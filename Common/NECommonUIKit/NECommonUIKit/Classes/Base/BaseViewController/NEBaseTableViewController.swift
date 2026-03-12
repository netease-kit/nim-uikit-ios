
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import UIKit

@objcMembers
open class NEBaseTableViewController: NEBaseViewController {
  public lazy var tableView: UITableView = {
    let tableView = UITableView(frame: CGRect.zero, style: .grouped)
    tableView.backgroundColor = .clear
    tableView.separatorColor = .clear
    tableView.separatorStyle = .none
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.sectionFooterHeight = 0
    tableView.sectionHeaderHeight = 0
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }

    tableView.contentInsetAdjustmentBehavior = .always

    let headerView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
    headerView.backgroundColor = .clear
    tableView.tableHeaderView = headerView
    return tableView
  }()

  override open func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
  }

  open func setupTable() {
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       // Get the new view controller using segue.destination.
       // Pass the selected object to the new view controller.
   }
   */
}
