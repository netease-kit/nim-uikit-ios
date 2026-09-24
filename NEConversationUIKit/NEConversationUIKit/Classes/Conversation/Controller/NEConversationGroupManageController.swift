// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

open class NEConversationGroupManageController: NEConversationBaseViewController, UITableViewDataSource, UITableViewDelegate, ConversationGroupViewModelDelegate {
  private let groupViewModel: ConversationGroupViewModel
  private let style: NEConversationGroupUIStyle
  private let tableView = UITableView(frame: .zero, style: .plain)

  private lazy var createButton: UIButton = {
    let button = UIButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = style.primaryColor
    button.setTitle(localizable("conversation_group_create"), for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
    button.layer.cornerRadius = 8
    button.addTarget(self, action: #selector(createGroupAction), for: .touchUpInside)
    return button
  }()

  init(viewModel: ConversationGroupViewModel, style: NEConversationGroupUIStyle = .normal) {
    groupViewModel = viewModel
    self.style = style
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    title = localizable("conversation_group_title")
    view.backgroundColor = style.pageBackgroundColor
    navigationView.backgroundColor = style.navigationBackgroundColor
    navigationView.moreButton.isHidden = true
    navigationView.moreButton.removeTarget(nil, action: nil, for: .touchUpInside)
    groupViewModel.delegate = self
    setupCreateButton()
    setupTableView()
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    groupViewModel.delegate = self
    tableView.reloadData()
  }

  private func setupTableView() {
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .clear
    tableView.separatorStyle = .none
    tableView.dataSource = self
    tableView.delegate = self
    tableView.isEditing = true
    tableView.allowsSelectionDuringEditing = true
    tableView.register(ManageCell.self, forCellReuseIdentifier: "ManageCell")
    let commonHeader = makeSectionHeader(title: localizable("conversation_group_common"))
    commonHeader.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 42)
    tableView.tableHeaderView = commonHeader
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: navigationView.bottomAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: createButton.topAnchor, constant: -12),
    ])
  }

  private func setupCreateButton() {
    view.addSubview(createButton)
    NSLayoutConstraint.activate([
      createButton.widthAnchor.constraint(equalToConstant: 315),
      createButton.heightAnchor.constraint(equalToConstant: 50),
      createButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
    ])
  }

  public func numberOfSections(in tableView: UITableView) -> Int {
    2
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    section == 0 ? groupViewModel.commonGroups.count : groupViewModel.hiddenGroups.count
  }

  public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    section == 0 ? .leastNormalMagnitude : 42
  }

  public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard section == 1 else {
      return nil
    }
    return makeSectionHeader(title: localizable("conversation_group_hidden"))
  }

  private func makeSectionHeader(title: String) -> UIView {
    let label = UILabel()
    label.text = title
    label.textColor = style.secondaryTextColor
    label.font = .systemFont(ofSize: 13)
    let container = UIView()
    container.addSubview(label)
    label.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      label.leftAnchor.constraint(equalTo: container.leftAnchor, constant: 16),
      label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
    ])
    return container
  }

  public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    54
  }

  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ManageCell", for: indexPath) as! ManageCell
    let group = model(at: indexPath)
    cell.configure(
      group,
      hidden: indexPath.section == 1,
      style: style,
      showsDivider: indexPath.row < tableView.numberOfRows(inSection: indexPath.section) - 1
    )
    cell.leftAction = { [weak self] in
      if indexPath.section == 0 {
        self?.groupViewModel.moveCommonToHidden(group)
      } else {
        self?.groupViewModel.moveHiddenToCommon(group)
      }
    }
    cell.settingAction = { [weak self] in
      guard group.type == .custom else {
        return
      }
      guard let self = self else {
        return
      }
      let controller = NEConversationGroupSettingController(group: group, viewModel: self.groupViewModel, style: self.style)
      self.navigationController?.pushViewController(controller, animated: true)
    }
    return cell
  }

  public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    indexPath.section == 0 && model(at: indexPath).canDrag
  }

  public func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    .none
  }

  public func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
    false
  }

  public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    guard sourceIndexPath.section == 0, destinationIndexPath.section == 0 else {
      tableView.reloadData()
      return
    }
    var groups = groupViewModel.commonGroups
    let item = groups.remove(at: sourceIndexPath.row)
    groups.insert(item, at: max(destinationIndexPath.row, 1))
    groupViewModel.updateCommonOrder(groups)
  }

  private func model(at indexPath: IndexPath) -> NEConversationGroupModel {
    indexPath.section == 0 ? groupViewModel.commonGroups[indexPath.row] : groupViewModel.hiddenGroups[indexPath.row]
  }

  @objc private func createGroupAction() {
    presentCreateGroupSheet()
  }

  private func presentCreateGroupSheet() {
    let controller = NEConversationGroupNameSheetController(
      title: localizable("conversation_group_create"),
      style: style,
      heightRatio: 0.93
    ) { [weak self] name in
      guard let self = self, let sheet = self.presentedViewController else {
        return
      }
      self.performNetworkAction(on: sheet) {
        self.groupViewModel.createGroup(name: name) { [weak self, weak sheet] _, error in
          if let error = error {
            sheet?.showToast(self?.groupViewModel.groupErrorMessage(error) ?? error.localizedDescription)
          } else {
            sheet?.dismiss(animated: true)
          }
        }
      }
    }
    present(controller, animated: true)
  }

  private func performNetworkAction(on controller: UIViewController, _ action: @escaping () -> Void) {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      controller.showToast(commonLocalizable("network_error"))
      return
    }
    action()
  }

  public func conversationGroupDidReload() {
    tableView.reloadData()
  }

  public func conversationGroupSelectionChanged() {
    tableView.reloadData()
  }
}

private final class ManageCell: UITableViewCell {
  var leftAction: (() -> Void)?
  var settingAction: (() -> Void)?
  private let leftButton = UIButton(type: .custom)
  private let titleLabel = UILabel()
  private let settingButton = UIButton(type: .custom)
  private let divider = UIView()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    backgroundColor = .white
    contentView.backgroundColor = .white
    for item in [leftButton, titleLabel, settingButton, divider] {
      item.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview(item)
    }
    titleLabel.font = .systemFont(ofSize: 16)
    titleLabel.textColor = .ne_darkText
    titleLabel.lineBreakMode = .byTruncatingTail
    leftButton.addTarget(self, action: #selector(leftTap), for: .touchUpInside)
    settingButton.addTarget(self, action: #selector(settingTap), for: .touchUpInside)
    NSLayoutConstraint.activate([
      leftButton.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      leftButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      leftButton.widthAnchor.constraint(equalToConstant: 32),
      leftButton.heightAnchor.constraint(equalToConstant: 32),
      titleLabel.leftAnchor.constraint(equalTo: leftButton.rightAnchor, constant: 8),
      titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      settingButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
      settingButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      settingButton.widthAnchor.constraint(equalToConstant: 32),
      settingButton.heightAnchor.constraint(equalToConstant: 32),
      titleLabel.rightAnchor.constraint(lessThanOrEqualTo: settingButton.leftAnchor, constant: -8),
      divider.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
      divider.rightAnchor.constraint(equalTo: rightAnchor),
      divider.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      divider.heightAnchor.constraint(equalToConstant: 0.5),
    ])
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func configure(_ group: NEConversationGroupModel, hidden: Bool, style: NEConversationGroupUIStyle, showsDivider: Bool) {
    titleLabel.text = group.name
    titleLabel.textColor = style.titleTextColor
    divider.backgroundColor = style.lineColor
    divider.isHidden = showsDivider == false
    leftButton.setImage(UIImage.ne_imageNamed(name: hidden ? style.hiddenAddImageName : (group.canHide ? style.deleteImageName : style.disableImageName)), for: .normal)
    leftButton.isEnabled = hidden || group.canHide
    settingButton.setImage(UIImage.ne_imageNamed(name: style.settingImageName), for: .normal)
    settingButton.isHidden = group.type != .custom
  }

  @objc private func leftTap() {
    leftAction?()
  }

  @objc private func settingTap() {
    settingAction?()
  }
}
