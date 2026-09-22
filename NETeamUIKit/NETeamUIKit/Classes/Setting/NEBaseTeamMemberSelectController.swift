//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NEBaseUIKit
import UIKit

@objcMembers
open class NEBaseTeamMemberSelectController: NETeamBaseViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, TeamMemberSelectViewModelDelegate {
  public var selectMemberBlock: NESelectTeamMemberBlock?
  public var showAllMembers: Bool = false // 是否显示所有群成员

  let viewModel = TeamMemberSelectViewModel()

  private var renderedAccountIds = [String?]()
  private var searchStartPosition: (accountId: String, relativeY: CGFloat, contentOffsetX: CGFloat)?

  open var memberLoadStatusTintColor: UIColor { .ne_normalTheme }

  /// 群id
  var teamId: String?

  public var cellClassDic = [Int: UITableViewCell.Type]() // key 值为 table section 值

  /// 搜索输入框
  public lazy var searchInput: UITextField = {
    let searchInput = NESingleLineTextField()
    searchInput.textColor = UIColor(hexString: "333333")
    searchInput.placeholder = localizable("search_member")
    searchInput.font = UIFont.systemFont(ofSize: 14.0)
    searchInput.returnKeyType = .search
    searchInput.delegate = self
    searchInput.clearButtonMode = .always
    return searchInput
  }()

  /// 选择数量限制
  public var selectCountLimit = 10

  /// 内容列表
  public lazy var contentTableView: UITableView = {
    let tableView = UITableView()
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .clear
    tableView.dataSource = self
    tableView.delegate = self
    tableView.separatorColor = .clear
    tableView.separatorStyle = .none
    tableView.sectionHeaderHeight = 12.0
    tableView
      .tableFooterView =
      UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 12))
    tableView.keyboardDismissMode = .onDrag

    tableView.estimatedRowHeight = 0
    tableView.estimatedSectionHeaderHeight = 0
    tableView.estimatedSectionFooterHeight = 0

    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }
    return tableView
  }()

  /// 搜索框背景视图
  let searchBackView = UIView()

  override open func viewDidLoad() {
    super.viewDidLoad()

    emptyView.setEmptyImage(name: "user_empty")
    emptyView.setText(localizable("member_select_no_member"))
    viewModel.delegate = self
    setupUI()
    if let tid = teamId {
      viewModel.getTeamInfo(tid, showAllMembers) { [weak self] error in
        if let err = error {
          self?.view.neMakeToast(err.localizedDescription)
        } else {
          print("获取群信息成功 : ", self?.viewModel.teamInfoModel?.users.count as Any)
        }
        self?.didReloadTableData()
      }
      didReloadTableData()
    }
  }

  /// 刷新列表
  open func didReloadTableData() {
    if viewModel.isLoadingMembers || viewModel.memberLoadError != nil {
      emptyView.isHidden = true
    } else if viewModel.showDatas.count <= 0 {
      emptyView.isHidden = false
    } else {
      emptyView.isHidden = true
    }
    let canSubmit = !viewModel.isLoadingMembers && viewModel.memberLoadError == nil
    navigationView.moreButton.isEnabled = canSubmit
    navigationView.moreButton.alpha = canSubmit ? 1 : 0.45
    updateMemberLoadStatus()
    reloadPreservingTopMember()
  }

  let searchImageView: UIImageView = {
    let searchImageView = UIImageView()
    searchImageView.image = coreLoader.loadImage("textField_search_icon")
    searchImageView.translatesAutoresizingMaskIntoConstraints = false
    return searchImageView
  }()

  open func setupUI() {
    view.backgroundColor = .white
    view.addSubview(contentTableView)

    view.addSubview(searchBackView)
    searchBackView.backgroundColor = UIColor(hexString: "F2F4F5")
    searchBackView.translatesAutoresizingMaskIntoConstraints = false
    searchBackView.clipsToBounds = true
    searchBackView.layer.cornerRadius = 4.0
    NSLayoutConstraint.activate([
      searchBackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      searchBackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      searchBackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 13 + topConstant),
      searchBackView.heightAnchor.constraint(equalToConstant: 32),
    ])

    searchBackView.addSubview(searchImageView)
    NSLayoutConstraint.activate([
      searchImageView.centerYAnchor.constraint(equalTo: searchBackView.centerYAnchor),
      searchImageView.leftAnchor.constraint(equalTo: searchBackView.leftAnchor, constant: 18),
      searchImageView.widthAnchor.constraint(equalToConstant: 13),
      searchImageView.heightAnchor.constraint(equalToConstant: 13),
    ])

    searchBackView.addSubview(searchInput)
    searchInput.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      searchInput.leftAnchor.constraint(equalTo: searchImageView.rightAnchor, constant: 5),
      searchInput.rightAnchor.constraint(equalTo: searchBackView.rightAnchor, constant: -18),
      searchInput.topAnchor.constraint(equalTo: searchBackView.topAnchor),
      searchInput.bottomAnchor.constraint(equalTo: searchBackView.bottomAnchor),
    ])

    if let clearButton = searchInput.value(forKey: "_clearButton") as? UIButton {
      clearButton.accessibilityIdentifier = "id.clear"
    }
    searchInput.accessibilityIdentifier = "id.addFriendAccount"

    NSLayoutConstraint.activate([
      contentTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentTableView.topAnchor.constraint(equalTo: searchBackView.bottomAnchor),
      contentTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    for (key, value) in cellClassDic {
      contentTableView.register(value, forCellReuseIdentifier: "\(key)")
    }

    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
      emptyView.widthAnchor.constraint(equalToConstant: 122),
      emptyView.heightAnchor.constraint(equalToConstant: 91),
    ])

    navigationView.moreButton.isHidden = false
    navigationView.moreButton.setImage(nil, for: .normal)
    navigationView.moreButton.addTarget(self, action: #selector(didClickSure), for: .touchUpInside)
    didChangeSelectMember()
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.showDatas.count
  }

  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    UITableViewCell()
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let model = viewModel.showDatas[indexPath.row]
    guard let cell = tableView.cellForRow(at: indexPath) as? NEBaseTeamMemberSelectCell else {
      return
    }
    if let member = model.member, let accid = member.teamMember?.accountId {
      if viewModel.selectDic[accid] != nil {
        viewModel.selectDic[accid] = nil
        model.isSelected = false
        cell.checkImageView.isHighlighted = false
      } else {
        if viewModel.selectDic.count >= selectCountLimit {
          if selectCountLimit == 1 {
            for c in tableView.visibleCells {
              if let c = c as? NEBaseTeamMemberSelectCell {
                c.checkImageView.isHighlighted = false
                c.currentModel?.isSelected = false
                viewModel.selectDic.removeAll()
              }
            }
          } else {
            view.neMakeToast(String(format: localizable("select_limit_tip"), selectCountLimit))
            return
          }
        }

        viewModel.selectDic[accid] = member
        model.isSelected = true
        cell.checkImageView.isHighlighted = true
      }
      didChangeSelectMember()
    }
  }

  open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    0
  }

  open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    guard let text = textField.text else {
      return false
    }
    if text.count <= 0 {
      return false
    }
    return true
  }

  open func textFieldShouldClear(_ textField: UITextField) -> Bool {
    viewModel.resetSearchResults()
    viewModel.showDatas = viewModel.datas
    didReloadTableData()
    restoreSearchStartPositionIfNeeded()
    return true
  }

  /// 文本输入变更
  open func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let finalString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
    let previousKeyword = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let normalizedKeyword = finalString.trimmingCharacters(in: .whitespacesAndNewlines)
    let wasSearching = !previousKeyword.isEmpty
    let willSearch = !normalizedKeyword.isEmpty
    if !wasSearching, willSearch {
      searchStartPosition = currentScrollPosition()
    }
    if finalString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      viewModel.resetSearchResults()
      viewModel.showDatas = viewModel.datas
    } else {
      viewModel.showDatas = viewModel.searchAllData(finalString)
    }
    didReloadTableData()
    if !willSearch {
      restoreSearchStartPositionIfNeeded()
    } else if previousKeyword != normalizedKeyword {
      scrollSearchResultsToTop()
    }
    return true
  }

  /// 选择成员变更回调，内部根据选择数量来做右上角状态变更
  open func didChangeSelectMember() {
    if !viewModel.selectDic.isEmpty {
      let title = commonLocalizable("sure") + "(\(viewModel.selectDic.count))"
      navigationView.moreButton.setTitle(title, for: .normal)
      navigationView.setMoreButtonWidth(90)
    } else {
      navigationView.moreButton.setTitle(commonLocalizable("sure"), for: .normal)
    }
  }

  /// 刷新回调
  open func didNeedRefresh() {
    let keyword = searchInput.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if keyword.isEmpty {
      viewModel.resetSearchResults()
      viewModel.showDatas = viewModel.datas
    } else {
      viewModel.showDatas = viewModel.searchAllData(keyword)
    }
    didReloadTableData()
    didChangeSelectMember()
  }

  private func reloadPreservingTopMember() {
    let anchor = contentTableView.indexPathsForVisibleRows?
      .sorted()
      .first
      .flatMap { indexPath -> (String, CGFloat)? in
        guard renderedAccountIds.indices.contains(indexPath.row),
              let accountId = renderedAccountIds[indexPath.row] else {
          return nil
        }
        let relativeY = contentTableView.rectForRow(at: indexPath).minY - contentTableView.contentOffset.y
        return (accountId, relativeY)
      }
    let nextRenderedAccountIds = viewModel.showDatas.map {
      $0.member?.teamMember?.accountId ?? $0.member?.nimUser?.user?.accountId
    }

    UIView.performWithoutAnimation {
      contentTableView.reloadData()
      contentTableView.layoutIfNeeded()
    }
    renderedAccountIds = nextRenderedAccountIds

    guard let anchor,
          let row = viewModel.showDatas.firstIndex(where: {
            $0.member?.teamMember?.accountId == anchor.0
          }) else {
      return
    }
    let rect = contentTableView.rectForRow(at: IndexPath(row: row, section: 0))
    let minimumY = -contentTableView.adjustedContentInset.top
    let maximumY = max(
      minimumY,
      contentTableView.contentSize.height - contentTableView.bounds.height + contentTableView.adjustedContentInset.bottom
    )
    let targetY = min(max(rect.minY - anchor.1, minimumY), maximumY)
    contentTableView.setContentOffset(CGPoint(x: contentTableView.contentOffset.x, y: targetY), animated: false)
  }

  private func scrollSearchResultsToTop() {
    contentTableView.layoutIfNeeded()
    contentTableView.setContentOffset(
      CGPoint(x: contentTableView.contentOffset.x, y: -contentTableView.adjustedContentInset.top),
      animated: false
    )
  }

  private func currentScrollPosition() -> (accountId: String, relativeY: CGFloat, contentOffsetX: CGFloat)? {
    guard let indexPath = contentTableView.indexPathsForVisibleRows?.sorted().first,
          renderedAccountIds.indices.contains(indexPath.row),
          let accountId = renderedAccountIds[indexPath.row] else {
      return nil
    }
    let relativeY = contentTableView.rectForRow(at: indexPath).minY - contentTableView.contentOffset.y
    return (accountId, relativeY, contentTableView.contentOffset.x)
  }

  private func restoreSearchStartPositionIfNeeded() {
    guard let position = searchStartPosition else {
      return
    }
    defer { searchStartPosition = nil }
    guard let row = viewModel.showDatas.firstIndex(where: {
      ($0.member?.teamMember?.accountId ?? $0.member?.nimUser?.user?.accountId) == position.accountId
    }) else {
      return
    }
    let rect = contentTableView.rectForRow(at: IndexPath(row: row, section: 0))
    let minimumY = -contentTableView.adjustedContentInset.top
    let maximumY = max(
      minimumY,
      contentTableView.contentSize.height - contentTableView.bounds.height + contentTableView.adjustedContentInset.bottom
    )
    let targetY = min(max(rect.minY - position.relativeY, minimumY), maximumY)
    contentTableView.setContentOffset(CGPoint(x: position.contentOffsetX, y: targetY), animated: false)
  }

  private func updateMemberLoadStatus() {
    if viewModel.isLoadingMembers {
      let footer = UIView(frame: CGRect(x: 0, y: 0, width: contentTableView.bounds.width, height: 44))
      let indicator = UIActivityIndicatorView(style: .medium)
      indicator.color = memberLoadStatusTintColor
      indicator.center = CGPoint(x: footer.bounds.midX, y: footer.bounds.midY)
      indicator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
      indicator.startAnimating()
      footer.addSubview(indicator)
      contentTableView.tableFooterView = footer
    } else if let error = viewModel.memberLoadError {
      let footer = UIView(frame: CGRect(x: 0, y: 0, width: contentTableView.bounds.width, height: 52))
      let button = UIButton(type: .system)
      button.frame = footer.bounds
      button.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      button.tintColor = memberLoadStatusTintColor
      button.setTitleColor(memberLoadStatusTintColor, for: .normal)
      button.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
      button.setTitle(error.localizedDescription, for: .normal)
      button.titleLabel?.font = .systemFont(ofSize: 14)
      button.titleLabel?.numberOfLines = 2
      button.addTarget(self, action: #selector(retryMemberLoad), for: .touchUpInside)
      footer.addSubview(button)
      contentTableView.tableFooterView = footer
    } else {
      contentTableView.tableFooterView = UIView(
        frame: CGRect(x: 0, y: 0, width: contentTableView.bounds.width, height: 12)
      )
    }
  }

  @objc private func retryMemberLoad() {
    guard let teamId else { return }
    viewModel.getTeamInfo(teamId, showAllMembers) { [weak self] error in
      if let error {
        self?.view.neMakeToast(error.localizedDescription)
      }
      self?.didReloadTableData()
    }
  }

  /// 点击确定添加回调
  open func didClickSure() {
    guard !viewModel.isLoadingMembers, viewModel.memberLoadError == nil else { return }
    if !showAllMembers,
       viewModel.selectDic.count + viewModel.managerSet.count > selectCountLimit {
      view.neMakeToast(String(format: localizable("max_managers_tip"), selectCountLimit))
      return
    }

    if viewModel.selectDic.count <= 0 {
      view.neMakeToast(localizable("member_empty_tip"))
      return
    }

    var retArray = [NETeamMemberInfoModel]()
    for (_, value) in viewModel.selectDic {
      retArray.append(value)
    }

    if let block = selectMemberBlock {
      block(retArray)
    }
  }
}
