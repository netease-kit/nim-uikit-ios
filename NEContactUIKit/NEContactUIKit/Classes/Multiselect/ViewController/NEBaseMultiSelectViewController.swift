// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK
import UIKit

/// 转发 - 选择页面 - 基类
@objcMembers
open class NEBaseMultiSelectViewController: NEContactBaseViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource {
  public let viewModel = MultiSelectViewModel()
  public var filterUsers: Set<String>?
  public var limit = 9 // 最大可选数量（多选）
  public var userId: String? // 单聊中对方的userId
  public var selectedArray = [MultiSelectModel]() // 已选列表
  public var recentArray = [MultiSelectModel]() // 最近会话列表
  var tabIndex = 0 // 最近会话 - 0；我的好友 - 1；我的群聊 - 2
  var isMultiSelect = false // 是否处于多选
  var searchText: String? // 搜索文案
  var currentTableView: UITableView? // 当前展示的 tableView

  var selectedContentViewHeight: CGFloat = 59 // 已选区域高度
  var selectedContentViewHeightAnchor: NSLayoutConstraint? // 已选区域 高度约束
  var recentContentViewHeight: CGFloat = 145 // 最近转发区域高度
  var recentContentViewHeightAnchor: NSLayoutConstraint? // 最近会话 高度约束
  public var selectedLineLeftAnchor: NSLayoutConstraint? // 已选 tab 下划线左侧约束

  public var themeColor: UIColor = .ne_normalTheme // 主题颜色
  public var titleText = localizable("select") // 标题文案
  public var sureButtonText = localizable("alert_sure") // 确定按钮文案

  init(filterUsers: Set<String>? = nil) {
    super.init(nibName: nil, bundle: nil)
    self.filterUsers = filterUsers
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  /// 设置背景圆角
  override open func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    view.layer.cornerRadius = 8
    view.layer.borderWidth = 0.2
    view.layer.borderColor = UIColor.lightGray.cgColor
  }

  override open func viewDidLoad() {
    super.viewDidLoad()

    setupUI()
    currentTableView = recentTableView
    loadAllData()
  }

  /// 加载所有数据
  func loadAllData() {
    viewModel.loadAllData(filterUsers) { [weak self] error in
      self?.setEmptyViewText(self?.searchText)

      if let sessions = self?.viewModel.sessions {
        self?.emptyView.isHidden = sessions.count > 0
        self?.currentTableView?.reloadData()
      }

      if let recentSessions = self?.viewModel.loadRecentForward(), !recentSessions.isEmpty {
        self?.recentArray = recentSessions
        self?.recentCollectionView.reloadData()
      } else {
        self?.recentContentView.isHidden = true
        self?.recentContentViewHeightAnchor?.constant = 16
      }
    }
  }

  /// 加载数据（根据下标）
  /// - Parameter index: tab 下标
  func loadData(_ index: Int = 0) {
    viewModel.loadData(index, filterUsers) { [weak self] error in
      self?.viewModel.searchText(self?.searchText ?? "")
      self?.setEmptyViewText(self?.searchText)
      self?.currentTableView?.reloadData()
      self?.emptyView.isHidden = self?.viewModel.sessions.isEmpty == false
    }
  }

  /// 设置标题
  func setupTitle() {
    navigationController?.isNavigationBarHidden = true
    navigationView.isHidden = true

    // 取消按钮
    view.addSubview(cancelButton)
    NSLayoutConstraint.activate([
      cancelButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      cancelButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
      cancelButton.widthAnchor.constraint(equalToConstant: 40),
      cancelButton.heightAnchor.constraint(equalToConstant: 18),
    ])

    // 标题文案
    let titleLabel = UILabel()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.text = titleText
    titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    titleLabel.textAlignment = .center
    titleLabel.textColor = .ne_darkText
    view.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
      titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      titleLabel.heightAnchor.constraint(equalToConstant: 18),
    ])

    // 多选按钮
    view.addSubview(multiSelectButton)
    NSLayoutConstraint.activate([
      multiSelectButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      multiSelectButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
      multiSelectButton.widthAnchor.constraint(equalToConstant: 40),
      multiSelectButton.heightAnchor.constraint(equalToConstant: 18),
    ])

    // 确定按钮
    view.addSubview(sureButton)
    NSLayoutConstraint.activate([
      sureButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      sureButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
      sureButton.widthAnchor.constraint(equalToConstant: 76),
      sureButton.heightAnchor.constraint(equalToConstant: 32),
    ])
  }

  /// 设置 UI 布局
  open func setupUI() {
    // 设置标题
    setupTitle()

    // 搜索
    view.addSubview(searchTextField)
    NSLayoutConstraint.activate([
      searchTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 58),
      searchTextField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      searchTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      searchTextField.heightAnchor.constraint(equalToConstant: 32),
    ])

    // 已选
    view.addSubview(selectedContentView)
    selectedContentViewHeightAnchor = selectedContentView.heightAnchor.constraint(equalToConstant: 0)
    selectedContentViewHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      selectedContentView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor),
      selectedContentView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      selectedContentView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
    ])

    // 最近转发
    view.addSubview(recentContentView)
    recentContentViewHeightAnchor = recentContentView.heightAnchor.constraint(equalToConstant: recentContentViewHeight)
    recentContentViewHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      recentContentView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      recentContentView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      recentContentView.topAnchor.constraint(equalTo: selectedContentView.bottomAnchor),
    ])

    // 会话选择区域
    view.addSubview(sessionContentView)
    NSLayoutConstraint.activate([
      sessionContentView.topAnchor.constraint(equalTo: recentContentView.bottomAnchor),
      sessionContentView.leftAnchor.constraint(equalTo: view.leftAnchor),
      sessionContentView.rightAnchor.constraint(equalTo: view.rightAnchor),
      sessionContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  // MARK: - lazy var

  /// 搜索区域
  public lazy var searchTextField1: FunSearchView = {
    let view = FunSearchView(searchButtonLeftConstant: 16)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backView.backgroundColor = UIColor.ne_backcolor
    view.searchButton.setImage(UIImage.ne_imageNamed(name: "funSearch"), for: .normal)
    view.searchButton.setTitle(commonLocalizable("search"), for: .normal)
    view.searchButton.contentHorizontalAlignment = .left
    return view
  }()

  public lazy var searchTextField: SearchTextField = {
    let textField = SearchTextField()
    let leftImageView = UIImageView(image: UIImage.ne_imageNamed(name: "search"))
    textField.contentMode = .center
    textField.leftView = leftImageView
    textField.leftViewMode = .always
    textField.placeholder = commonLocalizable("search")
    textField.font = UIFont.systemFont(ofSize: 14)
    textField.textColor = UIColor.ne_darkText
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.layer.cornerRadius = 8
    textField.backgroundColor = .ne_lightBackgroundColor
    textField.clearButtonMode = .always
    textField.returnKeyType = .search
    textField.addTarget(self, action: #selector(searchTextFieldChange), for: .editingChanged)

    if let clearButton = textField.value(forKey: "_clearButton") as? UIButton {
      clearButton.accessibilityIdentifier = "id.clear"
    }
    textField.accessibilityIdentifier = "id.search"
    return textField
  }()

  /// 已选区域
  public lazy var selectedContentView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    view.isHidden = true

    view.addSubview(selectedCollectionView)
    NSLayoutConstraint.activate([
      selectedCollectionView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      selectedCollectionView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: -10),
      selectedCollectionView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30),
      selectedCollectionView.heightAnchor.constraint(equalToConstant: 36),
    ])

    // 向右箭头（更多）
    let arrowRight = UIImageView()
    arrowRight.translatesAutoresizingMaskIntoConstraints = false
    arrowRight.image = UIImage.ne_imageNamed(name: "arrowRight")

    view.addSubview(arrowRight)
    NSLayoutConstraint.activate([
      arrowRight.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      arrowRight.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -5),
    ])

    // 分隔线
    let dividerLine = UIView()
    dividerLine.translatesAutoresizingMaskIntoConstraints = false
    dividerLine.backgroundColor = UIColor.ne_backcolor
    view.addSubview(dividerLine)
    NSLayoutConstraint.activate([
      dividerLine.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      dividerLine.leftAnchor.constraint(equalTo: view.leftAnchor, constant: -20),
      dividerLine.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 20),
      dividerLine.heightAnchor.constraint(equalToConstant: 3),
    ])

    let tap = UITapGestureRecognizer(target: self, action: #selector(selectedCollectionViewAction))
    view.addGestureRecognizer(tap)
    return view
  }()

  /// 已选
  public lazy var selectedCollectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    let collectView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
    collectView.translatesAutoresizingMaskIntoConstraints = false
    collectView.backgroundColor = .clear
    collectView.delegate = self
    collectView.dataSource = self
    collectView.allowsMultipleSelection = false
    collectView.contentInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    collectView.accessibilityIdentifier = "id.selected"
    return collectView
  }()

  /// 最近转发区域
  public lazy var recentContentView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear

    // 最近转发文案
    view.addSubview(recentLabel)
    NSLayoutConstraint.activate([
      recentLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
      recentLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
      recentLabel.widthAnchor.constraint(equalToConstant: 50),
      recentLabel.heightAnchor.constraint(equalToConstant: 14),
    ])

    view.addSubview(recentCollectionView)
    NSLayoutConstraint.activate([
      recentCollectionView.topAnchor.constraint(equalTo: recentLabel.bottomAnchor, constant: 12),
      recentCollectionView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: -12),
      recentCollectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
      recentCollectionView.heightAnchor.constraint(equalToConstant: 84),
    ])

    // 分隔线
    let dividerLine = UIView()
    dividerLine.translatesAutoresizingMaskIntoConstraints = false
    dividerLine.backgroundColor = UIColor.ne_backcolor
    view.addSubview(dividerLine)
    NSLayoutConstraint.activate([
      dividerLine.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      dividerLine.leftAnchor.constraint(equalTo: view.leftAnchor, constant: -20),
      dividerLine.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 20),
      dividerLine.heightAnchor.constraint(equalToConstant: 3),
    ])

    return view
  }()

  /// 最近转发文案
  lazy var recentLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = localizable("recent_forward")
    label.font = .systemFont(ofSize: 12)
    label.textColor = UIColor(hexString: "#B3B7BC")
    return label
  }()

  /// 最近转发
  public lazy var recentCollectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    let collectView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
    collectView.translatesAutoresizingMaskIntoConstraints = false
    collectView.backgroundColor = .clear
    collectView.delegate = self
    collectView.dataSource = self
    collectView.allowsMultipleSelection = false
    collectView.contentInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    collectView.accessibilityIdentifier = "id.selected"
    return collectView
  }()

  /// 最近会话
  lazy var recentButton: UIButton = {
    let button = UIButton()
    button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    button.setTitle(localizable("recent_session"), for: .normal)
    button.setTitleColor(UIColor.ne_darkText, for: .normal)
    button.setTitleColor(themeColor, for: .highlighted)
    button.setTitleColor(themeColor, for: .selected)
    button.backgroundColor = .white
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(recentButtonAction), for: .touchUpInside)
    button.accessibilityIdentifier = "id.recentButton"
    button.isSelected = true
    return button
  }()

  /// 我的好友
  lazy var friendButton: UIButton = {
    let button = UIButton()
    button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    button.setTitle(localizable("my_friends"), for: .normal)
    button.setTitleColor(UIColor.ne_darkText, for: .normal)
    button.setTitleColor(themeColor, for: .highlighted)
    button.setTitleColor(themeColor, for: .selected)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = .white
    button.addTarget(self, action: #selector(friendButtonAction), for: .touchUpInside)
    button.accessibilityIdentifier = "id.friendButton"
    return button
  }()

  /// 我的群聊
  lazy var teamButton: UIButton = {
    let button = UIButton()
    button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    button.setTitle(localizable("my_teams"), for: .normal)
    button.setTitleColor(UIColor.ne_darkText, for: .normal)
    button.setTitleColor(themeColor, for: .highlighted)
    button.setTitleColor(themeColor, for: .selected)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = .white
    button.addTarget(self, action: #selector(teamButtonAction), for: .touchUpInside)
    button.accessibilityIdentifier = "id.teamButton"
    return button
  }()

  /// 取消按钮
  lazy var cancelButton: ExpandButton = {
    let button = ExpandButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.accessibilityIdentifier = "id.cancel"
    button.setTitle(localizable("alert_cancel"), for: .normal)
    button.setTitleColor(.ne_greyText, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 16)
    button.addTarget(self, action: #selector(cancelButtonAction), for: .touchUpInside)
    return button
  }()

  /// 多选按钮
  lazy var multiSelectButton: ExpandButton = {
    let button = ExpandButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.accessibilityIdentifier = "id.multiSelect"
    button.setTitle(localizable("multi_select"), for: .normal)
    button.setTitleColor(.ne_greyText, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 16)
    button.contentHorizontalAlignment = .right
    button.addTarget(self, action: #selector(multiSelectButtonAction), for: .touchUpInside)
    return button
  }()

  /// 确定按钮
  lazy var sureButton: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.accessibilityIdentifier = "id.sureButton"
    button.setTitle(sureButtonText, for: .normal)
    button.setTitleColor(UIColor.ne_normalTheme, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 16)
    button.layer.cornerRadius = 4
    button.addTarget(self, action: #selector(sureButtonAction), for: .touchUpInside)
    button.isHidden = true
    button.isEnabled = false
    return button
  }()

  /// Tab 选择区域（最近会话 | 我的好友 | 我的群聊）
  public lazy var tabContentView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear

    let tabButtonWidth = IMKitConfigCenter.shared.enableTeam ? NEConstant.screenWidth / 3.0 : NEConstant.screenWidth / 2.0

    view.addSubview(recentButton)
    NSLayoutConstraint.activate([
      recentButton.topAnchor.constraint(equalTo: view.topAnchor),
      recentButton.leftAnchor.constraint(equalTo: view.leftAnchor),
      recentButton.heightAnchor.constraint(equalToConstant: 48),
      recentButton.widthAnchor.constraint(equalToConstant: tabButtonWidth),
    ])

    view.addSubview(friendButton)
    NSLayoutConstraint.activate([
      friendButton.topAnchor.constraint(equalTo: recentButton.topAnchor),
      friendButton.leftAnchor.constraint(equalTo: recentButton.rightAnchor),
      friendButton.widthAnchor.constraint(equalTo: recentButton.widthAnchor),
      friendButton.heightAnchor.constraint(equalTo: recentButton.heightAnchor),
    ])

    if IMKitConfigCenter.shared.enableTeam {
      view.addSubview(teamButton)
      NSLayoutConstraint.activate([
        teamButton.topAnchor.constraint(equalTo: recentButton.topAnchor),
        teamButton.leftAnchor.constraint(equalTo: friendButton.rightAnchor),
        teamButton.widthAnchor.constraint(equalTo: recentButton.widthAnchor),
        teamButton.heightAnchor.constraint(equalTo: recentButton.heightAnchor),
      ])
    }

    // 未选中下划线
    var selectLine: UIView = .init()
    selectLine.translatesAutoresizingMaskIntoConstraints = false
    selectLine.backgroundColor = .ne_navLineColor
    view.addSubview(selectLine)
    NSLayoutConstraint.activate([
      selectLine.leftAnchor.constraint(equalTo: view.leftAnchor),
      selectLine.rightAnchor.constraint(equalTo: view.rightAnchor),
      selectLine.bottomAnchor.constraint(equalTo: recentButton.bottomAnchor, constant: 0),
      selectLine.heightAnchor.constraint(equalToConstant: 1),
    ])

    // 选中下划线
    var selectedLine: UIView = .init()
    selectedLine.translatesAutoresizingMaskIntoConstraints = false
    selectedLine.backgroundColor = themeColor
    view.addSubview(selectedLine)
    selectedLineLeftAnchor = selectedLine.leftAnchor.constraint(equalTo: view.leftAnchor)
    NSLayoutConstraint.activate([
      selectedLine.bottomAnchor.constraint(equalTo: recentButton.bottomAnchor, constant: 0),
      selectedLine.heightAnchor.constraint(equalToConstant: 2),
      selectedLine.widthAnchor.constraint(equalTo: recentButton.widthAnchor),
      selectedLineLeftAnchor!,
    ])

    return view
  }()

  // 【最近会话】的 tableView
  public lazy var recentTableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .clear
    tableView.sectionIndexColor = .ne_greyText
    tableView.delegate = self
    tableView.dataSource = self
    tableView.separatorStyle = .none
    tableView.keyboardDismissMode = .onDrag

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

  // 【我的好友】的 tableView
  public lazy var friendTableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .clear
    tableView.sectionIndexColor = .ne_greyText
    tableView.delegate = self
    tableView.dataSource = self
    tableView.separatorStyle = .none
    tableView.isHidden = true
    tableView.keyboardDismissMode = .onDrag

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

  // 【我的群聊】的 tableView
  public lazy var teamTableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .clear
    tableView.sectionIndexColor = .ne_greyText
    tableView.delegate = self
    tableView.dataSource = self
    tableView.separatorStyle = .none
    tableView.isHidden = true
    tableView.keyboardDismissMode = .onDrag

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

  /// tableView 背景视图
  public lazy var tableViewContentView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(recentTableView)
    NSLayoutConstraint.activate([
      recentTableView.topAnchor.constraint(equalTo: view.topAnchor),
      recentTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      recentTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      recentTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    view.addSubview(friendTableView)
    NSLayoutConstraint.activate([
      friendTableView.topAnchor.constraint(equalTo: view.topAnchor),
      friendTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      friendTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      friendTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    view.addSubview(teamTableView)
    NSLayoutConstraint.activate([
      teamTableView.topAnchor.constraint(equalTo: view.topAnchor),
      teamTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      teamTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      teamTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    return view
  }()

  /// 会话选择区域，包含 tab 和 tableView
  public lazy var sessionContentView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.topAnchor.constraint(equalTo: view.topAnchor, constant: -40),
      emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      emptyView.leftAnchor.constraint(equalTo: view.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])

    view.addSubview(tabContentView)
    NSLayoutConstraint.activate([
      tabContentView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tabContentView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tabContentView.topAnchor.constraint(equalTo: view.topAnchor),
      tabContentView.heightAnchor.constraint(equalToConstant: 48),
    ])

    view.addSubview(tableViewContentView)
    NSLayoutConstraint.activate([
      tableViewContentView.topAnchor.constraint(equalTo: view.topAnchor, constant: 48),
      tableViewContentView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableViewContentView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableViewContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    return view
  }()

  // MARK: - Action

  /// 搜索文案变动
  /// - Parameter textfield: 搜索框
  func searchTextFieldChange(textfield: SearchTextField) {
    guard let searchText = textfield.text else {
      return
    }

    self.searchText = searchText
    recentContentView.isHidden = recentArray.isEmpty || !searchText.isEmpty
    recentContentViewHeightAnchor?.constant = recentContentView.isHidden ? 16 : recentContentViewHeight

    if searchText.isEmpty {
      loadData(tabIndex)
      return
    }

    let textRange = textfield.markedTextRange
    if textRange == nil || ((textRange?.isEmpty) == nil) {
      loadData(tabIndex)
    }
  }

  /// 多选按钮点击事件
  /// - Parameter sender: 按钮
  open func multiSelectButtonAction(_ sender: UIButton) {
    isMultiSelect = true
    multiSelectButton.isHidden = true
    sureButton.isHidden = false
    recentCollectionView.reloadData()
    currentTableView?.reloadData()
  }

  /// 确认按钮点击事件
  /// - Parameter sender: 按钮
  open func sureButtonAction() {
    // 校验网络
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      // 如果是单选则从已选列表中移除
      if !isMultiSelect {
        selectedArray.first?.isSelected = false
        selectedArray.removeAll()
      }
      return
    }

    var conversationJSONs = [[String: Any]]()
    for model in selectedArray {
      var conversationJSON = [String: Any]()
      conversationJSON["conversationId"] = model.conversationId
      conversationJSON["name"] = model.name
      conversationJSON["avatar"] = model.avatar
      conversationJSONs.append(conversationJSON)
    }

    Router.shared.use(ForwardMultiSelectedRouter, parameters: ["conversations": conversationJSONs], closure: nil)

    cancelButtonAction()
  }

  /// 取消按钮点击事件
  /// - Parameter button: 按钮
  func cancelButtonAction() {
    dismiss(animated: true, completion: nil)
  }

  /// 获取已选视图控制器
  /// - Parameter selectedArray: 已选列表
  /// - Returns: 已选页面的视图控制器
  open func getMultiSelectedViewController(_ selectedArray: [MultiSelectModel]) -> NEBaseMultiSelectedViewController {
    NEBaseMultiSelectedViewController(selectedArray: selectedArray)
  }

  /// 已选视图点击事件
  func selectedCollectionViewAction() {
    let selectedVC = getMultiSelectedViewController(selectedArray)
    selectedVC.delegate = self
    present(selectedVC, animated: true)
  }

  /// tab 点击事件
  /// - Parameter index: tab 下标
  func setTabButtonLine(_ index: Int) {
    tabIndex = index
    selectedLineLeftAnchor?.constant = recentButton.width * CGFloat(index)

    // 设置 tab 按钮文案颜色
    for (i, view) in tabContentView.subviews.enumerated() {
      if let button = view as? UIButton {
        button.isSelected = i == index
      }
    }

    // 设置 UITableView 显隐
    for (i, view) in tableViewContentView.subviews.enumerated() {
      if let tableView = view as? UITableView {
        if i == index {
          currentTableView = tableView
        }
        tableView.isHidden = i != index
      }
    }

    UIView.animate(withDuration: 0.5) {
      self.view.layoutIfNeeded()
    }

    loadData(index)
  }

  /// 设置空白占位图文案
  /// - Parameter text: 搜索文案
  func setEmptyViewText(_ text: String?) {
    if let searchText = searchText, !searchText.isEmpty {
      let att = NSMutableAttributedString(string: String(format: commonLocalizable("no_search_result"), searchText))
      let range = att.mutableString.range(of: searchText)
      att.addAttribute(.foregroundColor, value: themeColor as Any, range: range)
      emptyView.setAttributedText(att)
      return
    }

    switch tabIndex {
    case 1:
      emptyView.setText(localizable("no_friend"))
    case 2:
      emptyView.setText(localizable("team_empty"))
    default:
      emptyView.setText(localizable("session_empty"))
    }
  }

  /// 最近会话 tab 点击事件
  func recentButtonAction() {
    if tabIndex == 0 {
      return
    }

    setTabButtonLine(0)
  }

  /// 我的好友 tab 点击事件
  func friendButtonAction() {
    if tabIndex == 1 {
      return
    }

    setTabButtonLine(1)
  }

  /// 我的群聊 tab 点击事件
  func teamButtonAction() {
    if tabIndex == 2 {
      return
    }

    setTabButtonLine(2)
  }

  // MARK: - Table View DataSource And Delegate

  open func numberOfSections(in tableView: UITableView) -> Int {
    if tableView == currentTableView {
      return 1
    }

    return 0
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if tableView == currentTableView {
      return viewModel.sessions.count
    }

    return 0
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if tableView == currentTableView {
      let info = viewModel.sessions[indexPath.row]
      let cell = tableView.dequeueReusableCell(
        withIdentifier: "\(NSStringFromClass(NEBaseSelectCell.self))",
        for: indexPath
      ) as! SelectCell
      cell.showSelect(isMultiSelect)
      cell.setModel(info)
      cell.searchText = searchText
      return cell
    }

    return UITableViewCell()
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let info = viewModel.sessions[indexPath.row]
    if info.isSelected == true {
      didUnselectContact(info)
    } else {
      if selectedArray.count >= limit {
        view.makeToast(String(format: localizable("choose_max_limit"), limit))
        return
      }
      didSelectContact(info)
    }

    // 选中后收起搜索键盘
    view.endEditing(true)
  }

  // MARK: - UIScrollViewDelegate

  /// 监听滚动
  /// - Parameter scrollView: 滚动视图
  public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    // 滚动时收起搜索键盘
    view.endEditing(true)
  }

  // MARK: Collection View DataSource And Delegate

  open func collectionView(_ collectionView: UICollectionView,
                           numberOfItemsInSection section: Int) -> Int {
    if collectionView == recentCollectionView {
      return recentArray.count
    } else if collectionView == selectedCollectionView {
      return selectedArray.count
    } else {
      return 0
    }
  }

  open func collectionView(_ collectionView: UICollectionView,
                           layout collectionViewLayout: UICollectionViewLayout,
                           sizeForItemAt indexPath: IndexPath) -> CGSize {
    if collectionView == recentCollectionView {
      return CGSize(width: 72, height: isMultiSelect ? 84 : 60)
    } else if collectionView == selectedCollectionView {
      return CGSize(width: 46, height: selectedContentViewHeight)
    } else {
      return CGSize.zero
    }
  }

  open func collectionView(_ collectionView: UICollectionView,
                           cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    var contactInfo = MultiSelectModel()

    if collectionView == recentCollectionView {
      contactInfo = recentArray[indexPath.row]
    } else if collectionView == selectedCollectionView {
      contactInfo = selectedArray[indexPath.row]
    }

    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "\(NSStringFromClass(NEBaseSelectedCell.self))",
      for: indexPath
    ) as? NEBaseSelectedCell
    cell?.configure(contactInfo)

    // 最近转发中的 cell
    if let c = cell as? NEBaseRecentSelectCell {
      c.showSelect(isMultiSelect)
    }

    return cell ?? UICollectionViewCell()
  }

  open func collectionView(_ collectionView: UICollectionView,
                           didSelectItemAt indexPath: IndexPath) {
    var contactInfo = MultiSelectModel()

    if collectionView == recentCollectionView {
      contactInfo = recentArray[indexPath.row]
      if contactInfo.isSelected {
        didUnselectContact(contactInfo)
      } else {
        didSelectContact(contactInfo)
      }
    } else if collectionView == selectedCollectionView {
      contactInfo = selectedArray[indexPath.row]
      didUnselectContact(contactInfo)
    }
  }

  /// 选中事件
  /// - Parameter model: 数据模型
  func didSelectContact(_ model: MultiSelectModel) {
    model.isSelected = true
    if selectedArray.contains(where: { c in
      model === c
    }) == false {
      selectedArray.append(model)

      // 单选点击直接弹窗
      if !isMultiSelect {
        sureButtonAction()
        return
      }

      if (selectedContentViewHeightAnchor?.constant ?? 0) <= 0 {
        selectedContentView.isHidden = false
        selectedContentViewHeightAnchor?.constant = selectedContentViewHeight
      }
    }

    recentCollectionView.reloadData()
    selectedCollectionView.reloadData()
    currentTableView?.reloadData()
    refreshSelectCount()
  }

  /// 取消选中事件
  /// - Parameter model: 数据模型
  func didUnselectContact(_ model: MultiSelectModel) {
    model.isSelected = false
    selectedArray.removeAll { c in
      model === c
    }
    if selectedArray.count <= 0 {
      selectedContentView.isHidden = true
      selectedContentViewHeightAnchor?.constant = 0
    }

    recentCollectionView.reloadData()
    selectedCollectionView.reloadData()
    currentTableView?.reloadData()
    refreshSelectCount()
  }

  /// 刷新（确定按钮）已选人数
  func refreshSelectCount() {
    if selectedArray.count > 0 {
      sureButton.isEnabled = true
      sureButton.setTitle(sureButtonText + "(\(selectedArray.count))", for: .normal)
    } else {
      sureButton.isEnabled = false
      sureButton.setTitle(sureButtonText, for: .normal)
    }
  }
}

extension NEBaseMultiSelectViewController: NEBaseMultiSelectedViewControllerDelegate {
  /// 移除按钮点击事件
  /// - Parameter model: 数据模型
  public func removeButtonAction(_ model: MultiSelectModel?) {
    if let m = model {
      didUnselectContact(m)
    }
  }
}
