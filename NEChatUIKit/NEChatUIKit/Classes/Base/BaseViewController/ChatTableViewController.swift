
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreKit
import UIKit

@objcMembers
open class ChatTableViewController: NEBaseViewController, UITableViewDelegate,
  UITableViewDataSource {
  public var tableView: UITableView = .init(frame: .zero, style: .grouped)
  public var topConstraint: NSLayoutConstraint?
  public var bottomConstraint: NSLayoutConstraint?

  override open func viewDidLoad() {
    super.viewDidLoad()
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])

    if #available(iOS 11.0, *) {
      self.topConstraint = self.tableView.topAnchor.constraint(
        equalTo: self.view.safeAreaLayoutGuide.topAnchor,
        constant: 0
      )
      self.bottomConstraint = self.tableView.bottomAnchor
        .constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)

    } else {
      // Fallback on earlier versions
      topConstraint = tableView.topAnchor.constraint(equalTo: view.topAnchor)
      bottomConstraint = tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    }
    topConstraint?.isActive = true
    bottomConstraint?.isActive = true

    tableView.sectionHeaderHeight = 38
    tableView.sectionFooterHeight = 0
    tableView.rowHeight = 62
    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    0
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
