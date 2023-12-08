
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class TeamHistoryMessageController: NEBaseTeamHistoryMessageController {
  override public init(session: NIMSession?) {
    super.init(session: session)
    tag = "TeamHistoryMessageController"
    navigationView.backgroundColor = .white
    navigationController?.navigationBar.backgroundColor = .white
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func setupSubviews() {
    super.setupSubviews()
    NSLayoutConstraint.activate([
      searchTextField.topAnchor.constraint(
        equalTo: view.topAnchor,
        constant: NEConstant.navigationHeight + NEConstant.statusBarHeight + 20
      ),
      searchTextField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      searchTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      searchTextField.heightAnchor.constraint(equalToConstant: 32),
    ])

    NSLayoutConstraint.activate([
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      tableView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 20),
    ])

    tableView.register(
      HistoryMessageCell.self,
      forCellReuseIdentifier: "\(NSStringFromClass(HistoryMessageCell.self))"
    )
  }

  override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(NSStringFromClass(HistoryMessageCell.self))",
      for: indexPath
    ) as! NEBaseHistoryMessageCell
    let cellModel = viewmodel.searchResultInfos?[indexPath.row]
    cell.searchText = searchStr
    cell.configData(message: cellModel)
    return cell
  }
}
