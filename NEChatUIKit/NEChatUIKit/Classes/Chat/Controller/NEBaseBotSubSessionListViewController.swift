// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NEBaseUIKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseBotSubSessionListViewController: NEChatBaseViewController,
  UITableViewDataSource, UITableViewDelegate, BotSubSessionListViewModelDelegate, UITextFieldDelegate {
  private enum EmptyState {
    case none
    case noTopic
    case noSearchResult
    case loadFailed
  }

  private let titleSideButtonWidth: CGFloat = 34
  private let titleButtonSpacing: CGFloat = 0
  private let titleViewHorizontalPadding: CGFloat = 12
  private lazy var titleNameViewModel = P2PChatViewModel(conversationId: conversationId)
  public let viewModel = BotSubSessionListViewModel()
  public let conversationId: String
  public let sessionId: String
  public let sessionName: String
  public let listTopSpacing: CGFloat = 12
  public var tableViewTopAnchor: NSLayoutConstraint?
  private var emptyState: EmptyState = .noTopic
  private var lastCreateActionTime: TimeInterval = 0
  private var lastEnterTopicActionTime: TimeInterval = 0
  private var isLoadingTopics = false
  public var deleteButtonBackgroundColor: UIColor = NEConstant.hexRGB(0xA8ABB6)
  public var renameButtonBackgroundColor: UIColor = NEConstant.hexRGB(0x337EFF)
  open var pageBackgroundColor: UIColor {
    .white
  }

  open var listItemBackgroundColor: UIColor {
    .white
  }

  open var showsListItemDivider: Bool {
    false
  }

  open var listItemDividerColor: UIColor {
    UIColor(hexString: "#D8D8D8")
  }

  open var defaultEmptyImageName: String {
    "emptyView"
  }

  open var searchEmptyImageName: String {
    defaultEmptyImageName
  }

  open var emptyActionTitleColor: UIColor {
    .white
  }

  open var emptyActionBackgroundColor: UIColor {
    .ne_normalTheme
  }

  open var searchHighlightColor: UIColor {
    .ne_normalTheme
  }

  public lazy var emptyActionButton: UIButton = {
    let button = UIButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = emptyActionBackgroundColor
    button.layer.cornerRadius = 16
    button.titleLabel?.font = .systemFont(ofSize: 14)
    button.setTitleColor(emptyActionTitleColor, for: .normal)
    button.accessibilityIdentifier = "id.emptyAction"
    button.addTarget(self, action: #selector(handleEmptyActionButtonTap), for: .touchUpInside)
    button.isHidden = true
    return button
  }()

  public lazy var createTopicButton: UIButton = {
    let button = UIButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(UIImage.ne_imageNamed(name: "add_black")?.withRenderingMode(.alwaysOriginal), for: .normal)
    button.contentHorizontalAlignment = .center
    button.contentVerticalAlignment = .center
    button.accessibilityIdentifier = "id.createTopic"
    button.addTarget(self, action: #selector(showCreateAlert), for: .touchUpInside)
    return button
  }()

  public lazy var searchTextField: SearchTextField = {
    let textField = NESingleLineSearchTextField()
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.delegate = self
    textField.placeholder = chatLocalizable("bot_sub_session_search_hint")
    textField.font = .systemFont(ofSize: 14)
    textField.textColor = .ne_darkText
    textField.backgroundColor = UIColor(hexString: "#F2F4F5")
    textField.layer.cornerRadius = 8
    textField.clearButtonMode = .always
    textField.returnKeyType = .search
    textField.leftView = UIImageView(image: coreLoader.loadImage("textField_search_icon"))
    textField.leftViewMode = .always
    textField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
    textField.accessibilityIdentifier = "id.search"
    if let clearButton = textField.value(forKey: "_clearButton") as? UIButton {
      clearButton.accessibilityIdentifier = "id.clear"
    }
    return textField
  }()

  public lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    tableView.dataSource = self
    tableView.delegate = self
    tableView.rowHeight = 68
    tableView.tableFooterView = UIView()
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0
    }
    return tableView
  }()

  public init(conversationId: String, sessionId: String, sessionName: String) {
    self.conversationId = conversationId
    self.sessionId = sessionId
    self.sessionName = sessionName
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    tableViewTopAnchor?.constant = listTopSpacing
    viewModel.refreshListStateIfNeeded()
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    title = displaySessionName()
    navigationView.moreButton.isHidden = false
    navigationView.setMoreButtonImage(coreLoader.loadImage("three_point"))
    navigationView.setMoreButtonWidth(titleSideButtonWidth)
    navigationView.moreButton.removeTarget(nil, action: nil, for: .touchUpInside)
    navigationView.addMoreButtonTarget(target: self, selector: #selector(openSettingPage))
    viewModel.delegate = self
    setupUI()
    loadSessionTitle()
    refreshData()
  }

  override open func toSetting() {
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    alert.addAction(UIAlertAction(title: commonLocalizable("add"), style: .default) { [weak self] _ in
      self?.showCreateAlert()
    })
    alert.addAction(UIAlertAction(title: commonLocalizable("cancel"), style: .cancel))
    present(alert, animated: true)
  }

  open func setupUI() {
    view.backgroundColor = pageBackgroundColor
    navigationView.titleBarView.addSubview(createTopicButton)
    navigationView.navTitle.numberOfLines = 1
    navigationView.navTitle.lineBreakMode = .byTruncatingTail
    NSLayoutConstraint.activate([
      createTopicButton.widthAnchor.constraint(equalToConstant: titleSideButtonWidth),
      createTopicButton.heightAnchor.constraint(equalToConstant: 32),
      createTopicButton.rightAnchor.constraint(equalTo: navigationView.moreButton.leftAnchor, constant: -titleButtonSpacing),
      createTopicButton.centerYAnchor.constraint(equalTo: navigationView.moreButton.centerYAnchor),
      navigationView.navTitle.widthAnchor.constraint(lessThanOrEqualToConstant: titleMaxWidth()),
    ])

    view.addSubview(searchTextField)
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      searchTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant + 8),
      searchTextField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
      searchTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
      searchTextField.heightAnchor.constraint(equalToConstant: 40),
    ])
    tableViewTopAnchor = tableView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: listTopSpacing)
    tableViewTopAnchor?.isActive = true
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    tableView.backgroundColor = pageBackgroundColor
    emptyView.backgroundColor = pageBackgroundColor
    emptyView.setText(chatLocalizable("bot_sub_session_empty"))
    let retryTap = UITapGestureRecognizer(target: self, action: #selector(handleEmptyViewTap))
    emptyView.addGestureRecognizer(retryTap)
    emptyView.isUserInteractionEnabled = true
    emptyView.addSubview(emptyActionButton)
    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.topAnchor.constraint(equalTo: tableView.topAnchor),
      emptyView.leftAnchor.constraint(equalTo: tableView.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: tableView.rightAnchor),
      emptyView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),

      emptyActionButton.topAnchor.constraint(equalTo: emptyView.emptyImageView.bottomAnchor, constant: 40),
      emptyActionButton.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
      emptyActionButton.widthAnchor.constraint(equalToConstant: 96),
      emptyActionButton.heightAnchor.constraint(equalToConstant: 32),
    ])
  }

  open func refreshData() {
    emptyState = .none
    isLoadingTopics = true
    viewModel.loadData(conversationId: conversationId, sessionId: sessionId) { [weak self] error in
      guard let self else {
        return
      }
      self.isLoadingTopics = false
      if let err = error {
        self.emptyState = .loadFailed
        self.emptyView.setText(chatLocalizable("bot_sub_session_load_failed"))
        self.updateEmptyActionButton()
        self.emptyView.isHidden = false
      } else {
        self.updateEmptyState()
      }
    }
  }

  open func onBotSubSessionListReload() {
    updateEmptyState()
    tableView.reloadData()
  }

  open func numberOfSections(in tableView: UITableView) -> Int {
    1
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.displayTopicList.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let reuseId = "bot.sub.session.cell"
    let cell = tableView.dequeueReusableCell(withIdentifier: reuseId) as? BotSubSessionListCell ??
      BotSubSessionListCell(style: .default, reuseIdentifier: reuseId)
    guard let item = viewModel.item(at: indexPath.row) else {
      return cell
    }
    cell.configure(item: item,
                   sessionName: sessionName,
                   keyword: viewModel.keyword,
                   highlightColor: searchHighlightColor)
    cell.applyStyle(backgroundColor: listItemBackgroundColor,
                    showsDivider: showsListItemDivider,
                    dividerColor: listItemDividerColor)
    return cell
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard indexPath.row < viewModel.displayTopicList.count else {
      return
    }
    let now = Date().timeIntervalSince1970
    guard now - lastEnterTopicActionTime >= 0.5 else {
      return
    }
    lastEnterTopicActionTime = now
    let topic = viewModel.displayTopicList[indexPath.row]
    enterTopic(topic)
  }

  open func tableView(_ tableView: UITableView,
                      didHighlightRowAt indexPath: IndexPath) {
    searchTextField.resignFirstResponder()
  }

  open func tableView(_ tableView: UITableView,
                      trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    guard indexPath.row < viewModel.displayTopicList.count else {
      return nil
    }

    let topic = viewModel.displayTopicList[indexPath.row]
    let deleteAction = UIContextualAction(style: .normal,
                                          title: chatLocalizable("operation_delete")) { [weak self] _, _, completion in
      self?.showDeleteAlert(topic: topic)
      completion(true)
    }
    deleteAction.backgroundColor = deleteButtonBackgroundColor

    let renameAction = UIContextualAction(style: .normal,
                                          title: chatLocalizable("bot_sub_session_rename_action")) { [weak self] _, _, completion in
      self?.showRenameAlert(topic: topic)
      completion(true)
    }
    renameAction.backgroundColor = renameButtonBackgroundColor

    let config = UISwipeActionsConfiguration(actions: [deleteAction, renameAction])
    config.performsFirstActionWithFullSwipe = false
    return config
  }

  open func showDeleteAlert(topic: V2NIMTopic) {
    let topicName = topicDisplayName(topic)
    let controller = BotSubSessionDeleteDialogController(title: chatLocalizable("bot_sub_session_delete_title"), message: String(format: chatLocalizable("bot_sub_session_delete_topic"), topicName), confirmButtonBackgroundColor: renameButtonBackgroundColor)
    controller.onDelete = { [weak self, weak controller] in
      controller?.dismiss(animated: false)
      self?.viewModel.removeTopic(topic: topic) { error in
        if error != nil {
          self?.showToast(chatLocalizable("bot_sub_session_delete_failed"))
        }
      }
    }
    present(controller, animated: false)
  }

  open func showRenameAlert(topic: V2NIMTopic) {
    let controller = BotSubSessionRenameDialogController(name: topicDisplayName(topic), saveButtonBackgroundColor: renameButtonBackgroundColor)
    controller.onSave = { [weak self, weak controller] name in
      if name.isEmpty {
        controller?.showToast(chatLocalizable("bot_sub_session_input_name"))
        return
      }
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        controller?.showToast(commonLocalizable("network_error"))
        return
      }
      self?.viewModel.updateTopicName(topic: topic, topicName: name) { _, error in
        if error != nil {
          controller?.showToast(chatLocalizable("bot_sub_session_rename_failed"))
        } else {
          controller?.dismiss(animated: false)
        }
      }
    }
    present(controller, animated: false)
  }

  open func showCreateAlert() {
    let now = Date().timeIntervalSince1970
    guard now - lastCreateActionTime >= 0.5 else {
      return
    }
    lastCreateActionTime = now
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(chatLocalizable("bot_sub_session_offline_create"))
      return
    }
    enterTopic(nil)
  }

  open func searchTextChanged() {
    viewModel.updateKeyword(searchTextField.text ?? "")
  }

  open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    viewModel.updateKeyword(textField.text ?? "")
    textField.resignFirstResponder()
    return true
  }

  open func enterTopic(_ topic: V2NIMTopic?) {}

  open func openSettingPage() {
    guard let controller = getUserSettingViewController() else {
      return
    }
    controller.fromBotSubSession = true
    navigationController?.pushViewController(controller, animated: true)
  }

  open func getUserSettingViewController() -> NEBaseUserSettingViewController? {
    nil
  }

  private func displaySessionName() -> String {
    let name = titleNameViewModel.getShowName(sessionId)
    return name.isEmpty ? sessionId : name
  }

  private func loadSessionTitle() {
    titleNameViewModel.loadShowName([sessionId]) { [weak self] in
      guard let self = self else {
        return
      }
      DispatchQueue.main.async {
        self.title = self.displaySessionName()
      }
    }
  }

  private func titleMaxWidth() -> CGFloat {
    let rightButtonArea = titleSideButtonWidth * 2 + titleButtonSpacing + navigationView.leftMargin + titleViewHorizontalPadding
    let leftButtonArea = max(navigationView.backButtonWidthAnchor?.constant ?? 34, titleSideButtonWidth) + navigationView.leftMargin
    return NEConstant.screenWidth - max(leftButtonArea, rightButtonArea) * 2
  }

  private func topicDisplayName(_ topic: V2NIMTopic) -> String {
    viewModel.topicDisplayName(topic)
  }

  private func updateEmptyState() {
    if isLoadingTopics {
      emptyView.isHidden = true
      emptyActionButton.isHidden = true
      return
    }
    if viewModel.displayTopicList.isEmpty {
      if viewModel.keyword.isEmpty {
        emptyState = .noTopic
        emptyView.setEmptyImage(name: defaultEmptyImageName)
        emptyView.setText(chatLocalizable("bot_sub_session_empty"))
      } else {
        emptyState = .noSearchResult
        emptyView.setEmptyImage(name: searchEmptyImageName)
        emptyView.setText(chatLocalizable("bot_sub_session_search_empty"))
      }
      updateEmptyActionButton()
      emptyView.isHidden = false
    } else {
      emptyState = .none
      emptyView.isHidden = true
      emptyActionButton.isHidden = true
    }
  }

  @objc private func handleEmptyViewTap() {
    if emptyState == .loadFailed {
      refreshData()
    }
  }

  @objc private func handleEmptyActionButtonTap() {
    switch emptyState {
    case .noTopic:
      showCreateAlert()
    case .loadFailed:
      refreshData()
    default:
      break
    }
  }

  private func updateEmptyActionButton() {
    switch emptyState {
    case .noTopic:
      emptyActionButton.setTitle(chatLocalizable("bot_sub_session_create_conversation"), for: .normal)
      emptyActionButton.isHidden = false
    case .loadFailed:
      emptyActionButton.setTitle(chatLocalizable("bot_sub_session_retry"), for: .normal)
      emptyActionButton.isHidden = false
    default:
      emptyActionButton.isHidden = true
    }
  }
}

@objcMembers
open class BotSubSessionListCell: UITableViewCell {
  private var timeWidth: NSLayoutConstraint?
  private let iconContainerView = UIView()
  private let iconImageView = UIImageView()
  private let titleLabel = UILabel()
  private let summaryLabel = UILabel()
  private let timeLabel = UILabel()
  private let unreadDot = UIView()
  private let dividerLine = UIView()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  open func setupUI() {
    selectionStyle = .none
    backgroundColor = .white

    iconContainerView.translatesAutoresizingMaskIntoConstraints = false
    iconContainerView.clipsToBounds = false

    iconImageView.translatesAutoresizingMaskIntoConstraints = false
    iconImageView.image = UIImage.ne_imageNamed(name: "bot_sub_session_icon")
    iconImageView.contentMode = .scaleAspectFit

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
    titleLabel.textColor = .ne_darkText
    titleLabel.numberOfLines = 1

    summaryLabel.translatesAutoresizingMaskIntoConstraints = false
    summaryLabel.font = .systemFont(ofSize: 14)
    summaryLabel.textColor = .ne_greyText
    summaryLabel.numberOfLines = 1

    timeLabel.translatesAutoresizingMaskIntoConstraints = false
    timeLabel.font = .systemFont(ofSize: 12)
    timeLabel.textColor = .lightGray
    timeLabel.textAlignment = .right

    unreadDot.translatesAutoresizingMaskIntoConstraints = false
    unreadDot.backgroundColor = .systemRed
    unreadDot.layer.cornerRadius = 4

    dividerLine.translatesAutoresizingMaskIntoConstraints = false
    dividerLine.isHidden = true

    let textStack = UIStackView(arrangedSubviews: [titleLabel, summaryLabel])
    textStack.translatesAutoresizingMaskIntoConstraints = false
    textStack.axis = .vertical
    textStack.spacing = 6

    contentView.addSubview(iconContainerView)
    iconContainerView.addSubview(iconImageView)
    iconContainerView.addSubview(unreadDot)
    contentView.addSubview(textStack)
    contentView.addSubview(timeLabel)
    contentView.addSubview(dividerLine)

    timeWidth = timeLabel.widthAnchor.constraint(equalToConstant: 0)
    timeWidth?.isActive = true

    NSLayoutConstraint.activate([
      iconContainerView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      iconContainerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      iconContainerView.widthAnchor.constraint(equalToConstant: 42),
      iconContainerView.heightAnchor.constraint(equalToConstant: 42),

      iconImageView.leftAnchor.constraint(equalTo: iconContainerView.leftAnchor),
      iconImageView.topAnchor.constraint(equalTo: iconContainerView.topAnchor),
      iconImageView.widthAnchor.constraint(equalToConstant: 42),
      iconImageView.heightAnchor.constraint(equalToConstant: 42),

      textStack.leftAnchor.constraint(equalTo: iconContainerView.rightAnchor, constant: 12),
      textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      textStack.rightAnchor.constraint(equalTo: timeLabel.leftAnchor, constant: -12),

      timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 17),
      timeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),

      unreadDot.centerXAnchor.constraint(equalTo: iconContainerView.rightAnchor, constant: -6),
      unreadDot.centerYAnchor.constraint(equalTo: iconContainerView.topAnchor, constant: 6),
      unreadDot.widthAnchor.constraint(equalToConstant: 8),
      unreadDot.heightAnchor.constraint(equalToConstant: 8),

      dividerLine.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 70),
      dividerLine.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      dividerLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      dividerLine.heightAnchor.constraint(equalToConstant: 0.5),
    ])
  }

  open func applyStyle(backgroundColor: UIColor, showsDivider: Bool, dividerColor: UIColor) {
    self.backgroundColor = backgroundColor
    contentView.backgroundColor = backgroundColor
    dividerLine.backgroundColor = dividerColor
    dividerLine.isHidden = !showsDivider
  }

  open func configure(item: BotSubSessionItem,
                      sessionName: String,
                      keyword: String = "",
                      highlightColor: UIColor = .ne_normalTheme) {
    let topic = item.topic
    let title: String
    title = topic.topicName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    titleLabel.attributedText = highlightedTitle(title,
                                                 keyword: keyword,
                                                 highlightColor: highlightColor)
    let summary = item.summary ?? ""
    summaryLabel.text = summary
    summaryLabel.isHidden = summary.isEmpty
    timeLabel.text = String.stringFromTimeInterval(time: TimeInterval(item.updateTime))
    if let text = timeLabel.text {
      let maxSize = CGSize(width: UIScreen.main.bounds.width, height: 0)
      let attributes = [NSAttributedString.Key.font: timeLabel.font]
      let labelSize = NSString(string: text).boundingRect(with: maxSize, attributes: attributes as [NSAttributedString.Key: Any], context: nil)
      timeWidth?.constant = labelSize.width + 1
    }
    unreadDot.isHidden = !item.hasUnread
  }

  private func highlightedTitle(_ title: String,
                                keyword: String,
                                highlightColor: UIColor) -> NSAttributedString {
    let attributes: [NSAttributedString.Key: Any] = [
      .foregroundColor: UIColor.ne_darkText,
      .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
    ]
    let attributed = NSMutableAttributedString(string: title, attributes: attributes)
    let key = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !key.isEmpty else {
      return attributed
    }
    let range = (title as NSString).range(of: key, options: [.caseInsensitive])
    if range.location != NSNotFound {
      attributed.addAttribute(.foregroundColor, value: highlightColor, range: range)
      attributed.addAttribute(.backgroundColor, value: UIColor.clear, range: range)
    }
    return attributed
  }
}

@objcMembers
open class BotSubSessionActionSheetController: UIViewController, UIGestureRecognizerDelegate {
  public let topicTitle: String
  public var onRename: (() -> Void)?
  public var onDelete: (() -> Void)?

  private let sheetView = UIView()
  private let titleLabel = UILabel()
  private let renameButton = UIButton(type: .custom)
  private let deleteButton = UIButton(type: .custom)
  private let cancelButton = UIButton(type: .custom)

  public init(title: String) {
    topicTitle = title
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .overFullScreen
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  open func setupUI() {
    view.backgroundColor = UIColor(white: 0, alpha: 0.4)
    let tap = UITapGestureRecognizer(target: self, action: #selector(cancelAction))
    tap.delegate = self
    view.addGestureRecognizer(tap)

    sheetView.translatesAutoresizingMaskIntoConstraints = false
    sheetView.backgroundColor = .white
    sheetView.layer.cornerRadius = 28
    sheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    sheetView.clipsToBounds = true
    view.addSubview(sheetView)

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.text = topicTitle
    titleLabel.textAlignment = .center
    titleLabel.font = .systemFont(ofSize: 14)
    titleLabel.textColor = .ne_greyText
    titleLabel.numberOfLines = 1

    configure(button: renameButton,
              title: chatLocalizable("bot_sub_session_rename_action"),
              color: .ne_darkText,
              action: #selector(renameAction))
    configure(button: deleteButton,
              title: chatLocalizable("operation_delete"),
              color: UIColor(hexString: "#FC596A"),
              action: #selector(deleteAction))
    configure(button: cancelButton,
              title: commonLocalizable("cancel"),
              color: .ne_darkText,
              action: #selector(cancelAction))

    let divider1 = divider()
    let divider2 = divider()
    let gap = UIView()
    gap.translatesAutoresizingMaskIntoConstraints = false
    gap.backgroundColor = UIColor(hexString: "#F2F4F5")

    for item in [titleLabel, divider1, renameButton, divider2, deleteButton, gap, cancelButton] {
      sheetView.addSubview(item)
    }

    NSLayoutConstraint.activate([
      sheetView.leftAnchor.constraint(equalTo: view.leftAnchor),
      sheetView.rightAnchor.constraint(equalTo: view.rightAnchor),
      sheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      titleLabel.topAnchor.constraint(equalTo: sheetView.topAnchor),
      titleLabel.leftAnchor.constraint(equalTo: sheetView.leftAnchor, constant: 24),
      titleLabel.rightAnchor.constraint(equalTo: sheetView.rightAnchor, constant: -24),
      titleLabel.heightAnchor.constraint(equalToConstant: 56),

      divider1.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
      divider1.leftAnchor.constraint(equalTo: sheetView.leftAnchor),
      divider1.rightAnchor.constraint(equalTo: sheetView.rightAnchor),
      divider1.heightAnchor.constraint(equalToConstant: 1),

      renameButton.topAnchor.constraint(equalTo: divider1.bottomAnchor),
      renameButton.leftAnchor.constraint(equalTo: sheetView.leftAnchor),
      renameButton.rightAnchor.constraint(equalTo: sheetView.rightAnchor),
      renameButton.heightAnchor.constraint(equalToConstant: 56),

      divider2.topAnchor.constraint(equalTo: renameButton.bottomAnchor),
      divider2.leftAnchor.constraint(equalTo: sheetView.leftAnchor),
      divider2.rightAnchor.constraint(equalTo: sheetView.rightAnchor),
      divider2.heightAnchor.constraint(equalToConstant: 1),

      deleteButton.topAnchor.constraint(equalTo: divider2.bottomAnchor),
      deleteButton.leftAnchor.constraint(equalTo: sheetView.leftAnchor),
      deleteButton.rightAnchor.constraint(equalTo: sheetView.rightAnchor),
      deleteButton.heightAnchor.constraint(equalToConstant: 56),

      gap.topAnchor.constraint(equalTo: deleteButton.bottomAnchor),
      gap.leftAnchor.constraint(equalTo: sheetView.leftAnchor),
      gap.rightAnchor.constraint(equalTo: sheetView.rightAnchor),
      gap.heightAnchor.constraint(equalToConstant: 10),

      cancelButton.topAnchor.constraint(equalTo: gap.bottomAnchor),
      cancelButton.leftAnchor.constraint(equalTo: sheetView.leftAnchor),
      cancelButton.rightAnchor.constraint(equalTo: sheetView.rightAnchor),
      cancelButton.heightAnchor.constraint(equalToConstant: 56),
      cancelButton.bottomAnchor.constraint(equalTo: sheetView.safeAreaLayoutGuide.bottomAnchor),
    ])
  }

  private func configure(button: UIButton, title: String, color: UIColor, action: Selector) {
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(title, for: .normal)
    button.setTitleColor(color, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 16)
    button.addTarget(self, action: action, for: .touchUpInside)
  }

  private func divider() -> UIView {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor(hexString: "#F2F4F5")
    return view
  }

  @objc private func renameAction() {
    onRename?()
  }

  @objc private func deleteAction() {
    onDelete?()
  }

  @objc private func cancelAction() {
    dismiss(animated: false)
  }

  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                shouldReceive touch: UITouch) -> Bool {
    guard let touchedView = touch.view else {
      return true
    }
    return !touchedView.isDescendant(of: sheetView)
  }
}

@objcMembers
open class BotSubSessionRenameDialogController: UIViewController, UITextFieldDelegate {
  public let initialName: String
  public let saveButtonBackgroundColor: UIColor
  public var onSave: ((String) -> Void)?

  private let contentView = UIView()
  private let nameField = NESingleLineTextField()

  public init(name: String, saveButtonBackgroundColor: UIColor = NEConstant.hexRGB(0x337EFF)) {
    initialName = name
    self.saveButtonBackgroundColor = saveButtonBackgroundColor
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .overFullScreen
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  override open func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    nameField.becomeFirstResponder()
  }

  open func setupUI() {
    view.backgroundColor = UIColor(white: 0, alpha: 0.4)

    contentView.translatesAutoresizingMaskIntoConstraints = false
    contentView.backgroundColor = .white
    contentView.layer.cornerRadius = 16
    contentView.clipsToBounds = true
    view.addSubview(contentView)

    let titleLabel = UILabel()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.text = chatLocalizable("bot_sub_session_rename_conversation")
    titleLabel.textAlignment = .center
    titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
    titleLabel.textColor = .ne_darkText

    nameField.translatesAutoresizingMaskIntoConstraints = false
    nameField.text = initialName
    nameField.delegate = self
    nameField.returnKeyType = .done
    nameField.clearButtonMode = .whileEditing
    nameField.font = .systemFont(ofSize: 16)
    nameField.textColor = .ne_darkText
    nameField.layer.cornerRadius = 8
    nameField.layer.borderWidth = 1
    nameField.layer.borderColor = UIColor(hexString: "#337EFF").cgColor
    nameField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
    nameField.leftViewMode = .always
    nameField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
    nameField.rightViewMode = .unlessEditing

    let cancelButton = UIButton(type: .custom)
    configureDialogButton(
      cancelButton,
      title: commonLocalizable("cancel"),
      titleColor: .ne_darkText,
      backgroundColor: UIColor(hexString: "#F2F4F5"),
      action: #selector(cancelAction)
    )

    let saveButton = UIButton(type: .custom)
    configureDialogButton(
      saveButton,
      title: chatLocalizable("bot_sub_session_save"),
      titleColor: .white,
      backgroundColor: saveButtonBackgroundColor,
      action: #selector(saveAction)
    )

    for item in [titleLabel, nameField, cancelButton, saveButton] {
      contentView.addSubview(item)
    }

    NSLayoutConstraint.activate([
      contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
      contentView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),

      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 24),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -24),

      nameField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
      nameField.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 24),
      nameField.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -24),
      nameField.heightAnchor.constraint(equalToConstant: 48),

      cancelButton.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 16),
      cancelButton.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 24),
      cancelButton.heightAnchor.constraint(equalToConstant: 42),

      saveButton.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 16),
      saveButton.leftAnchor.constraint(equalTo: cancelButton.rightAnchor, constant: 24),
      saveButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -24),
      saveButton.widthAnchor.constraint(equalTo: cancelButton.widthAnchor),
      saveButton.heightAnchor.constraint(equalToConstant: 42),
      saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
    ])
  }

  private func configureDialogButton(_ button: UIButton,
                                     title: String,
                                     titleColor: UIColor,
                                     backgroundColor: UIColor,
                                     action: Selector) {
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(title, for: .normal)
    button.setTitleColor(titleColor, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 16)
    button.backgroundColor = backgroundColor
    button.layer.cornerRadius = 8
    button.addTarget(self, action: action, for: .touchUpInside)
  }

  @objc private func cancelAction() {
    dismiss(animated: false)
  }

  public func showToast(_ message: String) {
    view.neMakeToast(message, position: .center)
  }

  @objc private func saveAction() {
    let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    onSave?(name)
  }

  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    saveAction()
    return true
  }

  public func textField(_ textField: UITextField,
                        shouldChangeCharactersIn range: NSRange,
                        replacementString string: String) -> Bool {
    let current = textField.text ?? ""
    guard let textRange = Range(range, in: current) else {
      return true
    }
    let next = current.replacingCharacters(in: textRange, with: string)
    return next.count <= 20
  }
}

@objcMembers
open class BotSubSessionDeleteDialogController: UIViewController {
  public var onDelete: (() -> Void)?
  public let dialogTitle: String
  public let dialogMessage: String
  public let confirmButtonBackgroundColor: UIColor

  private let contentView = UIView()

  public init(title: String, message: String, confirmButtonBackgroundColor: UIColor) {
    dialogTitle = title
    dialogMessage = message
    self.confirmButtonBackgroundColor = confirmButtonBackgroundColor
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .overFullScreen
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  open func setupUI() {
    view.backgroundColor = UIColor(white: 0, alpha: 0.4)

    contentView.translatesAutoresizingMaskIntoConstraints = false
    contentView.backgroundColor = .white
    contentView.layer.cornerRadius = 16
    contentView.clipsToBounds = true
    view.addSubview(contentView)

    let titleLabel = UILabel()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.text = dialogTitle
    titleLabel.textAlignment = .center
    titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
    titleLabel.textColor = .ne_darkText

    let messageLabel = UILabel()
    messageLabel.translatesAutoresizingMaskIntoConstraints = false
    messageLabel.text = dialogMessage
    messageLabel.textAlignment = .center
    messageLabel.font = .systemFont(ofSize: 16)
    messageLabel.textColor = .ne_greyText
    messageLabel.numberOfLines = 0

    let cancelButton = UIButton(type: .custom)
    configureDialogButton(
      cancelButton,
      title: commonLocalizable("cancel"),
      titleColor: .ne_darkText,
      backgroundColor: UIColor(hexString: "#F2F4F5"),
      action: #selector(cancelAction)
    )

    let deleteButton = UIButton(type: .custom)
    configureDialogButton(
      deleteButton,
      title: chatLocalizable("operation_delete"),
      titleColor: .white,
      backgroundColor: confirmButtonBackgroundColor,
      action: #selector(deleteAction)
    )

    for item in [titleLabel, messageLabel, cancelButton, deleteButton] {
      contentView.addSubview(item)
    }

    NSLayoutConstraint.activate([
      contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
      contentView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),

      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 24),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -24),

      messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
      messageLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 24),
      messageLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -24),

      cancelButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16),
      cancelButton.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 24),
      cancelButton.heightAnchor.constraint(equalToConstant: 48),

      deleteButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16),
      deleteButton.leftAnchor.constraint(equalTo: cancelButton.rightAnchor, constant: 24),
      deleteButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -24),
      deleteButton.widthAnchor.constraint(equalTo: cancelButton.widthAnchor),
      deleteButton.heightAnchor.constraint(equalToConstant: 48),
      deleteButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
    ])
  }

  private func configureDialogButton(_ button: UIButton,
                                     title: String,
                                     titleColor: UIColor,
                                     backgroundColor: UIColor,
                                     action: Selector) {
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(title, for: .normal)
    button.setTitleColor(titleColor, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 16)
    button.backgroundColor = backgroundColor
    button.layer.cornerRadius = 8
    button.addTarget(self, action: action, for: .touchUpInside)
  }

  @objc private func cancelAction() {
    dismiss(animated: false)
  }

  @objc private func deleteAction() {
    onDelete?()
  }
}
