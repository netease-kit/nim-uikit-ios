
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Lottie
import NECommonKit
import NECommonUIKit
import NECoreIM2Kit
import UIKit

@objcMembers
open class NEAIWordSearchViewController: UIViewController, NEAIWordSearchViewModelDelegate {
  let viewModel = NEAIWordSearchViewModel()
  var searchText: String?
  public var margin: CGFloat = 16
  public var titleBarBottomLineHeight: CGFloat = 1.0
  public var backButtonWidth: CGFloat = 33
  public var moreButtonWidth: CGFloat = 85
  public var themeColor: UIColor = .ne_normalTheme

  // 父视图添加单击手势，点击背景区域 dismiss
  var tap: UITapGestureRecognizer?
  var contentTableViewTopAnchor: NSLayoutConstraint?

  var viewHeight: CGFloat = 0

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
      view.superview?.removeGestureRecognizer(tap)
    }
  }

  override open func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    view.layer.cornerRadius = 8
    view.layer.borderWidth = 0.5
    view.layer.borderColor = UIColor.lightGray.cgColor

    if viewHeight == 0 {
      viewHeight = 406
      view.frame = CGRect(x: 0, y: NEConstant.screenHeight - viewHeight, width: NEConstant.screenWidth, height: viewHeight)
    }

    tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
    tap?.cancelsTouchesInView = false
    view.superview?.addGestureRecognizer(tap!)
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
      view.superview?.removeGestureRecognizer(tap)
    }
    view.removeFromSuperview()
    removeFromParent()
    dismiss(animated: true, completion: nil)
  }

  /// 单击手势点击事件
  /// - Parameter tap: 单击手势
  func tapAction(_ tap: UITapGestureRecognizer) {
    // 判断手势位置位于背景区域
    if tap.location(in: view).y < 0 {
      cancelButtonAction()
    }
  }

  /// 补充信息按钮点击事件
  func moreButtonAction() {
    viewHeight = 700
    UIView.animate(withDuration: 0.25) {
      self.view.frame = CGRect(x: 0, y: NEConstant.screenHeight - self.viewHeight, width: NEConstant.screenWidth, height: self.viewHeight)
      self.view.layoutIfNeeded()
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
  public lazy var loadingView: LottieAnimationView = {
    let view = LottieAnimationView(name: "ne_loading_data", bundle: coreLoader.bundle)
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

    NSLayoutConstraint.activate([
      navTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      navTitle.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      navTitle.widthAnchor.constraint(lessThanOrEqualToConstant: NEConstant.screenWidth - margin * 4 - backButtonWidth - moreButtonWidth - 16), // 16 为补充按钮 icon 宽度
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
    view.addSubview(sureButton)

    NSLayoutConstraint.activate([
      inputTextView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 12),
      inputTextView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -12),
      inputTextView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
      inputTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
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
      placeHolderLabel.widthAnchor.constraint(equalToConstant: 150),
      placeHolderLabel.heightAnchor.constraint(equalToConstant: 18),
    ])

    let accessoryView = UIToolbar(frame: CGRect(x: 0, y: 0, width: NEConstant.screenWidth, height: 40))
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
  }

  public func textViewDidEndEditing(_ textView: UITextView) {
    if textView.text.count <= 0 {
      placeHolderLabel.isHidden = false
      sureButton.isEnabled = false
    }
  }

  public func tableViewReload(_ isLoading: Bool) {
    setTitleText(isLoading)
    contentTableView.reloadData()
  }
}
