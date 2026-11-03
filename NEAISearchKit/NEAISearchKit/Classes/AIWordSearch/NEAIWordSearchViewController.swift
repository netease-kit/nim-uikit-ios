
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NEBaseUIKit
import UIKit

@objcMembers
open class NEAIWordSearchViewController: UIViewController, NEAIWordSearchViewModelDelegate {
  let viewModel = NEAIWordSearchViewModel()
  var searchText: String?
  public var margin: CGFloat = 16
  public var titleBarBottomLineHeight: CGFloat = 1.0
  public var backButtonWidth: CGFloat = NEAppLanguageUtil.getCurrentLanguage() == .english ? 60 : 33
  public var moreButtonWidth: CGFloat = NEAppLanguageUtil.getCurrentLanguage() == .english ? 100 : 85
  public var themeColor: UIColor = .ne_normalTheme

  // 父视图添加单击手势，点击背景区域 dismiss
  var tap: UITapGestureRecognizer?
  var contentTableViewTopAnchor: NSLayoutConstraint?

  var viewHeight: CGFloat = 0
  private var navTitleMaxWidthConstraint: NSLayoutConstraint?
  public weak var columnDimView: UIView?
  /// 由宿主直接嵌入右列时使用：不经过 presentation，frame 跟随父视图。
  public var isEmbeddedInColumn = false
  public var columnDismissHandler: (() -> Void)?
  private let compactViewHeight: CGFloat = 406
  private let expandedViewHeight: CGFloat = 700

  override open var title: String? {
    get {
      super.title
    }

    set {
      super.title = newValue
      navTitle.text = title
    }
  }

  public init(_ searchText: String?) {
    super.init(nibName: nil, bundle: nil)
    self.searchText = searchText
    setupUI()
    viewModel.delegate = self
    loadData(searchText)
  }

  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  deinit {
    if let tap = tap {
      tap.view?.removeGestureRecognizer(tap)
    }
  }

  override open func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    view.layer.cornerRadius = 8
    view.layer.borderWidth = 0.5
    view.layer.borderColor = UIColor.lightGray.cgColor

    updateNavTitleMaxWidth()
    if isEmbeddedInColumn {
      guard let host = parent?.view else { return }
      if viewHeight == 0 { viewHeight = compactViewHeight }
      let width = embeddedColumnWidth(in: host)
      let height = min(viewHeight, host.bounds.height)
      view.frame = CGRect(x: 0, y: host.bounds.height - height, width: width, height: height)
      columnDimView?.frame = CGRect(x: 0, y: 0, width: width, height: host.bounds.height)
      return
    }
    if viewHeight == 0 {
      viewHeight = compactViewHeight
    }
    if !usesNativeSheetPresentation {
      // 列内 overCurrentContext 在折叠/展开时容器尺寸会变化，frame 需跟随重算。
      let bounds = sheetContainerBounds
      let height = min(viewHeight, bounds.height)
      view.frame = CGRect(x: bounds.minX, y: bounds.maxY - height, width: bounds.width, height: height)
    }
  }

  override open func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if modalPresentationStyle == .overCurrentContext,
       columnDimView == nil,
       let containerView = presentationController?.containerView {
      let dim = UIView(frame: containerView.bounds)
      dim.backgroundColor = UIColor.black.withAlphaComponent(0.4)
      dim.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      containerView.insertSubview(dim, belowSubview: view)
      columnDimView = dim
    }
    guard tap == nil,
          let containerView = presentationController?.containerView else {
      return
    }
    let backgroundTap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
    backgroundTap.cancelsTouchesInView = false
    containerView.addGestureRecognizer(backgroundTap)
    tap = backgroundTap
  }

  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    columnDimView?.removeFromSuperview()
    columnDimView = nil
    if isEmbeddedInColumn {
      NotificationCenter.default.post(name: Notification.Name("NEAdaptiveOverlayDidDismiss"), object: nil)
    }
  }

//  override open func viewWillAppear(_ animated: Bool) {
//    super.viewWillAppear(animated)
//    if let parent = parent as? ChatViewController {
//      parent.isCurrentPage = false
//    }
//  }
//
//  override open func viewWillDisappear(_ animated: Bool) {
//    super.viewWillDisappear(animated)
//    if let parent = parent as? ChatViewController {
//      parent.isCurrentPage = true
//    }
//  }

  /// 展示错误弹窗
  /// - Parameter error: 错误信息
  func showErrorToast(_ error: Error?) {
    if let err = error as? NSError {
      switch err.code {
      case failedOperation:
        showToast(commonLocalizable("parameter_setting_error"))
      case rateLimitExceeded:
        showToast(commonLocalizable("rate_limit_exceeded"))
      case userNotExistCode:
        showToast(commonLocalizable("user_not_exist"))
      case userBannedCode:
        showToast(commonLocalizable("user_banned"))
      case userChatBannedCode:
        showToast(commonLocalizable("user_chat_banned"))
      case noFriendCode:
        showToast(commonLocalizable("friend_not_exist"))
      case messageHitAntispam1, messageHitAntispam2:
        showToast(commonLocalizable("message_hit_antispam"))
      case teamMemberNotExist:
        showToast(commonLocalizable("team_member_not_exist"))
      case teamNormalMemberChatBanned:
        showToast(commonLocalizable("team_normal_member_chat_banned"))
      case teamMemberChatBanned:
        showToast(commonLocalizable("team_member_chat_banned"))
      case notAIAccount:
        showToast(commonLocalizable("not_ai_account"))
      case cannotBlockAIAccount:
        showToast(commonLocalizable("cannot_blocklist_ai_account"))
      case aiMessagesDisabled:
        showToast(commonLocalizable("ai_messages_function_disabled"))
      case aiMessageRequestFailed:
        showToast(commonLocalizable("failed_request_to_the_LLM"))
      default:
        showToast(localizable("request_exception"))
      }
    }
  }

  /// 首次加载数据
  /// - Parameter searchText: 搜索内容
  func loadData(_ searchText: String?) {
    setTitleText(true)
    viewModel.loadData(searchText) { [weak self] error in
      self?.showErrorToast(error)
      self?.tableViewReload(false)
    }
  }

  /// 补充加载数据
  /// - Parameter searchText: 搜索内容
  func loadMoreData(_ searchText: String?) {
    setTitleText()
    inputTextView.resignFirstResponder()
    viewModel.loadData(searchText) { [weak self] error in
      self?.showErrorToast(error)
      self?.tableViewReload(false)
    }
  }

  /// UI 布局
  open func setupUI() {
    configureSheetPresentation()
    title = localizable("ai_word_searching")
    view.backgroundColor = .white

    view.addSubview(titleBarView)
    NSLayoutConstraint.activate([
      titleBarView.topAnchor.constraint(equalTo: view.topAnchor),
      titleBarView.leftAnchor.constraint(equalTo: view.leftAnchor),
      titleBarView.rightAnchor.constraint(equalTo: view.rightAnchor),
      titleBarView.heightAnchor.constraint(equalToConstant: 50),
    ])

    view.addSubview(contentTableView)
    contentTableViewTopAnchor = contentTableView.topAnchor.constraint(equalTo: titleBarBottomLine.bottomAnchor, constant: 0)
    contentTableViewTopAnchor?.isActive = true
    NSLayoutConstraint.activate([
      contentTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    contentTableView.register(NEAIWordSearchTextCell.self, forCellReuseIdentifier: "\(NEAIWordSearchTextCell.self)")
  }

  /// 设置标题
  /// - Parameter isLoading: loading 状态
  func setTitleText(_ isLoading: Bool = true) {
    if isLoading {
      title = localizable("ai_word_searching")
      loadingView.isHidden = false
    } else {
      title = localizable("ai_word_search")
      loadingView.isHidden = true
    }
  }

  /// 取消按钮点击事件
  func cancelButtonAction() {
    if let tap = tap {
      tap.view?.removeGestureRecognizer(tap)
    }
    if let columnDismissHandler {
      columnDismissHandler()
      return
    }
    dismiss(animated: true, completion: nil)
  }

  /// 单击手势点击事件
  /// - Parameter tap: 单击手势
  func tapAction(_ tap: UITapGestureRecognizer) {
    // 判断手势位置位于背景区域
    if !view.bounds.contains(tap.location(in: view)) {
      cancelButtonAction()
    }
  }

  /// 补充信息按钮点击事件
  func moreButtonAction() {
    viewHeight = expandedViewHeight
    if isEmbeddedInColumn, let host = parent?.view {
      UIView.animate(withDuration: 0.25) {
        let width = self.embeddedColumnWidth(in: host)
        let height = min(self.viewHeight, host.bounds.height)
        self.view.frame = CGRect(x: 0, y: host.bounds.height - height,
                                 width: width, height: height)
        self.columnDimView?.frame = CGRect(x: 0, y: 0, width: width, height: host.bounds.height)
        self.view.layoutIfNeeded()
      }
    } else if !updateNativeSheetHeight(expandedViewHeight,
                                       identifier: "com.netease.imuikit.aiSearch.expanded",
                                       animated: true) {
      UIView.animate(withDuration: 0.25) {
        let bounds = self.sheetContainerBounds
        let height = min(self.viewHeight, bounds.height)
        self.view.frame = CGRect(x: bounds.minX, y: bounds.maxY - height, width: bounds.width, height: height)
        self.view.layoutIfNeeded()
      }
    }

    // 移除补充信息按钮，添加输入框
    moreButton.removeFromSuperview()
    view.addSubview(inputBackView)
    NSLayoutConstraint.activate([
      inputBackView.topAnchor.constraint(equalTo: titleBarBottomLine.bottomAnchor, constant: 16),
      inputBackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      inputBackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      inputBackView.heightAnchor.constraint(equalToConstant: 120),
    ])

    contentTableViewTopAnchor?.constant = 16 + 120
  }

  private var sheetContainerBounds: CGRect {
    if let bounds = presentationController?.containerView?.bounds, bounds.width > 0, bounds.height > 0 {
      return bounds
    }
    if let bounds = view.window?.bounds, bounds.width > 0, bounds.height > 0 {
      return bounds
    }
    if let bounds = view.superview?.bounds, bounds.width > 0, bounds.height > 0 {
      return bounds
    }
    return view.bounds
  }

  private func updateNavTitleMaxWidth() {
    guard let constraint = navTitleMaxWidthConstraint else { return }
    let width = max(0, sheetContainerBounds.width - margin * 4 - backButtonWidth - moreButtonWidth - 16)
    if abs(constraint.constant - width) > 0.5 {
      constraint.constant = width
    }
  }

  /// 折叠态聊天 view 可能仍是整窗宽度；此时扣掉宿主窗口右侧的 rail 安全区。
  private func embeddedColumnWidth(in host: UIView) -> CGFloat {
    let windowWidth = host.window?.bounds.width ?? host.bounds.width
    let isFullWindow = host.bounds.width >= windowWidth - 1
    let railInset = isFullWindow ? max(0, host.window?.safeAreaInsets.right ?? 0) : 0
    return max(0, host.bounds.width - railInset)
  }

  private var usesNativeSheetPresentation: Bool {
    if #available(iOS 15.0, *) {
      return modalPresentationStyle == .pageSheet
    }
    return false
  }

  private func configureSheetPresentation() {
    if #available(iOS 15.0, *) {
      modalPresentationStyle = .pageSheet
      _ = updateNativeSheetHeight(compactViewHeight,
                                  identifier: "com.netease.imuikit.aiSearch.compact",
                                  animated: false)
    } else {
      // Prevent iOS 13-14 from adapting `.automatic` to a page sheet while
      // the legacy layout still positions the view with an explicit frame.
      modalPresentationStyle = .overFullScreen
    }
  }

  @discardableResult
  private func updateNativeSheetHeight(_ height: CGFloat,
                                       identifier: String,
                                       animated: Bool) -> Bool {
    if #available(iOS 16.0, *), let sheet = sheetPresentationController {
      let detentIdentifier = UISheetPresentationController.Detent.Identifier(identifier)
      let update = {
        sheet.detents = [
          .custom(identifier: detentIdentifier) { context in
            min(height, context.maximumDetentValue)
          },
        ]
        sheet.selectedDetentIdentifier = detentIdentifier
        sheet.prefersGrabberVisible = false
        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        sheet.preferredCornerRadius = 8
      }

      if animated {
        sheet.animateChanges(update)
      } else {
        update()
      }
      return true
    }

    if #available(iOS 15.0, *), let sheet = sheetPresentationController {
      let isExpanded = height == expandedViewHeight
      let detent: UISheetPresentationController.Detent = isExpanded ? .large() : .medium()
      let detentIdentifier: UISheetPresentationController.Detent.Identifier = isExpanded ? .large : .medium
      let update = {
        sheet.detents = [detent]
        sheet.selectedDetentIdentifier = detentIdentifier
        sheet.prefersGrabberVisible = false
        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        sheet.preferredCornerRadius = 8
      }

      if animated {
        sheet.animateChanges(update)
      } else {
        update()
      }
      return true
    }

    return false
  }

  /// 确认按钮点击事件
  func sureButtonAction() {
    // 校验网络
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    if let text = inputTextView.text, !text.isEmpty {
      loadMoreData(text)
      inputTextView.text = ""
      placeHolderLabel.isHidden = false
      sureButton.isEnabled = false
      clearButton.isHidden = true
    }
  }

  /// 键盘完成按钮点击事件
  func doneButtonAction() {
    inputTextView.resignFirstResponder()
  }

  // MARK: lazy

  /// 取消按钮
  public lazy var cancelButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(localizable("cancel"), for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 16)
    button.setTitleColor(.ne_darkText, for: .normal)
    button.contentHorizontalAlignment = .left
    button.addTarget(self, action: #selector(cancelButtonAction), for: .touchUpInside)
    button.accessibilityIdentifier = "id.cancel"
    return button
  }()

  /// 标题栏 loading 动画
  public lazy var loadingView: NELottieAnimationView = {
    let view = NELottieAnimationView(name: "ne_loading_data", bundle: coreLoader.bundle)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.loopMode = .loop
    view.contentMode = .scaleAspectFill
    view.accessibilityIdentifier = "id.loadingView"
    return view
  }()

  /// 标题
  public lazy var navTitle: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: 17, weight: .semibold)
    label.textAlignment = .center
    label.text = ""
    label.accessibilityIdentifier = "id.title"
    return label
  }()

  /// 补充信息按钮
  public lazy var moreButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(.ne_imageNamed(name: "ai_expand"), for: .normal)
    button.setTitle(localizable("input_more_button"), for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 16)
    button.setTitleColor(themeColor, for: .normal)
    button.accessibilityIdentifier = "id.threePoint"
    button.addTarget(self, action: #selector(moreButtonAction), for: .touchUpInside)
    button.accessibilityIdentifier = "id.moreButton"
    return button
  }()

  /// 标题栏分割线
  public lazy var titleBarBottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor(hexString: "#E9EFF5")
    view.isHidden = false
    return view
  }()

  /// 标题栏视图
  public lazy var titleBarView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    view.addSubview(cancelButton)
    view.addSubview(moreButton)
    view.addSubview(navTitle)
    view.addSubview(loadingView)
    view.addSubview(titleBarBottomLine)

    NSLayoutConstraint.activate([
      cancelButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: margin),
      cancelButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      cancelButton.widthAnchor.constraint(equalToConstant: backButtonWidth),
      cancelButton.heightAnchor.constraint(equalToConstant: 18),
    ])

    NSLayoutConstraint.activate([
      moreButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -margin),
      moreButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      moreButton.widthAnchor.constraint(equalToConstant: moreButtonWidth),
      moreButton.heightAnchor.constraint(equalToConstant: 18),
    ])

    navTitleMaxWidthConstraint = navTitle.widthAnchor.constraint(lessThanOrEqualToConstant: 0)
    NSLayoutConstraint.activate([
      navTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      navTitle.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      navTitleMaxWidthConstraint!, // 16 为补充按钮 icon 宽度
    ])

    loadingView.play()
    NSLayoutConstraint.activate([
      loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      loadingView.widthAnchor.constraint(equalToConstant: 16),
      loadingView.heightAnchor.constraint(equalToConstant: 16),
      loadingView.rightAnchor.constraint(equalTo: navTitle.leftAnchor, constant: -2),
    ])

    NSLayoutConstraint.activate([
      titleBarBottomLine.leftAnchor.constraint(equalTo: view.leftAnchor),
      titleBarBottomLine.rightAnchor.constraint(equalTo: view.rightAnchor),
      titleBarBottomLine.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      titleBarBottomLine.heightAnchor.constraint(equalToConstant: titleBarBottomLineHeight),
    ])

    return view
  }()

  /// 输入框视图
  lazy var inputBackView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor(hexString: "#F5F5F5")
    view.layer.cornerRadius = 4

    view.addSubview(inputTextView)
    view.addSubview(clearButton)
    view.addSubview(sureButton)

    NSLayoutConstraint.activate([
      inputTextView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 12),
      inputTextView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -44),
      inputTextView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
      inputTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
      clearButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -12),
      clearButton.topAnchor.constraint(equalTo: inputTextView.topAnchor, constant: 4),
      clearButton.widthAnchor.constraint(equalToConstant: 24),
      clearButton.heightAnchor.constraint(equalToConstant: 24),
    ])

    NSLayoutConstraint.activate([
      sureButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -12),
      sureButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
      sureButton.widthAnchor.constraint(equalToConstant: 40),
      sureButton.heightAnchor.constraint(equalToConstant: 18),
    ])

    return view
  }()

  /// 输入框占位符
  lazy var placeHolderLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = localizable("input_more_placeholder")
    label.font = .systemFont(ofSize: 16)
    label.textColor = UIColor(hexString: "#AAAAAA")
    return label
  }()

  /// 输入框
  lazy var inputTextView: UITextView = {
    let textView = UITextView()
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.backgroundColor = .clear
    textView.font = .systemFont(ofSize: 16)
    textView.textColor = .ne_darkText
    textView.delegate = self

    textView.addSubview(placeHolderLabel)
    NSLayoutConstraint.activate([
      placeHolderLabel.leftAnchor.constraint(equalTo: textView.leftAnchor, constant: 6),
      placeHolderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 8),
      placeHolderLabel.rightAnchor.constraint(equalTo: textView.rightAnchor, constant: -6),
      placeHolderLabel.heightAnchor.constraint(equalToConstant: 18),
    ])

    let accessoryView = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIWindow.ne_activeKeyWindow?.bounds.width ?? 0, height: 40))
    accessoryView.barStyle = .default

    // 完成按钮
    let accessoryDoneButton = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 20))
    accessoryDoneButton.translatesAutoresizingMaskIntoConstraints = false
    accessoryDoneButton.setTitle(localizable("complete"), for: .normal)
    accessoryDoneButton.setTitleColor(.ne_normalTheme, for: .normal)
    accessoryDoneButton.addTarget(self, action: #selector(doneButtonAction), for: .touchUpInside)

    accessoryView.addSubview(accessoryDoneButton)
    NSLayoutConstraint.activate([
      accessoryDoneButton.rightAnchor.constraint(equalTo: accessoryView.rightAnchor, constant: -12),
      accessoryDoneButton.centerYAnchor.constraint(equalTo: accessoryView.centerYAnchor),
      accessoryDoneButton.widthAnchor.constraint(equalToConstant: 44),
      accessoryDoneButton.heightAnchor.constraint(equalToConstant: 20),
    ])

    textView.inputAccessoryView = accessoryView

    return textView
  }()

  lazy var clearButton: UIButton = {
    let button = UIButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = .clear
    if #available(iOS 13.0, *) {
      let configuration = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
      button.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: configuration), for: .normal)
    } else {
      button.setTitle("×", for: .normal)
      button.setTitleColor(.ne_emptyTitleColor, for: .normal)
      button.titleLabel?.font = .systemFont(ofSize: 16)
    }
    button.tintColor = .ne_emptyTitleColor
    button.accessibilityIdentifier = "id.clear"
    button.addTarget(self, action: #selector(clearText), for: .touchUpInside)
    button.isHidden = true
    return button
  }()

  /// 确认按钮
  lazy var sureButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(localizable("ok"), for: .normal)
    button.setTitleColor(UIColor(hexString: "#2155EE"), for: .normal)
    button.setTitleColor(UIColor(hexString: "#2155EE", 0.5), for: .disabled)
    button.titleLabel?.font = .systemFont(ofSize: 16)
    button.addTarget(self, action: #selector(sureButtonAction), for: .touchUpInside)
    button.accessibilityIdentifier = "id.sureButton"
    button.isEnabled = false
    return button
  }()

  /// 内容列表
  lazy var contentTableView: UITableView = {
    let tableView = UITableView()
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .clear
    tableView.separatorStyle = .none
    tableView.keyboardDismissMode = .onDrag
    tableView.delegate = self
    tableView.dataSource = self

    if #available(iOS 11.0, *) {
      tableView.estimatedRowHeight = 0
      tableView.estimatedSectionHeaderHeight = 0
      tableView.estimatedSectionFooterHeight = 0
    }
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }
    return tableView
  }()
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension NEAIWordSearchViewController: UITableViewDelegate, UITableViewDataSource {
  public func numberOfSections(in tableView: UITableView) -> Int {
    1
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.data.count
  }

  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = viewModel.data[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: "\(NEAIWordSearchTextCell.self)", for: indexPath) as! NEAIWordSearchTextCell
    cell.setModel(model)

    if viewModel.data.count == 1, !moreButton.isHidden {
      cell.showBottomLine(false)
    } else {
      cell.showBottomLine(true)
    }

    return cell
  }

  public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let model = viewModel.data[indexPath.row]
    return model.height + 16 + 20
  }
}

// MARK: - UITextViewDelegate

extension NEAIWordSearchViewController: UITextViewDelegate {
  public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
    placeHolderLabel.isHidden = true
    if textView.text.count <= 0 {
      sureButton.isEnabled = false
    }
    return true
  }

  public func textViewDidChange(_ textView: UITextView) {
    if textView.text.count > 0 {
      placeHolderLabel.isHidden = true
      sureButton.isEnabled = true
    } else {
      placeHolderLabel.isHidden = false
      sureButton.isEnabled = false
    }
    clearButton.isHidden = textView.text.isEmpty
  }

  public func textViewDidEndEditing(_ textView: UITextView) {
    if textView.text.count <= 0 {
      placeHolderLabel.isHidden = false
      sureButton.isEnabled = false
    }
  }

  @objc
  func clearText() {
    inputTextView.text = ""
    textViewDidChange(inputTextView)
  }

  public func tableViewReload(_ isLoading: Bool) {
    setTitleText(isLoading)
    contentTableView.reloadData()
  }
}
