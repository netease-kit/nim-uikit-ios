// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class FunConversationSearchController: NEBaseConversationSearchController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    tag = "FunConversationSearchController"
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .funConversationBackgroundColor
    navigationController?.isNavigationBarHidden = true
    customNavigationView.isHidden = true
    emptyView.setEmptyImage(name: "fun_user_empty")
  }

  override open func setupSubviews() {
    super.setupSubviews()
    let leftImageView = UIImageView(image: UIImage
      .ne_imageNamed(name: "funSearch"))
    searchTextField.leftView = leftImageView
    searchTextField.font = UIFont.systemFont(ofSize: 16)
    searchTextField.textColor = .black
    searchTextField.layer.cornerRadius = 4
    searchTextField.backgroundColor = .white
    NSLayoutConstraint.activate([
      searchTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: NEConstant.statusBarHeight + 12),
      searchTextField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8),
      searchTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -72),
      searchTextField.heightAnchor.constraint(equalToConstant: 36),
    ])

    let cancelButton = UIButton()
    cancelButton.translatesAutoresizingMaskIntoConstraints = false
    cancelButton.setTitle(localizable("cancel"), for: .normal)
    cancelButton.setTitleColor(.ne_greyText, for: .normal)
    cancelButton.addTarget(self, action: #selector(backEvent), for: .touchUpInside)
    cancelButton.titleLabel?.adjustsFontSizeToFitWidth = true
    cancelButton.contentHorizontalAlignment = .center
    view.addSubview(cancelButton)
    NSLayoutConstraint.activate([
      cancelButton.centerYAnchor.constraint(equalTo: searchTextField.centerYAnchor),
      cancelButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -5),
      cancelButton.widthAnchor.constraint(equalToConstant: 55),
    ])

    tableView.sectionHeaderHeight = 38
    NSLayoutConstraint.activate([
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      tableView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 12),
    ])
    tableView.register(
      FunConversationSearchCell.self,
      forCellReuseIdentifier: "\(NSStringFromClass(NEBaseConversationSearchCell.self))"
    )
    tableView.register(
      FunSearchSessionHeaderView.self,
      forHeaderFooterViewReuseIdentifier: "\(NSStringFromClass(SearchSessionBaseView.self))"
    )
    tableView.backgroundColor = .funConversationBackgroundColor
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0
    }
    searchTextField.becomeFirstResponder()
  }

  // MARK: UITableViewDelegate, UITableViewDataSource

  override open func tableView(_ tableView: UITableView,
                               viewForHeaderInSection section: Int) -> UIView? {
    let sectionView = tableView
      .dequeueReusableHeaderFooterView(
        withIdentifier: "\(NSStringFromClass(SearchSessionBaseView.self))"
      ) as! FunSearchSessionHeaderView
    sectionView.title.textColor = .funConversationSearchHeaderViewTitleColor
    sectionView.bottomLine.backgroundColor = .funConversationLineBorderColor
    sectionView.setUpTitle(title: headTitleArr[section])
    return sectionView
  }
}
