// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

open class NEConversationGroupAddConversationController: NEConversationBaseViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
  public var complete: (() -> Void)?
  var partialFailure: (() -> Void)?
  private let group: NEConversationGroupModel
  private let groupViewModel: ConversationGroupViewModel
  private let addViewModel: ConversationGroupAddViewModel
  private let style: NEConversationGroupUIStyle
  private let searchBar = UISearchBar()
  private let tableView = UITableView(frame: .zero, style: .plain)
  private lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(
      image: UIImage.ne_imageNamed(name: style.emptyImageName),
      content: localizable("session_empty"),
      frame: .zero
    )
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isUserInteractionEnabled = false
    view.isHidden = true
    return view
  }()

  private var keyword = ""

  init(group: NEConversationGroupModel, existingIds: Set<String>, viewModel: ConversationGroupViewModel, style: NEConversationGroupUIStyle = .normal) {
    self.group = group
    groupViewModel = viewModel
    self.style = style
    addViewModel = ConversationGroupAddViewModel(groupId: group.groupId, existingIds: existingIds)
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    updateDoneTitle()
    view.backgroundColor = style.pageBackgroundColor
    navigationView.backgroundColor = style.navigationBackgroundColor
    navigationView.setBackButtonTitle(localizable("cancel"))
    navigationView.setBackButtonWidth(56)
    navigationView.moreButton.isHidden = false
    navigationView.addMoreButtonTarget(target: self, selector: #selector(doneAction))
    setupSearch()
    setupTable()
    loadMore()
  }

  private func setupSearch() {
    searchBar.translatesAutoresizingMaskIntoConstraints = false
    searchBar.placeholder = localizable("conversation_group_search_hint")
    searchBar.delegate = self
    searchBar.tintColor = style.primaryColor
    searchBar.barTintColor = style.contentBackgroundColor
    searchBar.backgroundColor = style.contentBackgroundColor
    searchBar.backgroundImage = UIImage()
    searchBar.searchBarStyle = .minimal
    if #available(iOS 13.0, *) {
      searchBar.searchTextField.backgroundColor = .white
    }
    view.addSubview(searchBar)
    NSLayoutConstraint.activate([
      searchBar.topAnchor.constraint(equalTo: navigationView.bottomAnchor),
      searchBar.leftAnchor.constraint(equalTo: view.leftAnchor),
      searchBar.rightAnchor.constraint(equalTo: view.rightAnchor),
      searchBar.heightAnchor.constraint(equalToConstant: 52),
    ])
  }

  private func setupTable() {
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.backgroundColor = style.contentBackgroundColor
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(AddConversationCell.self, forCellReuseIdentifier: "AddConversationCell")
    view.addSubview(tableView)
    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      emptyView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
      emptyView.leftAnchor.constraint(equalTo: view.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: view.rightAnchor),
      emptyView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
    ])
  }

  private func loadMore() {
    addViewModel.loadMore { [weak self] error, _ in
      guard let self = self else { return }
      self.tableView.reloadData()
      self.refreshEmpty()

      // 过滤掉已在分组中的会话后，当前页可能不足一页；继续拉取，
      // 避免用户必须上拉才能看到下一页可添加的会话。
      if self.keyword.isEmpty,
         error == nil,
         self.addViewModel.finished == false,
         self.addViewModel.displayData.count < self.addViewModel.pageSize {
        self.loadMore()
      }
    }
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    addViewModel.displayData.count
  }

  public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    62
  }

  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "AddConversationCell", for: indexPath) as! AddConversationCell
    let model = addViewModel.displayData[indexPath.row]
    cell.configure(model, selected: addViewModel.selectedIds.contains(model.conversation?.conversationId ?? ""), keyword: keyword, style: style)
    return cell
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let conversationId = addViewModel.displayData[indexPath.row].conversation?.conversationId else {
      return
    }
    if addViewModel.selectedIds.contains(conversationId) == false,
       addViewModel.existingCount + addViewModel.selectedIds.count >= 100 {
      showToast(localizable("conversation_group_members_limit"))
      return
    }
    addViewModel.toggle(conversationId)
    updateDoneTitle()
    let selected = addViewModel.selectedIds.contains(conversationId)
    (tableView.cellForRow(at: indexPath) as? AddConversationCell)?.updateSelected(selected, style: style)
  }

  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if keyword.isEmpty,
       addViewModel.finished == false,
       scrollView.contentOffset.y + scrollView.bounds.height > scrollView.contentSize.height - 80 {
      loadMore()
    }
  }

  public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    keyword = searchText
    addViewModel.search(searchText)
    tableView.reloadData()
    refreshEmpty()
  }

  private func updateDoneTitle() {
    let count = addViewModel.selectedIds.count
    let enabled = count > 0
    title = String(format: localizable("conversation_group_add_title"), count, 100)
    navigationView.setMoreButtonTitle(
      localizable("confirm"),
      enabled ? style.primaryColor : style.primaryDisabledColor
    )
    navigationView.moreButton.isEnabled = enabled
    navigationView.setMoreButtonWidth(60)
  }

  private func refreshEmpty() {
    emptyView.isHidden = addViewModel.displayData.isEmpty == false
  }

  @objc private func doneAction() {
    guard addViewModel.selectedIds.isEmpty == false else {
      return
    }
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }
    groupViewModel.addConversations(groupId: group.groupId, conversationIds: Array(addViewModel.selectedIds)) { [weak self] results, error in
      guard let self = self else {
        return
      }
      if error != nil {
        self.showToast(self.groupViewModel.groupErrorMessage(error))
        return
      }
      let failedResults = results?.filter { result in
        guard let error = result.error as V2NIMError? else { return false }
        return error.code != 0 && error.code != 200
      } ?? []
      if failedResults.count == self.addViewModel.selectedIds.count {
        let firstError = failedResults.first?.error.nserror as NSError?
        self.showToast(self.groupViewModel.groupErrorMessage(firstError))
        return
      }
      let hasPartialFailure = failedResults.isEmpty == false
      self.complete?()
      self.navigationController?.popViewController(animated: true)
      if hasPartialFailure {
        self.partialFailure?()
      }
    }
  }
}

private final class AddConversationCell: UITableViewCell {
  private let checkImageView = UIImageView()
  private let avatar = NEUserHeaderView(frame: .zero)
  private let titleLabel = UILabel()
  private let line = UIView()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    for item in [checkImageView, avatar, titleLabel, line] {
      item.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview(item)
    }
    checkImageView.contentMode = .center
    titleLabel.font = .systemFont(ofSize: 16)
    titleLabel.textColor = .ne_darkText
    titleLabel.lineBreakMode = .byTruncatingTail
    avatar.clipsToBounds = true
    NSLayoutConstraint.activate([
      checkImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      checkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      checkImageView.widthAnchor.constraint(equalToConstant: 24),
      checkImageView.heightAnchor.constraint(equalToConstant: 24),
      avatar.leftAnchor.constraint(equalTo: checkImageView.rightAnchor, constant: 12),
      avatar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      avatar.widthAnchor.constraint(equalToConstant: 48),
      avatar.heightAnchor.constraint(equalToConstant: 48),
      titleLabel.leftAnchor.constraint(equalTo: avatar.rightAnchor, constant: 12),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
      titleLabel.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
      line.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
      line.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      line.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      line.heightAnchor.constraint(equalToConstant: 0.5),
    ])
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func configure(_ model: NEConversationListModel, selected: Bool, keyword: String, style: NEConversationGroupUIStyle) {
    contentView.backgroundColor = style.cardBackgroundColor
    titleLabel.textColor = style.titleTextColor
    avatar.layer.cornerRadius = style.addConversationAvatarCornerRadius
    line.backgroundColor = style.lineColor
    updateSelected(selected, style: style)
    let title = model.conversation?.name ?? model.conversation?.conversationId ?? ""
    if keyword.isEmpty {
      titleLabel.attributedText = nil
      titleLabel.text = title
    } else {
      let attributed = NSMutableAttributedString(string: title)
      let range = (title as NSString).range(of: keyword, options: .caseInsensitive)
      if range.location != NSNotFound {
        attributed.addAttribute(.foregroundColor, value: style.primaryColor, range: range)
      }
      titleLabel.attributedText = attributed
    }
    avatar.configHeadData(headUrl: model.conversation?.avatar, name: model.conversation?.shortName() ?? "", uid: model.conversation?.conversationId ?? "")
  }

  func updateSelected(_ selected: Bool, style: NEConversationGroupUIStyle) {
    checkImageView.image = UIImage.ne_imageNamed(name: selected ? style.selectedImageName : style.unselectedImageName)
  }
}
