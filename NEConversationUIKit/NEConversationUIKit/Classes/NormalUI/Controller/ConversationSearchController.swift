
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class SearchSessionHeaderView: SearchSessionBaseView {
  override open func setupUI() {
    super.setupUI()
    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
    ])

    NSLayoutConstraint.activate([
      bottomLine.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      bottomLine.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
      bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      bottomLine.heightAnchor.constraint(equalToConstant: 1),
    ])
  }
}

@objcMembers
open class ConversationSearchController: NEBaseConversationSearchController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    tag = "ConversationSearchController"
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    searchTextFieldTopAnchor?.constant = topConstant + 20
  }

  override open func setupSubviews() {
    super.setupSubviews()
    title = commonLocalizable("search")
    navigationController?.navigationBar.backgroundColor = .white
    navigationView.backgroundColor = .white
    navigationView.moreButton.isHidden = true

    searchTextField.placeholder = localizable("search_keyword")
    searchTextFieldTopAnchor = searchTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant + 20)
    searchTextFieldTopAnchor?.isActive = true
    NSLayoutConstraint.activate([
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
      ConversationSearchCell.self,
      forCellReuseIdentifier: "\(NSStringFromClass(NEBaseConversationSearchCell.self))"
    )
    tableView.register(
      SearchSessionHeaderView.self,
      forHeaderFooterViewReuseIdentifier: "\(NSStringFromClass(SearchSessionBaseView.self))"
    )
  }
}
