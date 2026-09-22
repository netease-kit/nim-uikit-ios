
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NEBaseUIKit
import NIMSDK
import UIKit

public typealias DidSelectedAtRow = (_ index: Int, _ model: NETeamMemberInfoModel?) -> Void

@objcMembers
open class NEBaseSelectUserViewController: NEChatBaseViewController, UITableViewDelegate,
  UITableViewDataSource, UITextFieldDelegate {
  public var tableView = UITableView(frame: .zero, style: .plain)
  public var conversationId: String
  public var viewModel = TeamMemberSelectVM()
  public var selectedBlock: DidSelectedAtRow?
  public var allMembers = [NETeamMemberInfoModel]()
  public var visibleMembers = [NETeamMemberInfoModel]()
  public var aiAccountIds = Set<String>()
  public var searchKeyword = ""
  public private(set) var isLoadingMembers = false
  public private(set) var memberLoadError: NSError?
  var teamInfo: NETeamInfoModel?
  private var loadGeneration = UUID()
  private var searchableTeamMemberAccountIds = Set<String>()
  private var renderedAccountIds = [String?]()
  private var searchStartPosition: (accountId: String, relativeY: CGFloat, contentOffsetX: CGFloat)?
  //// 是否展示自己
  private var showSelf = true
  private var showTeamMembers: Bool = false
  var logClassName = "SelectUserViewController"
  var isShowAtAll = true

  open var searchIconName: String { "textField_search_icon" }
  open var searchFieldBackgroundColor: UIColor { UIColor(hexString: "#F2F4F5") }
  open var searchFieldTextColor: UIColor { .ne_darkText }
  open var searchFieldFont: UIFont { .systemFont(ofSize: 14) }
  open var searchFieldCornerRadius: CGFloat { 4 }
  open var searchFieldHorizontalInset: CGFloat { 20 }
  open var searchFieldHeight: CGFloat { 32 }
  open var searchEmptyImageName: String { "user_empty" }
  open var memberLoadStatusTintColor: UIColor { .ne_normalTheme }

  public lazy var searchTextField: SearchTextField = {
    let textField = NESingleLineSearchTextField()
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.leftView = UIImageView(image: coreLoader.loadImage(searchIconName))
    textField.leftViewMode = .always
    textField.placeholder = chatLocalizable("user_search_placeholder")
    textField.font = searchFieldFont
    textField.textColor = searchFieldTextColor
    textField.backgroundColor = searchFieldBackgroundColor
    textField.layer.cornerRadius = searchFieldCornerRadius
    textField.clearButtonMode = .whileEditing
    textField.returnKeyType = .search
    textField.delegate = self
    textField.accessibilityIdentifier = "id.search"
    textField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
    if let clearButton = textField.value(forKey: "_clearButton") as? UIButton {
      clearButton.accessibilityIdentifier = "id.clear"
    }
    return textField
  }()

  public var isSearching: Bool {
    !searchKeyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  public init(conversationId: String, showSelf: Bool = true, showTeamMembers: Bool = false) {
    self.conversationId = conversationId
    self.showSelf = showSelf
    self.showTeamMembers = showTeamMembers
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) {
    conversationId = ""
    showSelf = true
    showTeamMembers = false
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.isNavigationBarHidden = true
    navigationView.isHidden = true
    commonUI()
    loadData()
  }

  /// UI 内容初始化以及布局
  func commonUI() {
    view.backgroundColor = .white

    let button = UIButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.accessibilityIdentifier = "id.arrowDown"
    button.setImage(UIImage.ne_imageNamed(name: "arrowDown"), for: .normal)
    button.addTarget(self, action: #selector(btnEvent), for: .touchUpInside)
    view.addSubview(button)

    NSLayoutConstraint.activate([
      button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      button.widthAnchor.constraint(equalToConstant: 50),
      button.heightAnchor.constraint(equalToConstant: 50),
    ])

    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = chatLocalizable("user_select")
    label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    label.textAlignment = .center
    label.textColor = .ne_darkText
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
      label.topAnchor.constraint(equalTo: view.topAnchor),
      label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
      label.heightAnchor.constraint(equalToConstant: 50),
    ])

    var listTopAnchor = label.bottomAnchor
    var listTopSpacing: CGFloat = 0
    if showTeamMembers {
      view.addSubview(searchTextField)
      NSLayoutConstraint.activate([
        searchTextField.leadingAnchor.constraint(
          equalTo: view.leadingAnchor,
          constant: searchFieldHorizontalInset
        ),
        searchTextField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
        searchTextField.trailingAnchor.constraint(
          equalTo: view.trailingAnchor,
          constant: -searchFieldHorizontalInset
        ),
        searchTextField.heightAnchor.constraint(equalToConstant: searchFieldHeight),
      ])
      listTopAnchor = searchTextField.bottomAnchor
      listTopSpacing = 8
    }

    /// 内容列表
    tableView.delegate = self
    tableView.dataSource = self
    tableView.sectionHeaderHeight = 0
    tableView.sectionFooterHeight = 0
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.tableFooterView = UIView()
    tableView.keyboardDismissMode = .onDrag
    tableView.estimatedRowHeight = 0
    tableView.estimatedSectionHeaderHeight = 0
    tableView.estimatedSectionFooterHeight = 0

    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.topAnchor.constraint(equalTo: listTopAnchor, constant: listTopSpacing),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor
        .constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
    ])

    emptyView.setEmptyImage(name: searchEmptyImageName)
    emptyView.setText(chatLocalizable("user_search_empty"))
    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
      emptyView.topAnchor.constraint(equalTo: tableView.topAnchor),
      emptyView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
      emptyView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
    ])
  }

  func loadData() {
    // 数字人列表
    var aiUserMembers = [NETeamMemberInfoModel]()
    if IMKitConfigCenter.shared.enableAIUser {
      let aiUsers = NEAIUserManager.shared.getAIChatUserList()
      aiUserMembers = aiUsers.map { user in
        let teamMember = NETeamMemberInfoModel()
        teamMember.nimUser = NEUserWithFriend(user: user)
        return teamMember
      }
    }
    aiAccountIds = Set(aiUserMembers.compactMap { $0.nimUser?.user?.accountId })

    if !showTeamMembers {
      let team = NETeamInfoModel()
      team.users = aiUserMembers
      teamInfo = team
      allMembers = aiUserMembers
      visibleMembers = aiUserMembers
      isShowAtAll = false
      reloadSearchResults()
      return
    }

    guard V2NIMConversationIdUtil.conversationType(conversationId) == .CONVERSATION_TYPE_TEAM,
          let teamId = V2NIMConversationIdUtil.conversationTargetId(conversationId) else {
      return
    }

    let generation = UUID()
    loadGeneration = generation
    isLoadingMembers = true
    memberLoadError = nil
    if allMembers.isEmpty {
      allMembers = aiUserMembers
      visibleMembers = aiUserMembers
    }
    reloadSearchResults()

    // 获取群成员列表
    NEALog.infoLog(className() + " [Performance]", desc: #function + " start, timestamp: \(Date().timeIntervalSince1970)")
    viewModel.getTeamMembers(
      teamId,
      progress: { [weak self] progress in
        guard let self,
              self.loadGeneration == generation,
              progress.teamId == teamId else { return }
        self.isLoadingMembers = progress.phase == .loading
        self.memberLoadError = progress.error
        if progress.phase == .loading || progress.phase == .finished {
          self.applyLoadedMembers(
            progress.members,
            team: NETeamUserManager.shared.getTeamInfo(),
            aiMembers: aiUserMembers
          )
        } else {
          self.reloadSearchResults()
          if let error = progress.error {
            self.view.neMakeToast(error.localizedDescription)
          }
        }
      }
    ) { [weak self] error, team in
      guard let self, self.loadGeneration == generation else { return }
      NEALog.infoLog(NEBaseSelectUserViewController.className() + " [Performance]", desc: #function + " onSuccess, timestamp: \(Date().timeIntervalSince1970)")
      NEALog.infoLog(
        ModuleName + " " + self.logClassName,
        desc: "CALLBACK fetchTeamMembers " + (error?.localizedDescription ?? "no error")
      )
      if error != nil {
        self.view.neMakeToast(error?.localizedDescription)
        return
      }
      guard let team else {
        self.isLoadingMembers = false
        self.reloadSearchResults()
        return
      }
      self.isLoadingMembers = false
      self.memberLoadError = nil
      NEALog.infoLog(NEBaseSelectUserViewController.className() + " [Performance]", desc: #function + " reload @ tableview, timestamp: \(Date().timeIntervalSince1970)")
      self.applyLoadedMembers(team.users, team: team.team, aiMembers: aiUserMembers)
    }
  }

  private func applyLoadedMembers(_ members: [NETeamMemberInfoModel],
                                  team: V2NIMTeam?,
                                  aiMembers: [NETeamMemberInfoModel]) {
    var filteredMembers = [NETeamMemberInfoModel]()
    var memberByAccountId = [String: NETeamMemberInfoModel]()
    for member in members {
      let accountId = member.teamMember?.accountId ?? member.nimUser?.user?.accountId
      guard let accountId, !accountId.isEmpty else { continue }
      if !showSelf, accountId == IMKitClient.instance.account() {
        if member.teamMember?.memberRole == .TEAM_MEMBER_ROLE_NORMAL,
           let custom = team?.serverExtension,
           let json = getDictionaryFromJSONString(custom),
           let atValue = json[keyAllowAtAll] as? String,
           atValue == allowAtManagerValue {
          isShowAtAll = false
        }
        continue
      }
      memberByAccountId[accountId] = member
      guard !aiAccountIds.contains(accountId) else { continue }
      filteredMembers.append(member)
    }

    searchableTeamMemberAccountIds = Set(memberByAccountId.keys)
    let displayAIMembers = aiMembers.map { aiMember -> NETeamMemberInfoModel in
      aiMember.teamMember = nil
      aiMember.nimUser?.friend = nil
      if let accountId = aiMember.nimUser?.user?.accountId,
         let teamMember = memberByAccountId[accountId] {
        aiMember.teamMember = teamMember.teamMember
        aiMember.nimUser?.friend = teamMember.nimUser?.friend
      }
      return aiMember
    }

    let snapshot = NETeamInfoModel()
    snapshot.team = team
    snapshot.users = displayAIMembers + filteredMembers
    teamInfo = snapshot
    allMembers = snapshot.users
    applySearch()
  }

  public func searchTextChanged(textField: SearchTextField) {
    let nextKeyword = textField.text ?? ""
    let previousKeyword = searchKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
    let normalizedKeyword = nextKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
    let wasSearching = isSearching
    let willSearch = !normalizedKeyword.isEmpty
    if !wasSearching, willSearch {
      searchStartPosition = currentScrollPosition()
    }
    searchKeyword = nextKeyword
    applySearch()
    if willSearch, previousKeyword != normalizedKeyword {
      scrollSearchResultsToTop()
    }
  }

  public func applySearch() {
    let normalizedKeyword = searchKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
    searchTextField.clearButtonMode = normalizedKeyword.isEmpty ? .never : .whileEditing
    guard !normalizedKeyword.isEmpty else {
      visibleMembers = allMembers
      reloadSearchResults()
      restoreSearchStartPositionIfNeeded()
      return
    }

    visibleMembers = allMembers.filter { member in
      let accountId = member.teamMember?.accountId ?? member.nimUser?.user?.accountId
      guard let accountId, !accountId.isEmpty,
            !aiAccountIds.contains(accountId) || searchableTeamMemberAccountIds.contains(accountId) else {
        return false
      }
      return searchResult(for: member) != nil
    }
    reloadSearchResults()
  }

  public func searchResult(for member: NETeamMemberInfoModel) -> NETeamMemberSearchResult? {
    guard isSearching else {
      return nil
    }
    return NETeamMemberSearchMatcher.result(
      keyword: searchKeyword,
      teamNick: member.teamMember?.teamNick,
      friendAlias: member.nimUser?.friend?.alias,
      userNickname: member.nimUser?.user?.name,
      accountId: member.nimUser?.user?.accountId ?? member.teamMember?.accountId
    )
  }

  open func textFieldShouldClear(_ textField: UITextField) -> Bool {
    searchKeyword = ""
    applySearch()
    textField.resignFirstResponder()
    return true
  }

  private func reloadSearchResults() {
    reloadPreservingTopMember()
    updateMemberLoadStatus()
    emptyView.isHidden = !isSearching || !visibleMembers.isEmpty || isLoadingMembers || memberLoadError != nil
  }

  private func scrollSearchResultsToTop() {
    tableView.layoutIfNeeded()
    tableView.setContentOffset(
      CGPoint(x: tableView.contentOffset.x, y: -tableView.adjustedContentInset.top),
      animated: false
    )
  }

  private func reloadPreservingTopMember() {
    let visibleAnchor = tableView.indexPathsForVisibleRows?
      .sorted()
      .first(where: { $0.section == 1 })
    let reloadAnchor = visibleAnchor.flatMap { indexPath -> (String, CGFloat)? in
      guard renderedAccountIds.indices.contains(indexPath.row),
            let accountId = renderedAccountIds[indexPath.row] else {
        return nil
      }
      let relativeY = tableView.rectForRow(at: indexPath).minY - tableView.contentOffset.y
      return (accountId, relativeY)
    }
    let nextRenderedAccountIds = visibleMembers.map {
      $0.teamMember?.accountId ?? $0.nimUser?.user?.accountId
    }

    UIView.performWithoutAnimation {
      tableView.reloadData()
      tableView.layoutIfNeeded()
    }
    renderedAccountIds = nextRenderedAccountIds

    guard let reloadAnchor,
          let row = visibleMembers.firstIndex(where: {
            ($0.teamMember?.accountId ?? $0.nimUser?.user?.accountId) == reloadAnchor.0
          }) else {
      return
    }
    let rect = tableView.rectForRow(at: IndexPath(row: row, section: 1))
    let minimumY = -tableView.adjustedContentInset.top
    let maximumY = max(
      minimumY,
      tableView.contentSize.height - tableView.bounds.height + tableView.adjustedContentInset.bottom
    )
    let targetY = min(max(rect.minY - reloadAnchor.1, minimumY), maximumY)
    tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x, y: targetY), animated: false)
  }

  private func currentScrollPosition() -> (accountId: String, relativeY: CGFloat, contentOffsetX: CGFloat)? {
    guard let indexPath = tableView.indexPathsForVisibleRows?
      .sorted()
      .first(where: { $0.section == 1 }),
      renderedAccountIds.indices.contains(indexPath.row),
      let accountId = renderedAccountIds[indexPath.row] else {
      return nil
    }
    let relativeY = tableView.rectForRow(at: indexPath).minY - tableView.contentOffset.y
    return (accountId, relativeY, tableView.contentOffset.x)
  }

  private func restoreSearchStartPositionIfNeeded() {
    guard let position = searchStartPosition else {
      return
    }
    defer { searchStartPosition = nil }
    guard let row = visibleMembers.firstIndex(where: {
      ($0.teamMember?.accountId ?? $0.nimUser?.user?.accountId) == position.accountId
    }) else {
      return
    }
    let rect = tableView.rectForRow(at: IndexPath(row: row, section: 1))
    let minimumY = -tableView.adjustedContentInset.top
    let maximumY = max(
      minimumY,
      tableView.contentSize.height - tableView.bounds.height + tableView.adjustedContentInset.bottom
    )
    let targetY = min(max(rect.minY - position.relativeY, minimumY), maximumY)
    tableView.setContentOffset(CGPoint(x: position.contentOffsetX, y: targetY), animated: false)
  }

  private func updateMemberLoadStatus() {
    guard showTeamMembers else {
      tableView.tableFooterView = UIView()
      return
    }
    if isLoadingMembers {
      let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44))
      let indicator = UIActivityIndicatorView(style: .medium)
      indicator.color = memberLoadStatusTintColor
      indicator.center = CGPoint(x: footer.bounds.midX, y: footer.bounds.midY)
      indicator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
      indicator.startAnimating()
      footer.addSubview(indicator)
      tableView.tableFooterView = footer
    } else if let error = memberLoadError {
      let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 52))
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
      tableView.tableFooterView = footer
    } else {
      tableView.tableFooterView = UIView()
    }
  }

  @objc private func retryMemberLoad() {
    loadData()
  }

  open func numberOfSections(in tableView: UITableView) -> Int {
    2
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return isShowAtAll && !isSearching ? 1 : 0
    }
    return visibleMembers.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    UITableViewCell()
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 0 {
      if let block = selectedBlock {
        block(indexPath.row, nil)
      }
      dismiss(animated: true, completion: nil)
      return
    }
    guard visibleMembers.indices.contains(indexPath.row) else {
      return
    }
    if let block = selectedBlock {
      block(indexPath.row, visibleMembers[indexPath.row])
    }
    dismiss(animated: true, completion: nil)
  }

  func btnEvent(button: UIButton) {
    dismiss(animated: true, completion: nil)
  }
}
