
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NEChatUIKit
import NEBaseUIKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseTeamMembersController: NETeamBaseViewController, UITableViewDelegate,
  UITableViewDataSource, TeamMemberCellDelegate, TeamMembersViewModelDelegate {
  /// 群id
  public var teamId: String?
  /// 群成员数据
  public var memberDatas: [NETeamMemberInfoModel]? {
    didSet {
      viewModel.setShowDatas(memberDatas)
    }
  }

  /// 创建者account id
  public var ownerId: String?

  public var isSenior = false

  open var memberLoadStatusTintColor: UIColor { .ne_funTheme }

  public let backView = UIView()

  let viewModel = TeamMembersViewModel()

  private var renderedAccountIds = [String?]()
  private var searchStartPosition: (accountId: String, relativeY: CGFloat, contentOffsetX: CGFloat)?
  private var appliedSearchKeyword = ""

  /// 搜索输入控件
  public lazy var searchTextField: UITextField = {
    let field = NESingleLineTextField()
    field.translatesAutoresizingMaskIntoConstraints = false
    field.placeholder = commonLocalizable("search")
    field.clearButtonMode = .always
    field.textColor = .ne_greyText
    field.font = UIFont.systemFont(ofSize: 14.0)
    field.backgroundColor = UIColor.ne_backcolor
    if let clearButton = field.value(forKey: "_clearButton") as? UIButton {
      clearButton.accessibilityIdentifier = "id.clear"
    }
    field.accessibilityIdentifier = "id.search"
    return field
  }()

  /// 群成员列表视图
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

  /// 搜索背景图
  public lazy var searchIconImageView: UIImageView = {
    let searchIconImageView = UIImageView()
    searchIconImageView.image = coreLoader.loadImage("textField_search_icon")
    searchIconImageView.translatesAutoresizingMaskIntoConstraints = false
    return searchIconImageView
  }()

  public init(teamId: String?) {
    super.init(nibName: nil, bundle: nil)
    self.teamId = teamId
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    addObserver()
    viewModel.delegate = self
    viewModel.teamId = teamId
    navigationView.moreButton.isHidden = true
    emptyView.setEmptyImage(name: "user_empty")
    emptyView.setText(localizable("no_result"))

    weak var weakSelf = self
    if let tid = teamId {
      weakSelf?.viewModel.getTeamInfo(tid) { teamInfo, error in
        weakSelf?.ownerId = teamInfo?.team?.ownerAccountId
        if error != nil {
          if let err = error {
            weakSelf?.showToast(err.localizedDescription)
          }
          weakSelf?.didNeedRefreshUI()
        } else {
          if teamInfo?.team?.isDisscuss() == false {
            weakSelf?.isSenior = true
            weakSelf?.title = chatLocalizable("group_memmber")
          } else {
            weakSelf?.title = localizable("discuss_mebmer")
          }

          // 订阅群成员在线状态
//          if IMKitConfigCenter.shared.enableOnlineStatus {
//            if let members = teamInfo?.users {
//              var subcribeMembers = [NETeamMemberInfoModel]()
//              for model in members {
//                if let account = model.teamMember?.accountId {
//                  if account != IMKitClient.instance.account() {
//                    subcribeMembers.append(model)
//                  }
//                }
//              }
//              weakSelf?.viewModel.subcribeMembers(members) { error in
//                NEALog.infoLog(NEBaseTeamMembersController.className(), desc: "sub cribe members error : \(error?.localizedDescription ?? "")")
//              }
//            }
//          }
          weakSelf?.didNeedRefreshUI()
        }
      }
    }
    setupUI()
    if teamId != nil {
      didNeedRefreshUI()
    }
  }

  /// UI 初始化
  open func setupUI() {
    backView.backgroundColor = .clear
    backView.translatesAutoresizingMaskIntoConstraints = false
    backView.clipsToBounds = true
    backView.layer.cornerRadius = 4.0

    view.addSubview(backView)
    NSLayoutConstraint.activate([
      backView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8.0 + topConstant),
      backView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      backView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      backView.heightAnchor.constraint(equalToConstant: 32),
    ])

    backView.addSubview(searchIconImageView)
    NSLayoutConstraint.activate([
      searchIconImageView.centerYAnchor.constraint(equalTo: backView.centerYAnchor),
      searchIconImageView.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 16.0),
    ])

    backView.addSubview(searchTextField)
    NSLayoutConstraint.activate([
      searchTextField.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 36.0),
      searchTextField.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -16.0),
      searchTextField.topAnchor.constraint(equalTo: backView.topAnchor),
      searchTextField.bottomAnchor.constraint(equalTo: backView.bottomAnchor),
    ])

    view.addSubview(contentTableView)
    NSLayoutConstraint.activate([
      contentTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentTableView.topAnchor.constraint(equalTo: backView.bottomAnchor, constant: 10),
      contentTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    contentTableView.register(NEBaseTeamMemberCell.self, forCellReuseIdentifier: "\(NEBaseTeamMemberCell.self)")

    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.leftAnchor.constraint(equalTo: contentTableView.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: contentTableView.rightAnchor),
      emptyView.topAnchor.constraint(equalTo: contentTableView.topAnchor, constant: 50),
      emptyView.bottomAnchor.constraint(equalTo: contentTableView.bottomAnchor),
    ])
  }

  open func addObserver() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(textChange),
      name: UITextField.textDidChangeNotification,
      object: nil
    )
  }

  open func isOwner(_ userId: String?) -> Bool {
    if isSenior == false {
      return false
    }
    if let uid = userId, let oid = ownerId, uid == oid {
      return true
    }
    return false
  }

  open func textChange() {
    let text = searchTextField.text ?? ""
    let previousKeyword = appliedSearchKeyword
    let normalizedKeyword = text.trimmingCharacters(in: .whitespacesAndNewlines)
    let willSearch = !normalizedKeyword.isEmpty
    if previousKeyword.isEmpty, willSearch {
      searchStartPosition = currentScrollPosition()
    }
    appliedSearchKeyword = normalizedKeyword
    viewModel.searchData(text)
    if normalizedKeyword.isEmpty {
      emptyView.isHidden = true
    }
    didNeedRefreshUI()
    if !willSearch {
      restoreSearchStartPositionIfNeeded()
    } else if previousKeyword != normalizedKeyword {
      scrollSearchResultsToTop()
    }
  }

  open func getRealModel(_ index: Int) -> NETeamMemberInfoModel? {
    if isSearching {
      guard viewModel.searchDatas.indices.contains(index) else { return nil }
      return viewModel.searchDatas[index]
    }
    guard viewModel.datas.indices.contains(index) else { return nil }
    return viewModel.datas[index]
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: UITableViewDelegate, UITableViewDataSource

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if isSearching {
      return viewModel.searchDatas.count
    }
    return viewModel.datas.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(NEBaseTeamMemberCell.self)",
      for: indexPath
    ) as? NEBaseTeamMemberCell {
      if let model = getRealModel(indexPath.row) {
        let isSearching = !(searchTextField.text ?? "")
          .trimmingCharacters(in: .whitespacesAndNewlines)
          .isEmpty
        cell.configure(model, searchResult: isSearching ? viewModel.searchResult(for: model) : nil)
        cell.ownerLabel.isHidden = !isOwner(
          model.teamMember?.accountId ?? model.nimUser?.user?.accountId
        )
      }
      return cell
    }
    return UITableViewCell()
  }

  open func tableView(_ tableView: UITableView,
                      heightForRowAt indexPath: IndexPath) -> CGFloat {
    62.0
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let model = getRealModel(indexPath.row),
          let uid = model.teamMember?.accountId ?? model.nimUser?.user?.accountId,
          !uid.isEmpty else {
      return
    }
    if IMKitClient.instance.isMe(uid) {
      Router.shared.use(
        MeSettingRouter,
        parameters: ["nav": navigationController as Any],
        closure: nil
      )
    } else {
      Router.shared.use(
        ContactUserInfoPageRouter,
        parameters: ["nav": navigationController as Any, "uid": uid],
        closure: nil
      )
    }
  }

  /// 移除群成员
  /// - Parameter model: 成员信息
  /// - Parameter index: 成员索引
  open func didClickRemoveButton(_ model: NETeamMemberInfoModel?, _ index: Int) {
    print("did click remove button")
    weak var weakSelf = self
    showAlert(title: localizable("remove_manager_title"), message: localizable("remove_member_tip")) {
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        weakSelf?.view.neMakeToast(commonLocalizable("network_error"))
        return
      }

      if let tid = weakSelf?.teamId,
         let uid = model?.teamMember?.accountId ?? model?.nimUser?.user?.accountId,
         !uid.isEmpty {
        weakSelf?.viewModel.removeTeamMember(tid, [uid]) { error in
          if let err = error {
            if err.code == noPermissionCode {
              weakSelf?.view.neMakeToast(localizable("no_permission_tip"))
            } else {
              weakSelf?.view.neMakeToast(localizable("remove_failed"))
            }
          } else {
            if let text = weakSelf?.searchTextField.text, !text.isEmpty {
              weakSelf?.viewModel.searchDatas.remove(at: index)
              weakSelf?.viewModel.searchDatas.removeAll(where: { model in
                if model.teamMember?.accountId == uid {
                  return true
                }
                return false
              })
              weakSelf?.viewModel.removeModel([uid])
              weakSelf?.didNeedRefreshUI()
            } else {
              weakSelf?.viewModel.removeModel([uid])
              weakSelf?.didNeedRefreshUI()
            }
          }
        }
      }
    }
  }

  open func didNeedRefreshUI() {
    let visibleCount = isSearching ? viewModel.searchDatas.count : viewModel.datas.count
    emptyView.isHidden = viewModel.isLoadingMembers || viewModel.memberLoadError != nil || visibleCount > 0
    updateMemberLoadStatus()
    reloadPreservingTopMember()
  }

  private var isSearching: Bool {
    !(searchTextField.text ?? "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .isEmpty
  }

  private var displayedMembers: [NETeamMemberInfoModel] {
    isSearching ? viewModel.searchDatas : viewModel.datas
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
    let nextRenderedAccountIds = displayedMembers.map {
      $0.teamMember?.accountId ?? $0.nimUser?.user?.accountId
    }

    UIView.performWithoutAnimation {
      contentTableView.reloadData()
      contentTableView.layoutIfNeeded()
    }
    renderedAccountIds = nextRenderedAccountIds

    guard let anchor,
          let row = displayedMembers.firstIndex(where: {
            ($0.teamMember?.accountId ?? $0.nimUser?.user?.accountId) == anchor.0
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
    guard let row = displayedMembers.firstIndex(where: {
      ($0.teamMember?.accountId ?? $0.nimUser?.user?.accountId) == position.accountId
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
    viewModel.getTeamInfo(teamId) { [weak self] _, error in
      if let error {
        self?.showToast(error.localizedDescription)
      }
      self?.didNeedRefreshUI()
    }
  }

  override open func willMove(toParent parent: UIViewController?) {
    super.willMove(toParent: parent)
//    if IMKitConfigCenter.shared.enableOnlineStatus {
//      if parent == nil {
//        viewModel.unSubcribeMembers(viewModel.datas) { [weak self] error in
//          NEALog.infoLog(NEBaseTeamMembersController.className(), desc: #function + " un sub scribe member error : \(error?.localizedDescription ?? "")")
//        }
//      }
//    }
  }
}
