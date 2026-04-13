// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonUIKit
import NECoreKit
import NIMSDK
import UIKit

// MARK: - UIView 扩展：弹窗回调（iOS 13 target-action 替代 addAction）

private var kAlertCancelAction = "kAlertCancelAction"
private var kAlertConfirmAction = "kAlertConfirmAction"

extension UIView {
  /// 弹窗取消回调
  var alertCancelAction: (() -> Void)? {
    get { objc_getAssociatedObject(self, &kAlertCancelAction) as? () -> Void }
    set { objc_setAssociatedObject(self, &kAlertCancelAction, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
  }

  /// 弹窗确认回调
  var alertConfirmAction: (() -> Void)? {
    get { objc_getAssociatedObject(self, &kAlertConfirmAction) as? () -> Void }
    set { objc_setAssociatedObject(self, &kAlertConfirmAction, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
  }

  @objc func handleAlertCancel() { alertCancelAction?() }
  @objc func handleAlertConfirm() { alertConfirmAction?() }
}

@objcMembers
open class NEBaseAIRobotDetailController: NEContactBaseViewController, UITableViewDelegate, UITableViewDataSource {
  public var viewModel: AIRobotDetailViewModel

  // MARK: - 顶部 header（头像 + 名称 + 箭头）

  public lazy var headerView: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.backgroundColor = .white
    return v
  }()

  public lazy var avatarView: NEUserHeaderView = {
    let v = NEUserHeaderView(frame: .zero)
    v.translatesAutoresizingMaskIntoConstraints = false
    v.layer.cornerRadius = avatarCornerRadius()
    v.clipsToBounds = true
    v.titleLabel.font = .systemFont(ofSize: 17)
    v.titleLabel.textColor = .white
    return v
  }()

  public lazy var nameLabel: UILabel = {
    let l = UILabel()
    l.translatesAutoresizingMaskIntoConstraints = false
    l.font = .systemFont(ofSize: 16)
    l.textColor = .ne_darkText
    return l
  }()

  public lazy var headerArrow: UIImageView = {
    let iv = UIImageView(image: coreLoader.loadImage("arrow_right"))
    iv.translatesAutoresizingMaskIntoConstraints = false
    iv.contentMode = .scaleAspectFit
    return iv
  }()

  // MARK: - 操作列表

  public lazy var tableView: UITableView = {
    let tv = UITableView(frame: .zero, style: .plain)
    tv.translatesAutoresizingMaskIntoConstraints = false
    tv.backgroundColor = .clear
    tv.separatorStyle = .none
    tv.delegate = self
    tv.dataSource = self
    tv.estimatedRowHeight = 0
    tv.estimatedSectionHeaderHeight = 0
    tv.estimatedSectionFooterHeight = 0
    tv.isScrollEnabled = false
    if #available(iOS 15.0, *) { tv.sectionHeaderTopPadding = 0 }
    return tv
  }()

  // MARK: - 聊天 + 删除区域容器

  public lazy var chatSeparatorBlock: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.backgroundColor = pageBackgroundColor()
    return v
  }()

  /// 整体白色容器，包含聊天行、内部分隔线、删除行
  public lazy var chatRowView: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.backgroundColor = .white
    return v
  }()

  public lazy var chatLabel: UILabel = {
    let l = UILabel()
    l.translatesAutoresizingMaskIntoConstraints = false
    l.text = localizable("ai_robot_chat")
    l.font = chatLabelFont()
    l.textColor = chatTextColor()
    l.textAlignment = .center
    return l
  }()

  /// 聊天行与删除行之间的分隔线
  public lazy var chatDeleteSeparator: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.backgroundColor = .ne_greyLine
    return v
  }()

  // MARK: - 删除按钮

  public lazy var deleteButton: UIButton = {
    let btn = UIButton(type: .custom)
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.setTitle(localizable("ai_robot_delete"), for: .normal)
    btn.setTitleColor(.ne_redText, for: .normal)
    btn.titleLabel?.font = deleteLabelFont()
    btn.addTarget(self, action: #selector(didTapDelete), for: .touchUpInside)
    return btn
  }()

  /// 操作行 titles（section 0 only，不含聊天/删除）
  public var operationTitles: [String] = []

  // MARK: - Init

  public init(bot: V2NIMUserAIBot) {
    viewModel = AIRobotDetailViewModel(bot: bot)
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - 生命周期

  override open func viewDidLoad() {
    super.viewDidLoad()
    title = localizable("ai_robot_detail_title")
    navigationView.moreButton.isHidden = true
    operationTitles = [
      localizable("ai_robot_view_config"),
      localizable("ai_robot_refresh_token"),
    ]
    setupDetailUI()
    configHeader()
  }

  // MARK: - UI

  open func setupDetailUI() {
    view.backgroundColor = pageBackgroundColor()

    // ── Header ──
    view.addSubview(headerView)
    NSLayoutConstraint.activate([
      headerView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant + headerTopMargin()),
      headerView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: cardHorizontalMargin()),
      headerView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -cardHorizontalMargin()),
      headerView.heightAnchor.constraint(equalToConstant: headerHeight()),
    ])
    setupHeaderStyle()

    headerView.addSubview(avatarView)
    NSLayoutConstraint.activate([
      avatarView.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 16),
      avatarView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
      avatarView.widthAnchor.constraint(equalToConstant: avatarSize()),
      avatarView.heightAnchor.constraint(equalToConstant: avatarSize()),
    ])

    headerView.addSubview(headerArrow)
    NSLayoutConstraint.activate([
      headerArrow.rightAnchor.constraint(equalTo: headerView.rightAnchor, constant: -16),
      headerArrow.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
      headerArrow.widthAnchor.constraint(equalToConstant: 16),
      headerArrow.heightAnchor.constraint(equalToConstant: 16),
    ])

    headerView.addSubview(nameLabel)
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: avatarView.rightAnchor, constant: 12),
      nameLabel.rightAnchor.constraint(equalTo: headerArrow.leftAnchor, constant: -8),
      nameLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
    ])

    let headerTap = UITapGestureRecognizer(target: self, action: #selector(didTapHeader))
    headerView.addGestureRecognizer(headerTap)

    // ── 操作列表（section 0 card）──
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: sectionSpacing()),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: cardHorizontalMargin()),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -cardHorizontalMargin()),
      tableView.heightAnchor.constraint(equalToConstant: CGFloat(operationTitles.count) * rowHeight()),
    ])
    setupTableStyle()
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AIRobotDetailCell")

    // ── 6pt 灰色分隔块 ──
    view.addSubview(chatSeparatorBlock)
    NSLayoutConstraint.activate([
      chatSeparatorBlock.topAnchor.constraint(equalTo: tableView.bottomAnchor),
      chatSeparatorBlock.leftAnchor.constraint(equalTo: view.leftAnchor),
      chatSeparatorBlock.rightAnchor.constraint(equalTo: view.rightAnchor),
      chatSeparatorBlock.heightAnchor.constraint(equalToConstant: chatSeparatorHeight()),
    ])

    // ── 聊天 + 删除整体容器 ──
    view.addSubview(chatRowView)
    NSLayoutConstraint.activate([
      chatRowView.topAnchor.constraint(equalTo: chatSeparatorBlock.bottomAnchor),
      chatRowView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: cardHorizontalMargin()),
      chatRowView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -cardHorizontalMargin()),
      chatRowView.heightAnchor.constraint(equalToConstant: chatRowHeight() + deleteSeparatorHeight() + deleteRowHeight()),
    ])
    setupChatRowStyle()

    // 聊天标签（点击区域：容器顶部 chatRowHeight() 高度）
    let chatTapArea = UIView()
    chatTapArea.translatesAutoresizingMaskIntoConstraints = false
    chatTapArea.backgroundColor = .clear
    let chatTap = UITapGestureRecognizer(target: self, action: #selector(didTapChat))
    chatTapArea.addGestureRecognizer(chatTap)
    chatRowView.addSubview(chatTapArea)
    NSLayoutConstraint.activate([
      chatTapArea.topAnchor.constraint(equalTo: chatRowView.topAnchor),
      chatTapArea.leftAnchor.constraint(equalTo: chatRowView.leftAnchor),
      chatTapArea.rightAnchor.constraint(equalTo: chatRowView.rightAnchor),
      chatTapArea.heightAnchor.constraint(equalToConstant: chatRowHeight()),
    ])

    chatRowView.addSubview(chatLabel)
    NSLayoutConstraint.activate([
      chatLabel.centerXAnchor.constraint(equalTo: chatRowView.centerXAnchor),
      chatLabel.centerYAnchor.constraint(equalTo: chatTapArea.centerYAnchor),
    ])

    // 内部分隔线
    chatRowView.addSubview(chatDeleteSeparator)
    NSLayoutConstraint.activate([
      chatDeleteSeparator.topAnchor.constraint(equalTo: chatRowView.topAnchor, constant: chatRowHeight()),
      chatDeleteSeparator.leftAnchor.constraint(equalTo: chatRowView.leftAnchor),
      chatDeleteSeparator.rightAnchor.constraint(equalTo: chatRowView.rightAnchor),
      chatDeleteSeparator.heightAnchor.constraint(equalToConstant: 0.5),
    ])

    // 删除按钮（全宽，点击整行均可触发）
    chatRowView.addSubview(deleteButton)
    NSLayoutConstraint.activate([
      deleteButton.leftAnchor.constraint(equalTo: chatRowView.leftAnchor),
      deleteButton.rightAnchor.constraint(equalTo: chatRowView.rightAnchor),
      deleteButton.topAnchor.constraint(equalTo: chatRowView.topAnchor, constant: chatRowHeight() + deleteSeparatorHeight()),
      deleteButton.heightAnchor.constraint(equalToConstant: deleteRowHeight()),
    ])
  }

  open func configHeader() {
    guard let bot = viewModel.bot else { return }
    let name = bot.name ?? bot.accid
    let shortName = NEFriendUserCache.getShortName(name)
    avatarView.configHeadData(headUrl: bot.icon, name: shortName, uid: bot.accid)
    nameLabel.text = name
  }

  // MARK: - Customization points（子类 override）

  open func pageBackgroundColor() -> UIColor { .ne_lightBackgroundColor }
  open func cardHorizontalMargin() -> CGFloat { 20 }
  open func headerTopMargin() -> CGFloat { 0 }
  /// headerView 总高度 = 头像行 + 0.5 分割线 + 昵称行
  open func headerHeight() -> CGFloat { avatarRowHeight() + 0.5 + nicknameRowHeight() }
  /// 头像行高度
  open func avatarRowHeight() -> CGFloat { 74 }
  /// 昵称行高度
  open func nicknameRowHeight() -> CGFloat { 50 }
  open func avatarSize() -> CGFloat { 42 }
  open func avatarCornerRadius() -> CGFloat { 21 }
  open func sectionSpacing() -> CGFloat { 12 }
  open func rowHeight() -> CGFloat { 48 }
  open func chatSeparatorHeight() -> CGFloat { 12 }
  open func chatRowHeight() -> CGFloat { 50 }
  /// 聊天行内部：分隔线到删除文字顶部的距离
  open func deleteSeparatorHeight() -> CGFloat { 0 }
  /// 删除按钮行自身高度
  open func deleteRowHeight() -> CGFloat { 50 }
  open func chatTextColor() -> UIColor { .ne_normalTheme }
  open func chatLabelFont() -> UIFont { .systemFont(ofSize: 16) }
  open func deleteLabelFont() -> UIFont { .systemFont(ofSize: 16, weight: .medium) }
  open func confirmButtonColor() -> UIColor { .normalContactThemeColor }

  open func setupHeaderStyle() {
    // Normal: 圆角8
    headerView.layer.cornerRadius = 8
    headerView.clipsToBounds = true
  }

  open func setupTableStyle() {
    // Normal: 圆角8
    tableView.layer.cornerRadius = 8
    tableView.clipsToBounds = true
    tableView.backgroundColor = .white
  }

  open func setupChatRowStyle() {
    // Normal: 圆角8
    chatRowView.layer.cornerRadius = 8
    chatRowView.clipsToBounds = true
  }

  // MARK: - UITableViewDataSource / Delegate

  open func numberOfSections(in tableView: UITableView) -> Int { 1 }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    operationTitles.count
  }

  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "AIRobotDetailCell", for: indexPath)
    cell.selectionStyle = .none
    cell.backgroundColor = .white
    cell.textLabel?.text = operationTitles[indexPath.row]
    cell.textLabel?.font = .systemFont(ofSize: 16)
    cell.textLabel?.textColor = .ne_darkText
    // 使用系统 accessoryType，与群设置 cell 保持一致（Normal 显示，Fun 子类可 override 隐藏）
    cell.accessoryType = .disclosureIndicator
    cell.accessoryView = nil
    return cell
  }

  open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { rowHeight() }

  open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    let isLast = indexPath.row == operationTitles.count - 1
    if !isLast {
      let sep = UIView(frame: CGRect(x: 16, y: rowHeight() - 0.5, width: tableView.bounds.width - 16, height: 0.5))
      sep.backgroundColor = .ne_greyLine
      cell.addSubview(sep)
    }
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch indexPath.row {
    case 0: didTapViewConfig()
    case 1: didTapRefreshToken()
    default: break
    }
  }

  // MARK: - Actions

  open func didTapHeader() { didTapEdit() }

  open func didTapEdit() {
    guard let bot = viewModel.bot else { return }
    Router.shared.use(ContactCreateAIRobotRouter,
                      parameters: ["nav": navigationController as Any,
                                   "bot": bot,
                                   "animated": true,
                                   "onEditSaved": { [weak self] (updatedBot: V2NIMUserAIBot) in
                                     self?.viewModel.bot = updatedBot
                                     self?.configHeader()
                                   }],
                      closure: nil)
  }

  open func didTapViewConfig() {
    // 单纯查看配置串，不刷新 token，直接使用当前 bot 数据跳转
    guard let bot = viewModel.bot else { return }
    Router.shared.use(ContactAIRobotConfigRouter,
                      parameters: ["nav": navigationController as Any,
                                   "bot": bot,
                                   "animated": true],
                      closure: nil)
  }

  open func didTapRefreshToken() { showRefreshTokenConfirmAlert() }

  /// 刷新 Token 二次确认弹窗
  open func showRefreshTokenConfirmAlert() {
    showConfirmAlert(
      tag: 9901,
      title: localizable("ai_robot_refresh_token_title"),
      desc: localizable("ai_robot_refresh_token_desc"),
      confirmTitle: commonLocalizable("sure"),
      confirmColor: confirmButtonColor(),
      onConfirm: { [weak self] in self?.performRefreshToken() }
    )
  }

  open func confirmRefreshToken() {
    removeAlert(tag: 9901)
    performRefreshToken()
  }

  open func performRefreshToken() {
    // 网络检查
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }
    view.isUserInteractionEnabled = false
    viewModel.refreshToken { [weak self] token, error in
      DispatchQueue.main.async {
        guard let self = self else { return }
        self.view.isUserInteractionEnabled = true
        if let error = error {
          // 非网络问题：提示「刷新失败，请重试」，Token 不变更
          self.showToast(localizable("ai_robot_token_refresh_failed"))
          return
        }
        // 刷新成功：token 已变更，重新拉取最新 bot 数据更新缓存
        if let accid = self.viewModel.bot?.accid {
          NEAIRobotManager.shared.loadAll()
          self.viewModel.bot?.token = token
        }
        self.showToast(localizable("ai_robot_token_refresh_success"))
      }
    }
  }

  open func didTapChat() {
    guard let accid = viewModel.bot?.accid else { return }
    guard let conversationId = V2NIMConversationIdUtil.p2pConversationId(accid) else { return }
    guard let nav = navigationController else { return }

    // 跳转到聊天页，同时将当前 Detail 页从导航栈中移除
    // 这样用户在聊天页点击返回时，会直接回到会话列表，而不是机器人详情页
    Router.shared.use(PushP2pChatVCRouter,
                      parameters: ["nav": nav,
                                   "conversationId": conversationId as Any,
                                   "animated": true],
                      closure: nil)
    // push 完成后，从导航栈中移除自身（Detail 页），保留栈底的会话列表
    DispatchQueue.main.async {
      var vcs = nav.viewControllers
      vcs.removeAll(where: { $0 === self })
      nav.setViewControllers(vcs, animated: false)
    }
  }

  open func didTapDelete() { showDeleteConfirmAlert() }

  /// 删除机器人二次确认弹窗
  open func showDeleteConfirmAlert() {
    showConfirmAlert(
      tag: 9911,
      title: localizable("ai_robot_delete_confirm_title"),
      desc: localizable("ai_robot_delete_confirm_desc"),
      confirmTitle: localizable("delete"),
      confirmColor: .ne_redText,
      onConfirm: { [weak self] in self?.performDelete() }
    )
  }

  open func performDelete() {
    // 网络检查
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }
    view.isUserInteractionEnabled = false
    let botAccid = viewModel.bot?.accid ?? ""
    viewModel.deleteRobot { [weak self] error in
      DispatchQueue.main.async {
        guard let self = self else { return }
        self.view.isUserInteractionEnabled = true
        if let error = error {
          self.showToast(robotErrorMessage(error))
          return
        }
        // 删除成功，从 Manager 缓存中移除
        NEAIRobotManager.shared.remove(accid: botAccid)
        self.navigationController?.popViewController(animated: true)
      }
    }
  }

  // MARK: - 通用弹窗工具

  /// 弹出二次确认弹窗（270×140，圆角14）
  open func showConfirmAlert(tag: Int, title: String, desc: String,
                             confirmTitle: String, confirmColor: UIColor,
                             onConfirm: @escaping () -> Void) {
    let overlay = UIView(frame: UIScreen.main.bounds)
    overlay.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    overlay.tag = tag

    let alertView = UIView()
    alertView.translatesAutoresizingMaskIntoConstraints = false
    alertView.backgroundColor = .white
    alertView.layer.cornerRadius = 14
    alertView.clipsToBounds = true
    overlay.addSubview(alertView)

    NSLayoutConstraint.activate([
      alertView.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
      alertView.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
      alertView.widthAnchor.constraint(equalToConstant: 270),
      alertView.heightAnchor.constraint(equalToConstant: 140),
    ])

    let titleLabel = UILabel()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.text = title
    titleLabel.font = UIFont(name: "PingFangSC-Regular", size: 17) ?? .systemFont(ofSize: 17)
    titleLabel.textColor = .black
    titleLabel.textAlignment = .center
    alertView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: alertView.topAnchor, constant: 19),
      titleLabel.leftAnchor.constraint(equalTo: alertView.leftAnchor, constant: 16),
      titleLabel.rightAnchor.constraint(equalTo: alertView.rightAnchor, constant: -16),
      titleLabel.heightAnchor.constraint(equalToConstant: 22),
    ])

    let descLabel = UILabel()
    descLabel.translatesAutoresizingMaskIntoConstraints = false
    descLabel.text = desc
    descLabel.font = UIFont(name: "PingFangSC-Regular", size: 13) ?? .systemFont(ofSize: 13)
    descLabel.textColor = .ne_darkText
    descLabel.textAlignment = .center
    descLabel.numberOfLines = 0
    alertView.addSubview(descLabel)
    NSLayoutConstraint.activate([
      descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
      descLabel.leftAnchor.constraint(equalTo: alertView.leftAnchor, constant: 16),
      descLabel.rightAnchor.constraint(equalTo: alertView.rightAnchor, constant: -16),
    ])

    let hLine = UIView()
    hLine.translatesAutoresizingMaskIntoConstraints = false
    hLine.backgroundColor = UIColor(red: 0, green: 0, blue: 80 / 255.0, alpha: 0.05)
    alertView.addSubview(hLine)
    NSLayoutConstraint.activate([
      hLine.leftAnchor.constraint(equalTo: alertView.leftAnchor),
      hLine.rightAnchor.constraint(equalTo: alertView.rightAnchor),
      hLine.bottomAnchor.constraint(equalTo: alertView.bottomAnchor, constant: -44),
      hLine.heightAnchor.constraint(equalToConstant: 0.5),
    ])

    let cancelBtn = UIButton(type: .custom)
    cancelBtn.translatesAutoresizingMaskIntoConstraints = false
    cancelBtn.setTitle(commonLocalizable("cancel"), for: .normal)
    cancelBtn.setTitleColor(.ne_greyText, for: .normal)
    cancelBtn.titleLabel?.font = UIFont(name: "PingFangSC-Regular", size: 17) ?? .systemFont(ofSize: 17)
    alertView.addSubview(cancelBtn)
    NSLayoutConstraint.activate([
      cancelBtn.leftAnchor.constraint(equalTo: alertView.leftAnchor),
      cancelBtn.bottomAnchor.constraint(equalTo: alertView.bottomAnchor),
      cancelBtn.widthAnchor.constraint(equalTo: alertView.widthAnchor, multiplier: 0.5, constant: -0.25),
      cancelBtn.heightAnchor.constraint(equalToConstant: 44),
    ])

    let vLine = UIView()
    vLine.translatesAutoresizingMaskIntoConstraints = false
    vLine.backgroundColor = UIColor(red: 0, green: 0, blue: 80 / 255.0, alpha: 0.05)
    alertView.addSubview(vLine)
    NSLayoutConstraint.activate([
      vLine.leftAnchor.constraint(equalTo: cancelBtn.rightAnchor),
      vLine.bottomAnchor.constraint(equalTo: alertView.bottomAnchor),
      vLine.widthAnchor.constraint(equalToConstant: 0.5),
      vLine.heightAnchor.constraint(equalToConstant: 44),
    ])

    let confirmBtn = UIButton(type: .custom)
    confirmBtn.translatesAutoresizingMaskIntoConstraints = false
    confirmBtn.setTitle(confirmTitle, for: .normal)
    confirmBtn.setTitleColor(confirmColor, for: .normal)
    confirmBtn.titleLabel?.font = UIFont(name: "PingFangSC-Regular", size: 17) ?? .systemFont(ofSize: 17)
    alertView.addSubview(confirmBtn)
    NSLayoutConstraint.activate([
      confirmBtn.rightAnchor.constraint(equalTo: alertView.rightAnchor),
      confirmBtn.bottomAnchor.constraint(equalTo: alertView.bottomAnchor),
      confirmBtn.widthAnchor.constraint(equalTo: alertView.widthAnchor, multiplier: 0.5, constant: -0.25),
      confirmBtn.heightAnchor.constraint(equalToConstant: 44),
    ])

    if let window = UIApplication.shared.keyWindow {
      window.addSubview(overlay)
      overlay.frame = window.bounds
    } else {
      view.addSubview(overlay)
    }

    // 将回调存储在 overlay 上，通过 target-action 转发（iOS 13 兼容）
    overlay.alertCancelAction = { [weak self] in self?.removeAlert(tag: tag) }
    overlay.alertConfirmAction = { [weak self] in
      self?.removeAlert(tag: tag)
      onConfirm()
    }
    cancelBtn.addTarget(overlay, action: #selector(UIView.handleAlertCancel), for: .touchUpInside)
    confirmBtn.addTarget(overlay, action: #selector(UIView.handleAlertConfirm), for: .touchUpInside)
  }

  open func removeAlert(tag: Int) {
    (UIApplication.shared.keyWindow ?? view)?.subviews.first(where: { $0.tag == tag })?.removeFromSuperview()
  }

  // MARK: - Helper

  public func makeArrowView() -> UIImageView {
    let iv = UIImageView(image: coreLoader.loadImage("arrow_right"))
    iv.contentMode = .scaleAspectFit
    iv.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
    return iv
  }
}
