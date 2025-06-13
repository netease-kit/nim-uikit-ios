
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class FunTeamHistoryMessageController: NEBaseTeamHistoryMessageController {
  public lazy var searchView: FunSearchView = {
    let view = FunSearchView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.searchButton.setImage(coreLoader.loadImage("fun_search"), for: .normal)
    view.searchButton.setTitle(localizable("search"), for: .normal)
    return view
  }()

  override public init(teamId: String?) {
    super.init(teamId: teamId)
    tag = "FunTeamHistoryMessageController"
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .funTeamBackgroundColor
    navigationController?.isNavigationBarHidden = true
    navigationView.isHidden = true
    emptyView.backgroundColor = .clear
    emptyView.setEmptyImage(name: "fun_emptyView")
  }

  override open func setupSubviews() {
    super.setupSubviews()

    let cancelButton = UIButton()
    cancelButton.translatesAutoresizingMaskIntoConstraints = false
    cancelButton.setTitle(commonLocalizable("cancel"), for: .normal)
    cancelButton.setTitleColor(.ne_greyText, for: .normal)
    cancelButton.addTarget(self, action: #selector(backEvent), for: .touchUpInside)

    view.addSubview(cancelButton)
    NSLayoutConstraint.activate([
      cancelButton.centerYAnchor.constraint(equalTo: searchTextField.centerYAnchor),
      cancelButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -12),
      cancelButton.widthAnchor.constraint(equalToConstant: NEAppLanguageUtil.getCurrentLanguage() == .english ? 60 : 40),
    ])

    let leftImageView = UIImageView(image: coreLoader.loadImage("fun_search"))
    searchTextField.leftView = leftImageView
    searchTextField.font = UIFont.systemFont(ofSize: 16)
    searchTextField.textColor = .black
    searchTextField.layer.cornerRadius = 4
    searchTextField.backgroundColor = .white
    NSLayoutConstraint.activate([
      searchTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: NEConstant.statusBarHeight + 12),
      searchTextField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8),
      searchTextField.rightAnchor.constraint(equalTo: cancelButton.leftAnchor, constant: -8),
      searchTextField.heightAnchor.constraint(equalToConstant: 36),
    ])

    tableView.backgroundColor = .funTeamBackgroundColor
    NSLayoutConstraint.activate([
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      tableView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 12),
    ])
    tableView.register(
      FunHistoryMessageCell.self,
      forCellReuseIdentifier: "\(NSStringFromClass(FunHistoryMessageCell.self))"
    )

    tableView.register(
      FunSearchSessionHeaderView.self,
      forHeaderFooterViewReuseIdentifier: "\(NSStringFromClass(FunSearchSessionHeaderView.self))"
    )
  }

  override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(NSStringFromClass(FunHistoryMessageCell.self))",
      for: indexPath
    ) as! NEBaseHistoryMessageCell
    let cellModel = viewModel.searchResultInfos?[indexPath.row]
    cell.searchText = searchStr
    cell.configData(message: cellModel)
    return cell
  }
}
