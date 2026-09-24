// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

open class NEConversationGroupSettingController: NEConversationBaseViewController, UITableViewDataSource, UITableViewDelegate, ConversationGroupViewModelDelegate {
  private var group: NEConversationGroupModel
  private let groupViewModel: ConversationGroupViewModel
  private let style: NEConversationGroupUIStyle
  private let tableView = UITableView(frame: .zero, style: .plain)
  private let groupNameCell = SettingActionCell(style: .default, reuseIdentifier: nil)
  private let addConversationCell = SettingActionCell(style: .default, reuseIdentifier: nil)
  private let membersHeader = UIView()
  private let membersTitleLabel = UILabel()
  private lazy var emptyView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    let imageView = UIImageView(image: UIImage.ne_imageNamed(name: style.emptyImageName))
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFit
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = localizable("session_empty")
    label.textColor = style.tertiaryTextColor
    label.font = .systemFont(ofSize: 14)
    label.textAlignment = .center
    view.addSubview(imageView)
    view.addSubview(label)
    NSLayoutConstraint.activate([
      imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
      imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      imageView.widthAnchor.constraint(equalToConstant: 122),
      imageView.heightAnchor.constraint(equalToConstant: 91),
      label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
      label.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
      label.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
    ])
    return view
  }()

  private var conversations = [NEConversationListModel]()
  private var memberOffset: Int64 = 0
  private var memberFinished = false
  private var isLoadingMembers = false
  private var isDeletingGroup = false
  private var didReturnAfterDeletingGroup = false

  init(group: NEConversationGroupModel, viewModel: ConversationGroupViewModel, style: NEConversationGroupUIStyle = .normal) {
    self.group = group
    groupViewModel = viewModel
    self.style = style
    conversations = viewModel.selectedGroup?.groupId == group.groupId ? viewModel.selectedCustomData : []
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    title = localizable("conversation_group_setting_title")
    view.backgroundColor = style.pageBackgroundColor
    navigationView.backgroundColor = style.navigationBackgroundColor
    navigationView.setMoreButtonTitle(localizable("delete"), style.primaryColor)
    navigationView.addMoreButtonTarget(target: self, selector: #selector(deleteGroupAction))
    groupViewModel.delegate = self
    setupTable()
    loadMembers()
  }

  private func setupTable() {
    groupNameCell.configure(
      title: localizable("conversation_group_name"),
      detail: group.name,
      showIcon: false,
      showDisclosure: true,
      style: style
    )
    groupNameCell.isUserInteractionEnabled = true
    groupNameCell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(editGroupNameAction)))

    addConversationCell.configure(
      title: localizable("conversation_group_add_member"),
      detail: nil,
      showIcon: true,
      showDisclosure: false,
      style: style
    )
    addConversationCell.isUserInteractionEnabled = true
    addConversationCell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addConversationAction)))

    membersHeader.translatesAutoresizingMaskIntoConstraints = false
    membersHeader.backgroundColor = style.cardBackgroundColor
    membersTitleLabel.translatesAutoresizingMaskIntoConstraints = false
    membersTitleLabel.text = String(format: localizable("conversation_group_members"), conversations.count)
    membersTitleLabel.font = .systemFont(ofSize: 15)
    membersTitleLabel.textColor = style.secondaryTextColor
    membersHeader.addSubview(membersTitleLabel)

    for item in [groupNameCell, addConversationCell] {
      item.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(item)
    }
    view.addSubview(membersHeader)

    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .clear
    tableView.separatorStyle = .none
    tableView.dataSource = self
    tableView.delegate = self
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0
    }
    tableView.register(SettingActionCell.self, forCellReuseIdentifier: "ActionCell")
    tableView.register(SettingConversationCell.self, forCellReuseIdentifier: "ConversationCell")
    view.addSubview(tableView)
    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      groupNameCell.topAnchor.constraint(equalTo: navigationView.bottomAnchor),
      groupNameCell.leftAnchor.constraint(equalTo: view.leftAnchor),
      groupNameCell.rightAnchor.constraint(equalTo: view.rightAnchor),
      groupNameCell.heightAnchor.constraint(equalToConstant: 52),
      membersHeader.topAnchor.constraint(equalTo: groupNameCell.bottomAnchor, constant: 6),
      membersHeader.leftAnchor.constraint(equalTo: view.leftAnchor),
      membersHeader.rightAnchor.constraint(equalTo: view.rightAnchor),
      membersHeader.heightAnchor.constraint(equalToConstant: 48),
      membersTitleLabel.leftAnchor.constraint(equalTo: membersHeader.leftAnchor, constant: 24),
      membersTitleLabel.bottomAnchor.constraint(equalTo: membersHeader.bottomAnchor, constant: -8),
      addConversationCell.topAnchor.constraint(equalTo: membersHeader.bottomAnchor),
      addConversationCell.leftAnchor.constraint(equalTo: view.leftAnchor),
      addConversationCell.rightAnchor.constraint(equalTo: view.rightAnchor),
      addConversationCell.heightAnchor.constraint(equalToConstant: 52),
      tableView.topAnchor.constraint(equalTo: addConversationCell.bottomAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      emptyView.topAnchor.constraint(equalTo: tableView.topAnchor),
      emptyView.leftAnchor.constraint(equalTo: view.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: view.rightAnchor),
      emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func loadMembers() {
    memberOffset = 0
    memberFinished = false
    conversations.removeAll()
    membersTitleLabel.text = String(format: localizable("conversation_group_members"), conversations.count)
    loadMoreMembers()
  }

  private func loadMoreMembers() {
    guard memberFinished == false, isLoadingMembers == false else {
      return
    }
    isLoadingMembers = true
    groupViewModel.loadGroupConversations(groupId: group.groupId, offset: memberOffset, limit: 100) { [weak self] models, offset, finished, error in
      guard let self = self else {
        return
      }
      self.isLoadingMembers = false
      if let error = error {
        self.showToast(self.groupViewModel.groupErrorMessage(error))
      }
      self.memberOffset = offset
      self.memberFinished = finished
      self.conversations.append(contentsOf: models)
      self.membersTitleLabel.text = String(format: localizable("conversation_group_members"), self.conversations.count)
      self.tableView.reloadData()
      self.refreshEmpty()
    }
  }

  public func numberOfSections(in tableView: UITableView) -> Int { 1 }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    conversations.count
  }

  public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    64
  }

  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationCell", for: indexPath) as! SettingConversationCell
    let conversationIndex = indexPath.row
    guard conversations.indices.contains(conversationIndex) else {
      cell.configure(nil, isLast: true, style: style)
      return cell
    }
    let model = conversations[conversationIndex]
    cell.configure(model, isLast: conversationIndex == conversations.count - 1, style: style)
    cell.removeAction = { [weak self] in
      self?.removeConversation(model)
    }
    return cell
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}

  @objc private func editGroupNameAction() {
    guard checkNetwork() else { return }
    let controller = NEConversationGroupNameSheetController(title: localizable("conversation_group_edit_name"), initialName: group.name, style: style) { [weak self] name in
      self?.updateName(name)
    }
    present(controller, animated: true)
  }

  @objc private func addConversationAction() {
    guard checkNetwork() else { return }
    groupViewModel.loadAllGroupConversationIds(groupId: group.groupId) { [weak self] existing, error in
      guard let self = self else { return }
      if let error = error {
        self.showToast(self.groupViewModel.groupErrorMessage(error))
        return
      }
      let controller = NEConversationGroupAddConversationController(group: self.group, existingIds: existing ?? [], viewModel: self.groupViewModel, style: self.style)
      controller.complete = { [weak self] in self?.loadMembers() }
      controller.partialFailure = { [weak self] in self?.showToast(localizable("conversation_group_add_partial_failed")) }
      self.navigationController?.pushViewController(controller, animated: true)
    }
  }

  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard scrollView.contentOffset.y + scrollView.bounds.height > scrollView.contentSize.height - 80 else {
      return
    }
    loadMoreMembers()
  }

  private func updateName(_ name: String) {
    performNetworkAction { [weak self] in
      guard let self = self else {
        return
      }
      self.groupViewModel.updateGroupName(groupId: self.group.groupId, name: name) { [weak self] error in
        if let error = error {
          self?.showToast(self?.groupViewModel.groupErrorMessage(error) ?? error.localizedDescription)
        } else {
          self?.group.name = name
          self?.dismiss(animated: true)
          self?.groupNameCell.configure(title: localizable("conversation_group_name"), detail: name, showIcon: false, showDisclosure: true, style: self?.style ?? .normal)
        }
      }
    }
  }

  private func removeConversation(_ model: NEConversationListModel) {
    guard let conversationId = model.conversation?.conversationId else {
      return
    }
    performNetworkAction { [weak self] in
      guard let self = self else {
        return
      }
      self.groupViewModel.removeConversations(groupId: self.group.groupId, conversationIds: [conversationId]) { [weak self] results, error in
        if let error = error {
          self?.showToast(self?.groupViewModel.groupErrorMessage(error) ?? error.localizedDescription)
        } else if let failed = results?.first(where: { result in
          guard let error = result.error as V2NIMError? else { return false }
          return error.code != 0 && error.code != 200
        }) {
          self?.showToast(self?.groupViewModel.groupErrorMessage(failed.error.nserror as NSError) ?? failed.error.desc)
        } else {
          if let index = self?.conversations.firstIndex(where: { $0.conversation?.conversationId == conversationId }) {
            self?.conversations.remove(at: index)
          }
          self?.tableView.reloadData()
          self?.membersTitleLabel.text = String(format: localizable("conversation_group_members"), self?.conversations.count ?? 0)
          self?.refreshEmpty()
        }
      }
    }
  }

  @objc private func deleteGroupAction() {
    guard checkNetwork() else {
      return
    }
    showAlert(
      title: localizable("conversation_group_delete_title"),
      message: localizable("conversation_group_delete_message"),
      sureText: localizable("delete"),
      cancelText: localizable("cancel"),
      sureTextColor: style.isFunStyle ? style.primaryColor : style.dangerColor
    ) { [weak self] in
      self?.performNetworkAction {
        guard let self = self else {
          return
        }
        self.isDeletingGroup = true
        self.didReturnAfterDeletingGroup = false
        self.groupViewModel.deleteGroup(groupId: self.group.groupId) { [weak self] error in
          if let error = error {
            self?.isDeletingGroup = false
            self?.showToast(self?.groupViewModel.groupErrorMessage(error) ?? error.localizedDescription)
          } else {
            self?.returnToGroupManagePageIfNeeded()
          }
        }
      }
    }
  }

  private func performNetworkAction(_ action: @escaping () -> Void) {
    guard checkNetwork() else {
      return
    }
    action()
  }

  private func checkNetwork() -> Bool {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return false
    }
    return true
  }

  private func refreshEmpty() {
    emptyView.isHidden = conversations.isEmpty == false
  }

  public func conversationGroupDidReload() {
    let allGroups = groupViewModel.commonGroups + groupViewModel.hiddenGroups
    guard let latestGroup = allGroups.first(where: { $0.groupId == group.groupId }) else {
      if didReturnAfterDeletingGroup {
        return
      }
      if isDeletingGroup {
        returnToGroupManagePageIfNeeded()
        return
      }
      showToast(localizable("conversation_group_not_exist"))
      navigationController?.popViewController(animated: true)
      return
    }
    group = latestGroup
    tableView.reloadData()
  }

  public func conversationGroupSelectionChanged() {}

  private func returnToGroupManagePageIfNeeded() {
    guard didReturnAfterDeletingGroup == false else {
      return
    }
    didReturnAfterDeletingGroup = true
    isDeletingGroup = false

    guard let navigationController = navigationController else {
      return
    }
    if let manageController = navigationController.viewControllers.first(where: {
      $0 is NEConversationGroupManageController
    }) {
      navigationController.popToViewController(manageController, animated: true)
    } else {
      navigationController.popViewController(animated: true)
    }
  }
}

private final class SettingActionCell: UITableViewCell {
  private let iconView = UIImageView()
  private let titleLabel = UILabel()
  private let detailLabel = UILabel()
  private var titleLeftToContent: NSLayoutConstraint?
  private var titleLeftToIcon: NSLayoutConstraint?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    accessoryType = .disclosureIndicator
    for item in [iconView, titleLabel, detailLabel] {
      item.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview(item)
    }
    iconView.contentMode = .scaleAspectFit
    titleLabel.font = .systemFont(ofSize: 16)
    detailLabel.font = .systemFont(ofSize: 15)
    detailLabel.textColor = .ne_lightText
    detailLabel.lineBreakMode = .byTruncatingTail
    titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    detailLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    titleLeftToContent = titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 24)
    titleLeftToIcon = titleLabel.leftAnchor.constraint(equalTo: iconView.rightAnchor, constant: 24)
    NSLayoutConstraint.activate([
      iconView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 24),
      iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      iconView.widthAnchor.constraint(equalToConstant: 36),
      iconView.heightAnchor.constraint(equalToConstant: 36),
      titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      detailLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
      detailLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      titleLabel.rightAnchor.constraint(lessThanOrEqualTo: detailLabel.leftAnchor, constant: -12),
    ])
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func configure(title: String, detail: String?, showIcon: Bool, showDisclosure: Bool, style: NEConversationGroupUIStyle) {
    accessoryType = showDisclosure ? .disclosureIndicator : .none
    titleLabel.text = title
    detailLabel.text = detail
    titleLabel.textColor = style.titleTextColor
    detailLabel.textColor = style.tertiaryTextColor
    iconView.isHidden = showIcon == false
    iconView.image = showIcon ? UIImage.ne_imageNamed(name: style.addImageName) : nil
    titleLeftToContent?.isActive = false
    titleLeftToIcon?.isActive = false
    if showIcon {
      titleLeftToIcon?.isActive = true
    } else {
      titleLeftToContent?.isActive = true
    }
    titleLabel.superview?.backgroundColor = style.cardBackgroundColor
  }
}

private final class SettingConversationCell: UITableViewCell {
  var removeAction: (() -> Void)?
  private let avatar = NEUserHeaderView(frame: .zero)
  private let titleLabel = UILabel()
  private let removeButton = UIButton(type: .custom)
  private let line = UIView()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    contentView.backgroundColor = .white
    for item in [avatar, titleLabel, removeButton, line] {
      item.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview(item)
    }
    titleLabel.font = .systemFont(ofSize: 15)
    titleLabel.textColor = .ne_darkText
    titleLabel.lineBreakMode = .byTruncatingTail
    titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    removeButton.setTitle(localizable("remove"), for: .normal)
    removeButton.setTitleColor(.ne_funTheme, for: .normal)
    removeButton.titleLabel?.font = .systemFont(ofSize: 14)
    removeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    removeButton.layer.cornerRadius = 4
    removeButton.layer.borderWidth = 1
    removeButton.addTarget(self, action: #selector(removeTap), for: .touchUpInside)
    line.backgroundColor = .ne_greyLine
    avatar.clipsToBounds = true
    NSLayoutConstraint.activate([
      avatar.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 24),
      avatar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      avatar.widthAnchor.constraint(equalToConstant: 36),
      avatar.heightAnchor.constraint(equalToConstant: 36),
      removeButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -24),
      removeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      removeButton.widthAnchor.constraint(equalToConstant: 64),
      titleLabel.leftAnchor.constraint(equalTo: avatar.rightAnchor, constant: 10),
      titleLabel.rightAnchor.constraint(equalTo: removeButton.leftAnchor, constant: -30),
      titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      line.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
      line.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      line.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      line.heightAnchor.constraint(equalToConstant: 1),
    ])
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    removeAction = nil
  }

  func configure(_ model: NEConversationListModel?, isLast: Bool, style: NEConversationGroupUIStyle) {
    contentView.backgroundColor = style.cardBackgroundColor
    titleLabel.textColor = style.titleTextColor
    avatar.layer.cornerRadius = style.settingConversationAvatarCornerRadius
    removeButton.setTitleColor(style.primaryColor, for: .normal)
    removeButton.layer.borderColor = style.primaryColor.cgColor
    removeButton.invalidateIntrinsicContentSize()
    line.backgroundColor = style.lineColor
    titleLabel.text = model?.conversation?.name ?? model?.conversation?.conversationId
    avatar.configHeadData(headUrl: model?.conversation?.avatar, name: model?.conversation?.shortName() ?? "", uid: model?.conversation?.conversationId ?? "")
    line.isHidden = isLast
  }

  @objc private func removeTap() {
    removeAction?()
  }
}
