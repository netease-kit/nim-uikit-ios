
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import MJRefresh
import NEChatKit
import NECommonKit
import NIMSDK

@objc
public protocol NEBaseConversationControllerDelegate {
  func onDataLoaded()
}

/// 会话列表页面 - 基类
@objcMembers
open class NEBaseConversationController: UIViewController, UIGestureRecognizerDelegate {
  var className = "NEBaseConversationController"
  public var deleteButtonBackgroundColor: UIColor = NEConstant.hexRGB(0xA8ABB6)

  public var brokenNetworkViewHeight = 36.0
  private var bodyTopViewHeightAnchor: NSLayoutConstraint?
  private var bodyBottomViewHeightAnchor: NSLayoutConstraint?
  public var contentViewTopAnchor: NSLayoutConstraint?
  public var topConstant: CGFloat = 0
  public var popListView = NEBasePopListView()

  public var delegate: NEBaseConversationControllerDelegate?

  /// 是否取过数据
  public var isRequestedData = false

  public var bodyTopViewHeight: CGFloat = 0 {
    didSet {
      bodyTopViewHeightAnchor?.constant = bodyTopViewHeight
      bodyTopView.isHidden = bodyTopViewHeight <= 0
    }
  }

  public var bodyBottomViewHeight: CGFloat = 0 {
    didSet {
      bodyBottomViewHeightAnchor?.constant = bodyBottomViewHeight
      bodyBottomView.isHidden = bodyBottomViewHeight <= 0
    }
  }

  public var cellRegisterDic = [0: NEBaseConversationListCell.self]
  /// 置顶l列表样式注册表
  public var stickTopCellRegisterDic = [0: NEBaseStickTopCell.self]
  public let viewModel = ConversationViewModel()

  public lazy var navigationView: TabNavigationView = {
    let nav = TabNavigationView(frame: CGRect.zero)
    nav.translatesAutoresizingMaskIntoConstraints = false
    nav.delegate = self

    nav.brandBtn.addTarget(self, action: #selector(brandBtnClick), for: .touchUpInside)

    if let brandTitle = NEKitConversationConfig.shared.ui.titleBarTitle {
      nav.brandBtn.setTitle(brandTitle, for: .normal)
    }
    if let brandTitleColor = NEKitConversationConfig.shared.ui.titleBarTitleColor {
      nav.brandBtn.setTitleColor(brandTitleColor, for: .normal)
    }
    if !NEKitConversationConfig.shared.ui.showTitleBarLeftIcon {
      nav.brandBtn.setImage(nil, for: .normal)
      // 如果左侧图标为空，则左侧文案左对齐
      nav.brandBtn.layoutButtonImage(style: .left, space: 0)
    }
    if let brandImg = NEKitConversationConfig.shared.ui.titleBarLeftRes {
      nav.brandBtn.setImage(brandImg, for: .normal)
      if brandImg.size.width == 0, brandImg.size.height == 0 {
        // 如果左侧图标为空，则左侧文案左对齐
        nav.brandBtn.layoutButtonImage(style: .left, space: 0)
      }
    }
    if let rightImg = NEKitConversationConfig.shared.ui.titleBarRightRes {
      nav.addBtn.setImage(rightImg, for: .normal)
    }
    if let right2Img = NEKitConversationConfig.shared.ui.titleBarRight2Res {
      nav.searchBtn.setImage(right2Img, for: .normal)
    }
    return nav
  }()

  public lazy var bodyTopView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    return view
  }()

  public lazy var bodyView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear

    view.addSubview(brokenNetworkView)
    view.addSubview(contentView)

    NSLayoutConstraint.activate([
      brokenNetworkView.topAnchor.constraint(equalTo: view.topAnchor),
      brokenNetworkView.leftAnchor.constraint(equalTo: view.leftAnchor),
      brokenNetworkView.rightAnchor.constraint(equalTo: view.rightAnchor),
      brokenNetworkView.heightAnchor.constraint(equalToConstant: brokenNetworkViewHeight),
    ])

    contentViewTopAnchor = contentView.topAnchor.constraint(equalTo: view.topAnchor)
    contentViewTopAnchor?.isActive = true
    NSLayoutConstraint.activate([
      contentView.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentView.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    return view
  }()

  public lazy var brokenNetworkView: NEBrokenNetworkView = {
    let view = NEBrokenNetworkView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    return view
  }()

  public lazy var contentView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    view.addSubview(tableView)
    view.addSubview(emptyView)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])

    NSLayoutConstraint.activate([
      emptyView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 100),
      emptyView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
      emptyView.leftAnchor.constraint(equalTo: tableView.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: tableView.rightAnchor),
    ])

    return view
  }()

  public lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(
      imageName: "user_empty",
      content: localizable("session_empty"),
      frame: CGRect.zero
    )
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isUserInteractionEnabled = false
    view.isHidden = true
    view.backgroundColor = .clear
    return view
  }()

  public lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
    tableView.keyboardDismissMode = .onDrag

    if #available(iOS 11.0, *) {
      tableView.estimatedRowHeight = 0
      tableView.estimatedSectionHeaderHeight = 0
      tableView.estimatedSectionFooterHeight = 0
    }
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }

    tableView.mj_footer = MJRefreshBackNormalFooter(
      refreshingTarget: self,
      refreshingAction: #selector(loadMoreData)
    )
    return tableView
  }()

  public lazy var bodyBottomView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    return view
  }()

  /// 置顶内容展示列表
  lazy var stickTopCollcetionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    let collcetionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collcetionView.backgroundColor = UIColor.clear
    collcetionView.translatesAutoresizingMaskIntoConstraints = false
    collcetionView.dataSource = self
    collcetionView.delegate = self
    collcetionView.isUserInteractionEnabled = true
    collcetionView.isPagingEnabled = true
    collcetionView.showsHorizontalScrollIndicator = false
    collcetionView.showsVerticalScrollIndicator = false
    collcetionView.alwaysBounceHorizontal = true
    collcetionView.clipsToBounds = false
    return collcetionView
  }()

  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    showTitleBar()

    // 是否取过数据，如果取过数据再刷新页面
    if isRequestedData == true {
      reloadTableView()
    }

    NEChatDetectNetworkTool.shareInstance.netWorkReachability { [weak self] status in
      if status == .notReachable {
        self?.brokenNetworkView.isHidden = false
        self?.contentViewTopAnchor?.constant = self?.brokenNetworkViewHeight ?? 36
      } else {
        self?.brokenNetworkView.isHidden = true
        self?.contentViewTopAnchor?.constant = 0
      }
    }

    if navigationController?.viewControllers.count ?? 0 > 0 {
      if let root = navigationController?.viewControllers[0] as? UIViewController {
        if root.isKind(of: NEBaseConversationController.self) {
          navigationController?.interactivePopGestureRecognizer?.delegate = self
        }
      }
    }
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    showTitleBar()
    setupSubviews()
    requestData()
    initialConfig()
  }

  override open func viewWillDisappear(_ animated: Bool) {
    popListView.removeSelf()
  }

  open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let navigationController = navigationController,
       navigationController.responds(to: #selector(getter: UINavigationController.interactivePopGestureRecognizer)),
       gestureRecognizer == navigationController.interactivePopGestureRecognizer,
       navigationController.visibleViewController == navigationController.viewControllers.first {
      return false
    }
    return true
  }

  open func showTitleBar() {
    if let useSystemNav = NEConfigManager.instance.getParameter(key: useSystemNav) as? Bool, useSystemNav {
      navigationView.isHidden = true
      topConstant = 0
      if NEKitConversationConfig.shared.ui.showTitleBar {
        navigationController?.isNavigationBarHidden = false
      } else {
        navigationController?.isNavigationBarHidden = true
        if #available(iOS 10, *) {
          topConstant += NEConstant.statusBarHeight
        }
      }
    } else {
      navigationController?.isNavigationBarHidden = true
      if NEKitConversationConfig.shared.ui.showTitleBar {
        navigationView.isHidden = false
        topConstant = NEConstant.navigationHeight
      } else {
        navigationView.isHidden = true
        topConstant = 0
      }
      if #available(iOS 10, *) {
        topConstant += NEConstant.statusBarHeight
      }
    }
  }

  func initSystemNav() {
    edgesForExtendedLayout = []

    let brandBarBtn = UIButton()
    brandBarBtn.accessibilityIdentifier = "id.titleBarTitle"
    brandBarBtn.setTitle(localizable("appName"), for: .normal)
    brandBarBtn.setImage(UIImage.ne_imageNamed(name: "brand_yunxin"), for: .normal)
    brandBarBtn.layoutButtonImage(style: .left, space: 12)
    brandBarBtn.setTitleColor(UIColor.black, for: .normal)
    brandBarBtn.titleLabel?.font = NEConstant.textFont("PingFangSC-Medium", 20)
    let brandBtn = UIBarButtonItem(customView: brandBarBtn)
    navigationItem.leftBarButtonItem = brandBtn
  }

  open func setupSubviews() {
    initSystemNav()
    view.addSubview(navigationView)
    view.addSubview(bodyTopView)
    view.addSubview(bodyView)
    view.addSubview(bodyBottomView)

    NSLayoutConstraint.activate([
      navigationView.topAnchor.constraint(equalTo: view.topAnchor),
      navigationView.leftAnchor.constraint(equalTo: view.leftAnchor),
      navigationView.rightAnchor.constraint(equalTo: view.rightAnchor),
      navigationView.heightAnchor
        .constraint(equalToConstant: NEConstant.navigationAndStatusHeight),
    ])

    NSLayoutConstraint.activate([
      bodyTopView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      bodyTopView.leftAnchor.constraint(equalTo: view.leftAnchor),
      bodyTopView.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])
    bodyTopViewHeightAnchor = bodyTopView.heightAnchor.constraint(equalToConstant: bodyTopViewHeight)
    bodyTopViewHeightAnchor?.isActive = true

    NSLayoutConstraint.activate([
      bodyView.topAnchor.constraint(equalTo: bodyTopView.bottomAnchor),
      bodyView.leftAnchor.constraint(equalTo: view.leftAnchor),
      bodyView.rightAnchor.constraint(equalTo: view.rightAnchor),
      bodyView.bottomAnchor.constraint(equalTo: bodyBottomView.topAnchor),
    ])

    NSLayoutConstraint.activate([
      bodyBottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      bodyBottomView.leftAnchor.constraint(equalTo: view.leftAnchor),
      bodyBottomView.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])
    bodyBottomViewHeightAnchor = bodyBottomView.heightAnchor.constraint(equalToConstant: bodyBottomViewHeight)
    bodyBottomViewHeightAnchor?.isActive = true

    for (key, value) in cellRegisterDic {
      tableView.register(value, forCellReuseIdentifier: "\(key)")
    }

    for (key, value) in stickTopCellRegisterDic {
      stickTopCollcetionView.register(value, forCellWithReuseIdentifier: "\(key)")
    }

    if let customController = NEKitConversationConfig.shared.ui.customController {
      customController(self)
    }
  }

  open func initialConfig() {
    viewModel.delegate = self
  }

  func loadMoreData() {
    viewModel.getConversationListByPage { [weak self] error, finishied in
      self?.isRequestedData = true
      if let end = finishied, end == true {
        self?.tableView.mj_footer?.endRefreshingWithNoMoreData()
        DispatchQueue.main.async {
          self?.tableView.mj_footer = nil
        }
      } else {
        self?.tableView.mj_footer?.endRefreshing()
      }
      self?.delegate?.onDataLoaded()
      self?.reloadTableView()
    }
  }

  func requestData() {
    viewModel.getConversationListByPage { [weak self] error, finished in
      self?.viewModel.getAIUserList()

      if let err = error {
        self?.view.ne_makeToast(err.localizedDescription)
        self?.emptyView.isHidden = false
        NEALog.errorLog(
          ModuleName + " " + (self?.className ?? ""),
          desc: "CALLBACK requestData failed，error = \(error!)"
        )
      } else {
        if let end = finished, end == true {
          DispatchQueue.main.async {
            self?.tableView.mj_footer = nil
          }
        }
        if let topDats = self?.viewModel.stickTopConversations, let normalDatas = self?.viewModel.conversationListData {
          if topDats.count <= 0, normalDatas.count <= 0 {
            self?.emptyView.isHidden = false
          } else {
            self?.emptyView.isHidden = true
            self?.reloadTableView()
            self?.delegate?.onDataLoaded()
          }
        }
      }
    }
  }

  // MARK: lazyMethod
}

extension NEBaseConversationController: TabNavigationViewDelegate {
  /// 标题栏左侧按钮点击事件
  func brandBtnClick() {
    NEKitConversationConfig.shared.ui.titleBarLeftClick?()
  }

  /// 点击搜索会话
  open func searchAction() {
    if let searchBlock = NEKitConversationConfig.shared.ui.titleBarRight2Click {
      searchBlock()
      return
    }

    Router.shared.use(
      SearchContactPageRouter,
      parameters: ["nav": navigationController as Any],
      closure: nil
    )
  }

  open func getPopListView() -> NEBasePopListView {
    NEBasePopListView()
  }

  open func getPopListItems() -> [PopListItem] {
    weak var weakSelf = self
    var items = [PopListItem]()
    let addFriend = PopListItem()
    addFriend.showName = localizable("add_friend")
    addFriend.image = UIImage.ne_imageNamed(name: "add_friend")
    addFriend.completion = {
      Router.shared.use(
        ContactAddFriendRouter,
        parameters: ["nav": self.navigationController as Any],
        closure: nil
      )
    }
    items.append(addFriend)

    let createGroup = PopListItem()
    createGroup.showName = localizable("create_discussion_group")
    createGroup.image = UIImage.ne_imageNamed(name: "create_discussion")
    createGroup.completion = {
      weakSelf?.createDiscussGroup()
    }
    items.append(createGroup)

    let createDicuss = PopListItem()
    createDicuss.showName = localizable("create_senior_group")
    createDicuss.image = UIImage.ne_imageNamed(name: "create_group")
    createDicuss.completion = {
      weakSelf?.createSeniorGroup()
    }
    items.append(createDicuss)

    return items
  }

  open func didClickAddBtn() {
    if let addBlock = NEKitConversationConfig.shared.ui.titleBarRightClick {
      addBlock()
      return
    }

    if IMKitConfigCenter.shared.enableTeam {
      popListView.itemDatas = getPopListItems()
      popListView.frame = CGRect(origin: .zero, size: view.frame.size)
      popListView.removeSelf()
      view.addSubview(popListView)
    } else {
      Router.shared.use(
        ContactAddFriendRouter,
        parameters: ["nav": navigationController as Any],
        closure: nil
      )
    }
  }

  /// 创建讨论组
  open func createDiscussGroup() {
    Router.shared.register(ContactSelectedUsersRouter) { param in
      print("user setting accids : ", param)
      Router.shared.use(TeamCreateDisuss, parameters: param, closure: nil)
    }

    // 创建讨论组-人员选择页面不包含自己
    var filters = Set<String>()
    filters.insert(IMKitClient.instance.account())

    if IMKitConfigCenter.shared.enableAIUser {
      Router.shared.use(
        ContactFusionSelectRouter,
        parameters: ["nav": navigationController as Any,
                     "limit": inviteNumberLimit,
                     "filters": filters],
        closure: nil
      )
    } else {
      Router.shared.use(
        ContactUserSelectRouter,
        parameters: ["nav": navigationController as Any,
                     "limit": inviteNumberLimit,
                     "filters": filters],
        closure: nil
      )
    }

    weak var weakSelf = self
    Router.shared.register(TeamCreateDiscussResult) { param in
      print("create discuss ", param)
      if let code = param["code"] as? Int, let teamid = param["teamId"] as? String,
         code == 0 {
        if let conversationId = V2NIMConversationIdUtil.teamConversationId(teamid) {
          var params = [String: Any]()
          params["nav"] = weakSelf?.navigationController as Any
          params["conversationId"] = conversationId as Any

          Router.shared.use(PushTeamChatVCRouter, parameters: params, closure: nil)
        }
      } else if let msg = param["msg"] as? String {
        weakSelf?.showToast(msg)
      }
    }
  }

  /// 创建高级群
  open func createSeniorGroup() {
    Router.shared.register(ContactSelectedUsersRouter) { param in
      Router.shared.use(TeamCreateSenior, parameters: param, closure: nil)
    }

    // 创建高级群-人员选择页面不包含自己
    var filters = Set<String>()
    filters.insert(IMKitClient.instance.account())

    if IMKitConfigCenter.shared.enableAIUser {
      Router.shared.use(
        ContactFusionSelectRouter,
        parameters: ["nav": navigationController as Any,
                     "limit": inviteNumberLimit,
                     "filters": filters],
        closure: nil
      )
    } else {
      Router.shared.use(
        ContactUserSelectRouter,
        parameters: ["nav": navigationController as Any,
                     "limit": inviteNumberLimit,
                     "filters": filters],
        closure: nil
      )
    }

    weak var weakSelf = self
    Router.shared.register(TeamCreateSeniorResult) { param in
      print("create senior : ", param)
      if let code = param["code"] as? Int, let teamid = param["teamId"] as? String,
         code == 0 {
        if let conversationId = V2NIMConversationIdUtil.teamConversationId(teamid) {
          var params = [String: Any]()
          params["nav"] = weakSelf?.navigationController as Any
          params["conversationId"] = conversationId as Any

          Router.shared.use(PushTeamChatVCRouter, parameters: params, closure: nil)
        }
      } else if let msg = param["msg"] as? String {
        weakSelf?.showToast(msg)
      }
    }
  }
}

extension NEBaseConversationController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  public func numberOfSections(in collectionView: UICollectionView) -> Int {
    1
  }

  /// 置顶分区
  open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    viewModel.aiUserListData.count
  }

  /// 置顶数据源绑定
  open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let model = viewModel.aiUserListData[indexPath.row]

    let reusedId = "\(model.customType)"
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reusedId, for: indexPath)

    if let c = cell as? NEBaseStickTopCell {
      c.configAIUserCellData(model)
    }
    return cell
  }

  /// 置顶cell大小，因为两套皮肤不同，在子类中具体实现
  open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    CGSize.zero
  }

  /// 置顶点击
  open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let conversationModel = viewModel.aiUserListData[indexPath.row]

    if let accountId = conversationModel.aiUser?.accountId, let conversationId = V2NIMConversationIdUtil.p2pConversationId(accountId) {
      Router.shared.use(
        PushP2pChatVCRouter,
        parameters: ["nav": navigationController as Any, "conversationId": conversationId as Any],
        closure: nil
      )
    }
  }
}

extension NEBaseConversationController: UITableViewDelegate, UITableViewDataSource {
  public func numberOfSections(in tableView: UITableView) -> Int {
    2
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return viewModel.stickTopConversations.count
    }
    return viewModel.conversationListData.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var model: NEConversationListModel?

    if indexPath.section == 0 {
      model = viewModel.stickTopConversations[indexPath.row]
    } else if indexPath.section == 1 {
      model = viewModel.conversationListData[indexPath.row]
    }

    let reusedId = "\(model?.customType ?? 0)"
    let cell = tableView.dequeueReusableCell(withIdentifier: reusedId, for: indexPath)

    if let c = cell as? NEBaseConversationListCell, let m = model {
      c.configureData(m)
    }

    return cell
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    var conversationModel: NEConversationListModel?
    if indexPath.section == 0 {
      conversationModel = viewModel.stickTopConversations[indexPath.row]
    } else if indexPath.section == 1 {
      conversationModel = viewModel.conversationListData[indexPath.row]
    }

    if let didClick = NEKitConversationConfig.shared.ui.itemClick, let model = conversationModel {
      didClick(model, indexPath)
      return
    }

    if let conversation = conversationModel?.conversation {
      onselectedTableRow(conversation: conversation)
    }
  }

  open func tableView(_ tableView: UITableView,
                      editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    weak var weakSelf = self

    var rowActions = [UITableViewRowAction]()
    let deleteAction = UITableViewRowAction(style: .destructive,
                                            title: NEKitConversationConfig.shared.ui.deleteButtonTitle) { action, indexPath in
      weakSelf?.deleteActionHandler(action: action, indexPath: indexPath)
    }

    // 置顶和取消置顶
    let isTop = indexPath.section == 0 ? true : false // viewModel.stickTopInfos[session] != nil
    let topAction = UITableViewRowAction(style: .destructive,
                                         title: isTop ? NEKitConversationConfig.shared.ui.stickTopButtonCancelTitle :
                                           NEKitConversationConfig.shared.ui.stickTopButtonTitle) { action, indexPath in
      weakSelf?.topActionHandler(action: action, indexPath: indexPath, isTop: isTop)
    }
    deleteAction.backgroundColor = NEKitConversationConfig.shared.ui.deleteButtonBackgroundColor ?? deleteButtonBackgroundColor
    topAction.backgroundColor = NEKitConversationConfig.shared.ui.stickTopButtonBackgroundColor ?? NEConstant.hexRGB(0x337EFF)
    rowActions.append(deleteAction)
    rowActions.append(topAction)

    /* 会话数字人pin到顶部处理
      var model: NEConversationListModel?
      if indexPath.section == 0 {
        model = viewModel.stickTopConversations[indexPath.row]
      } else if indexPath.section == 1 {
        model = viewModel.conversationListData[indexPath.row]
      }
     if model?.conversation?.type == .CONVERSATION_TYPE_P2P {
       if let conversationId = model?.conversation?.conversationId {
         if let accountId = V2NIMConversationIdUtil.conversationTargetId(conversationId) {
           if let enalbeAIUser = NEAIUserPinManager.shared.checkoutPinEnable(accountId) {
             let pinToTop = NEAIUserPinManager.shared.checkoutUnPinAIUser(enalbeAIUser)
             let pinToTopAction = UITableViewRowAction(style: .destructive, title: pinToTop ? localizable("ai_user_cancel_pin_top") : localizable("ai_user_pin_top")) { action, indexPath in
               weakSelf?.pinToTopActionHandler(user: enalbeAIUser, pinTop: pinToTop)
             }
             pinToTopAction.backgroundColor = .green
             rowActions.append(pinToTopAction)
           }
         }
       }
     } */

    return rowActions
  }

  /// 删除会话
  open func deleteActionHandler(action: UITableViewRowAction?, indexPath: IndexPath) {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    var conversationModel: NEConversationListModel?

    if indexPath.section == 0 {
      conversationModel = viewModel.stickTopConversations[indexPath.row]

    } else if indexPath.section == 1 {
      conversationModel = viewModel.conversationListData[indexPath.row]
    }

    if let deleteButtonClick = NEKitConversationConfig.shared.ui.deleteButtonClick {
      deleteButtonClick(conversationModel, indexPath)
      return
    }

    if let conversation = conversationModel?.conversation {
      viewModel.deleteConversation(conversation) { [weak self] error in
        if let err = error {
          self?.view.ne_makeToast(err.localizedDescription)
        }
        self?.reloadTableView()
      }
    }
  }

  /// pin 置顶
  open func pinToTopActionHandler(user: V2NIMUser, pinTop: Bool) {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(localizable("network_error"))
      return
    }
    if let accountId = user.accountId {
      if pinTop {
        NEAIUserPinManager.shared.unpinAIUser(accountId) { error, finish in
        }
      } else {
        NEAIUserPinManager.shared.pinAIUser(accountId) { error, finish in
        }
      }
    }
  }

  /// 点击会话
  open func topActionHandler(action: UITableViewRowAction?, indexPath: IndexPath, isTop: Bool) {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(localizable("network_error"))
      return
    }
    var conversationModel: NEConversationListModel?
    if indexPath.section == 0 {
      conversationModel = viewModel.stickTopConversations[indexPath.row]
    } else {
      conversationModel = viewModel.conversationListData[indexPath.row]
    }

    if let stickTopButtonClick = NEKitConversationConfig.shared.ui.stickTopButtonClick {
      stickTopButtonClick(conversationModel, indexPath)
      return
    }

    if let conversation = conversationModel?.conversation {
      onTopRecentAtIndexPath(conversation: conversation,
                             indexPath: indexPath,
                             isTop: isTop) { [weak self] error in

        if let err = error {
          self?.view.ne_makeToast(err.localizedDescription)
        } else {
          if isTop {
            self?.didRemoveStickTopSession(
              model: conversationModel ?? NEConversationListModel(),
              indexPath: indexPath
            )
          } else {
            self?.didAddStickTopSession(
              model: conversationModel ?? NEConversationListModel(),
              indexPath: indexPath
            )
          }
        }
      }
    }
  }

  /// 非置顶变为置顶
  ///  - Parameter conversation: 会话
  private func moveNormalConversationToTop(conversation: V2NIMConversation) {
    var addModel: NEConversationListModel?
    viewModel.conversationListData.removeAll(where: { model in
      if model.conversation?.conversationId == conversation.conversationId {
        addModel = model
        return true
      }
      return false
    })
    if let model = addModel {
      viewModel.stickTopConversations.append(model)
    }
  }

  /// 置顶变为非置顶
  ///  - Parameter conversation: 会话
  private func moveTopToNormalConversation(conversation: V2NIMConversation) {
    var addModel: NEConversationListModel?
    viewModel.stickTopConversations.removeAll(where: { model in
      if model.conversation?.conversationId == conversation.conversationId {
        addModel = model
        return true
      }
      return false
    })
    if let model = addModel {
      viewModel.conversationListData.append(model)
    }
  }

  /// 点击回调
  /// - Parameter conversation: 会话
  /// - Parameter indexPath: 索引
  /// - Parameter isTop: 置顶
  /// - Parameter completion: 完成回调
  func onTopRecentAtIndexPath(conversation: V2NIMConversation, indexPath: IndexPath,
                              isTop: Bool,
                              _ completion: @escaping (NSError?)
                                -> Void) {
    weak var weakSelf = self
    if isTop == true {
      viewModel.removeStickTop(conversation: conversation) { error in
        if let err = error {
          NEALog.errorLog(ModuleName + " " + (weakSelf?.className ?? "ConversationController"), desc: "CALLBACK removeStickTopSession failed，error = \(err)")
          completion(error)

          return
        } else {
          NEALog.infoLog(
            ModuleName + " " + (weakSelf?.className ?? "ConversationController"), desc: "✅CALLBACK removeStickTopSession SUCCESS"
          )
          weakSelf?.reloadTableView()
          completion(nil)
        }
      }

    } else {
      viewModel.addStickTop(conversation: conversation) { error in
        if let err = error {
          NEALog.errorLog(
            ModuleName + " " + (weakSelf?.className ?? "ConversationController"),
            desc: "CALLBACK addStickTopSession failed，error = \(err)"
          )
          completion(error)
          return
        } else {
          NEALog.infoLog(ModuleName + " " + (weakSelf?.className ?? "ConversationController"),
                         desc: "✅CALLBACK addStickTopSession callback SUCCESS")
          weakSelf?.reloadTableView()
          completion(nil)
        }
      }
    }
  }
}

// MARK: UI UIKit提供的重写方法

extension NEBaseConversationController {
  /// cell点击事件,可重写该事件处理自己的逻辑业务，例如跳转到指定的会话页面
  /// - Parameter conversation: 会话
  open func onselectedTableRow(conversation: V2NIMConversation) {
    let conversationId = conversation.conversationId

    let param = ["sessionId": conversationId]
    Router.shared.use("ClearAtMessageRemind", parameters: param, closure: nil)

    // 路由跳转到聊天页面
    if conversation.type == .CONVERSATION_TYPE_P2P {
      Router.shared.use(
        PushP2pChatVCRouter,
        parameters: ["nav": navigationController as Any, "conversationId": conversationId as Any],
        closure: nil
      )
    } else if conversation.type == .CONVERSATION_TYPE_TEAM {
      Router.shared.use(
        PushTeamChatVCRouter,
        parameters: ["nav": navigationController as Any, "conversationId": conversationId as Any],
        closure: nil
      )
    }
  }

  /// 删除会话
  ///   - parameter model: 会话模型
  ///   - parameter indexpath: 索引
  open func didDeleteConversationCell(model: NEConversationListModel, indexPath: IndexPath) {}

  /// 删除一条置顶记录
  ///   - parameter model: 会话模型
  ///   - parameter indexpath
  open func didRemoveStickTopSession(model: NEConversationListModel, indexPath: IndexPath) {}

  /// 添加一条置顶记录
  ///   - Parameter model: 会话模型
  ///   - Parameter indexpath: 索引
  open func didAddStickTopSession(model: NEConversationListModel, indexPath: IndexPath) {}
}

// MARK: ================= ConversationViewModelDelegate===================

extension NEBaseConversationController: ConversationViewModelDelegate {
  open func reloadData() {
    delegate?.onDataLoaded()
  }

  /// 带排序的刷新
  open func reloadTableView() {
    if viewModel.stickTopConversations.count <= 0, viewModel.conversationListData.count <= 0 {
      emptyView.isHidden = false
    } else {
      emptyView.isHidden = true
    }
    viewModel.conversationListData.sort()
    viewModel.stickTopConversations.sort()
    tableView.reloadData()
  }

  /// 由于数据变更可能导致底部有更多数据，此方法重新使列表加载更多能力开启
  public func loadMoreStateChange(_ finish: Bool) {
    if finish {
      tableView.mj_footer = nil
    } else {
      tableView.mj_footer = MJRefreshBackNormalFooter(
        refreshingTarget: self,
        refreshingAction: #selector(loadMoreData)
      )
    }
  }
}
