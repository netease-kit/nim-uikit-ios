// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEBaseUIKit
import NIMSDK
import UIKit

@objcMembers
open class FunConversationSearchController: NEBaseConversationSearchController {
  /// 返回按钮：统一返回箭头，原「取消」文案只保留为无障碍标签
  lazy var cancelButton: NEUnifiedBackButton = {
    let button = NEUnifiedBackButton(accessibilityLabel: commonLocalizable("cancel"))
    button.accessibilityIdentifier = "id.backArrow"
    button.addTarget(self, action: #selector(backEvent), for: .touchUpInside)
    return button
  }()

  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    tag = "FunConversationSearchController"
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  /// 搜索框左间距约束：侧栏承载时页面返回入口被侧栏接管，需要收回到 12。
  private var searchTextFieldLeftAnchor: NSLayoutConstraint?

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .funConversationBackgroundColor
    emptyView.setEmptyImage(name: "fun_user_empty")
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.isNavigationBarHidden = true
    navigationView.isHidden = true
  }

  override open func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updateSearchFieldLeftInset()
  }

  /// 侧栏承载时返回入口由侧栏展示，页面原按钮按 alpha=0 隐藏；
  /// 此处把搜索框左间距从「返回按钮 + 间距」收回到 12，避免留下不可见的空位。
  private func updateSearchFieldLeftInset() {
    guard let searchTextFieldLeftAnchor else { return }
    let hasPageBackEntry = !cancelButton.isHidden && cancelButton.alpha > 0.01
    let inset: CGFloat = hasPageBackEntry ? 58 : 12
    if abs(searchTextFieldLeftAnchor.constant - inset) > 0.5 {
      searchTextFieldLeftAnchor.constant = inset
    }
  }

  /// 初始化子视图
  override open func setupSubviews() {
    super.setupSubviews()
    let leftImageView = UIImageView(image: coreLoader.loadImage("fun_search"))
    searchTextField.leftView = leftImageView
    searchTextField.font = UIFont.systemFont(ofSize: 16)
    searchTextField.textColor = .black
    searchTextField.layer.cornerRadius = 4
    searchTextField.backgroundColor = .white
    searchTextFieldTopAnchor = searchTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: NEConstant.statusBarHeight + 12)
    searchTextFieldTopAnchor?.isActive = true
    // 返回入口统一放在左侧，搜索框紧随其后，避免箭头出现在右侧产生方向歧义。
    let searchTextFieldLeftAnchor = searchTextField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 58)
    self.searchTextFieldLeftAnchor = searchTextFieldLeftAnchor
    NSLayoutConstraint.activate([
      searchTextFieldLeftAnchor,
      searchTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -12),
      searchTextField.heightAnchor.constraint(equalToConstant: 36),
    ])

    view.addSubview(cancelButton)
    NSLayoutConstraint.activate([
      cancelButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
      cancelButton.centerYAnchor.constraint(equalTo: searchTextField.centerYAnchor),
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

    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: DispatchWorkItem(block: { [weak self] in
      self?.searchTextField.becomeFirstResponder()
    }))
  }

  // MARK: UITableViewDelegate, UITableViewDataSource

  override open func tableView(_ tableView: UITableView,
                               viewForHeaderInSection section: Int) -> UIView? {
    let sectionView = tableView
      .dequeueReusableHeaderFooterView(
        withIdentifier: "\(NSStringFromClass(SearchSessionBaseView.self))"
      ) as! FunSearchSessionHeaderView
    sectionView.titleLabel.textColor = .funConversationSearchHeaderViewTitleColor
    sectionView.bottomLine.backgroundColor = .funConversationLineBorderColor
    sectionView.setUpTitle(title: headTitleArr[section])
    return sectionView
  }
}
