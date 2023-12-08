
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreKit
import NIMSDK
import UIKit

@objc
public protocol NEBaseConversationControllerDelegate {
  func onDataLoaded()
}

@objcMembers
open class NEBaseConversationController: UIViewController, NIMChatManagerDelegate {
  var className = "NEBaseConversationController"
  public var deleteBottonBackgroundColor: UIColor = NEConstant.hexRGB(0xA8ABB6)

  public var brokenNetworkViewHeight = 36.0
  private var bodyTopViewHeightAnchor: NSLayoutConstraint?
  private var bodyBottomViewHeightAnchor: NSLayoutConstraint?
  public var contentViewTopAnchor: NSLayoutConstraint?
  public var topConstant: CGFloat = 0
  public var popListController = NEBasePopListViewController()

  public var delegate: NEBaseConversationControllerDelegate?

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
  public let viewModel = ConversationViewModel()

  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    showTitleBar()
    viewModel.loadStickTopSessionInfos { [weak self] error, sessionInfos in
      NELog.infoLog(
        ModuleName + " " + (self?.className ?? "NEBaseConversationController"),
        desc: "CALLBACK loadStickTopSessionInfos " + (error?.localizedDescription ?? "no error")
      )
      if let infos = sessionInfos {
        self?.viewModel.stickTopInfos = infos
        self?.reloadTableView()
        self?.delegate?.onDataLoaded()
      }
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
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    showTitleBar()
    setupSubviews()
    requestData()
    initialConfig()
    NIMSDK.shared().chatManager.add(self)
  }

  override open func viewWillDisappear(_ animated: Bool) {
    popListController.removeSelf()
  }

  deinit {
    NIMSDK.shared().chatManager.remove(self)
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

    cellRegisterDic.forEach { (key: Int, value: NEBaseConversationListCell.Type) in
      tableView.register(value, forCellReuseIdentifier: "\(key)")
    }

    if let customController = NEKitConversationConfig.shared.ui.customController {
      customController(self)
    }
  }

  open func initialConfig() {
    viewModel.delegate = self
  }

  func requestData() {
    let params = NIMFetchServerSessionOption()
    params.minTimestamp = 0
    params.maxTimestamp = Date().timeIntervalSince1970 * 1000
    params.limit = 50
    weak var weakSelf = self
    viewModel.fetchServerSessions(option: params) { error, recentSessions in
      if error == nil {
        NELog.infoLog(ModuleName + " " + self.className, desc: "✅CALLBACK fetchServerSessions SUCCESS")
        if let recentList = recentSessions {
          NELog.infoLog(ModuleName + " " + self.className, desc: "✅CALLBACK fetchServerSessions SUCCESS count : \(recentList.count)")
          if recentList.count > 0 {
            weakSelf?.emptyView.isHidden = true
            weakSelf?.reloadTableView()
            weakSelf?.delegate?.onDataLoaded()
          } else {
            weakSelf?.emptyView.isHidden = false
          }
        }

      } else {
        NELog.errorLog(
          ModuleName + " " + self.className,
          desc: "❌CALLBACK fetchServerSessions failed，error = \(error!)"
        )
        weakSelf?.emptyView.isHidden = false
      }
    }
  }

  // MARK: lazyMethod

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
    return tableView
  }()

  public lazy var bodyBottomView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    return view
  }()
}

extension NEBaseConversationController: TabNavigationViewDelegate {
  /// 标题栏左侧按钮点击事件
  func brandBtnClick() {
    NEKitConversationConfig.shared.ui.titleBarLeftClick?()
  }

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

  open func getPopListController() -> NEBasePopListViewController {
    NEBasePopListViewController()
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

    if IMKitClient.instance.getConfigCenter().teamEnable {
      popListController.itemDatas = getPopListItems()
      popListController.view.frame = CGRect(origin: .zero, size: view.frame.size)
      popListController.removeSelf()
      view.addSubview(popListController.view)
    } else {
      Router.shared.use(
        ContactAddFriendRouter,
        parameters: ["nav": navigationController as Any],
        closure: nil
      )
    }
  }

  open func createDiscussGroup() {
    Router.shared.register(ContactSelectedUsersRouter) { param in
      print("user setting accids : ", param)
      Router.shared.use(TeamCreateDisuss, parameters: param, closure: nil)
    }
    Router.shared.use(
      ContactUserSelectRouter,
      parameters: ["nav": navigationController as Any, "limit": inviteNumberLimit],
      closure: nil
    )
    weak var weakSelf = self
    Router.shared.register(TeamCreateDiscussResult) { param in
      print("create discuss ", param)
      if let code = param["code"] as? Int, let teamid = param["teamId"] as? String,
         code == 0 {
        let session = weakSelf?.viewModel.repo.createTeamSession(teamid)
        Router.shared.use(
          PushTeamChatVCRouter,
          parameters: ["nav": weakSelf?.navigationController as Any,
                       "session": session as Any],
          closure: nil
        )
      } else if let msg = param["msg"] as? String {
        weakSelf?.showToast(msg)
      }
    }
  }

  open func createSeniorGroup() {
    Router.shared.register(ContactSelectedUsersRouter) { param in
      Router.shared.use(TeamCreateSenior, parameters: param, closure: nil)
    }
    Router.shared.use(
      ContactUserSelectRouter,
      parameters: ["nav": navigationController as Any, "limit": 200],
      closure: nil
    )
    weak var weakSelf = self
    Router.shared.register(TeamCreateSeniorResult) { param in
      print("create senior : ", param)
      if let code = param["code"] as? Int, let teamid = param["teamId"] as? String,
         code == 0 {
        let session = weakSelf?.viewModel.repo.createTeamSession(teamid)
        Router.shared.use(
          PushTeamChatVCRouter,
          parameters: ["nav": weakSelf?.navigationController as Any,
                       "session": session as Any],
          closure: nil
        )
      } else if let msg = param["msg"] as? String {
        weakSelf?.showToast(msg)
      }
    }
  }

  // MARK: =========================NIMChatManagerDelegate========================

  open func onRecvRevokeMessageNotification(_ notification: NIMRevokeMessageNotification) {
    guard let msg = notification.message else {
      return
    }
    saveRevokeMessage(msg) { error in
    }
  }

  open func saveRevokeMessage(_ message: NIMMessage, _ completion: @escaping (Error?) -> Void) {
    let messageNew = NIMMessage()
    messageNew.text = localizable("message_recalled")
    var muta = [String: Any]()
    muta[revokeLocalMessage] = true
//    if message.messageType == .text {
//      muta[revokeLocalMessageContent] = message.text
//    }
    messageNew.timestamp = message.timestamp
    messageNew.from = message.from
    messageNew.localExt = muta
    let setting = NIMMessageSetting()
    setting.shouldBeCounted = false
    setting.isSessionUpdate = false
    messageNew.setting = setting
    if let session = message.session {
      viewModel.repo.saveMessageToDB(messageNew, session, completion)
    }
  }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension NEBaseConversationController: UITableViewDelegate, UITableViewDataSource {
  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let count = viewModel.conversationListArray?.count ?? 0
    NELog.infoLog(ModuleName + " " + "ConversationController",
                  desc: "numberOfRowsInSection count : \(count)")
    return count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = viewModel.conversationListArray?[indexPath.row]
    let reusedId = "\(model?.customType ?? 0)"
    let cell = tableView.dequeueReusableCell(withIdentifier: reusedId, for: indexPath)

    if let c = cell as? NEBaseConversationListCell {
      c.topStickInfos = viewModel.stickTopInfos
      c.configData(sessionModel: model)
    }

    return cell
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let conversationModel = viewModel.conversationListArray?[indexPath.row]

    if let didClick = NEKitConversationConfig.shared.ui.itemClick {
      didClick(conversationModel, indexPath)
      return
    }

    let sid = conversationModel?.recentSession?.session?.sessionId ?? ""
    let sessionType = conversationModel?.recentSession?.session?.sessionType ?? .P2P
    onselectedTableRow(sessionType: sessionType, sessionId: sid, indexPath: indexPath)
  }

  open func tableView(_ tableView: UITableView,
                      editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    weak var weakSelf = self
    var rowActions = [UITableViewRowAction]()

    let conversationModel = weakSelf?.viewModel.conversationListArray?[indexPath.row]
    guard let recentSession = conversationModel?.recentSession,
          let session = recentSession.session else {
      return rowActions
    }

    let deleteAction = UITableViewRowAction(style: .destructive,
                                            title: NEKitConversationConfig.shared.ui.deleteBottonTitle) { action, indexPath in
      weakSelf?.deleteActionHandler(action: action, indexPath: indexPath)
    }

    // 置顶和取消置顶
    let isTop = viewModel.stickTopInfos[session] != nil
    let topAction = UITableViewRowAction(style: .destructive,
                                         title: isTop ? NEKitConversationConfig.shared.ui.stickTopBottonCancelTitle :
                                           NEKitConversationConfig.shared.ui.stickTopBottonTitle) { action, indexPath in
      weakSelf?.topActionHandler(action: action, indexPath: indexPath, isTop: isTop)
    }
    deleteAction.backgroundColor = NEKitConversationConfig.shared.ui.deleteBottonBackgroundColor ?? deleteBottonBackgroundColor
    topAction.backgroundColor = NEKitConversationConfig.shared.ui.stickTopBottonBackgroundColor ?? NEConstant.hexRGB(0x337EFF)
    rowActions.append(deleteAction)
    rowActions.append(topAction)

    return rowActions
  }

  /*
   @available(iOS 11.0, *)
   public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

   var rowActions = [UIContextualAction]()

   let deleteAction = UIContextualAction(style: .normal, title: "删除") { (action, sourceView, completionHandler) in

   //            self.dataSource.remove(at: indexPath.row)
   //            tableView.deleteRows(at: [indexPath], with: .automatic)
   // 需要返回true，否则没有反应
   completionHandler(true)
   }
   deleteAction.backgroundColor = NEConstant.hexRGB(0xA8ABB6)
   rowActions.append(deleteAction)

   let topAction = UIContextualAction(style: .normal, title: "置顶") { (action, sourceView, completionHandler) in

   //            self.dataSource.remove(at: indexPath.row)
   //            tableView.deleteRows(at: [indexPath], with: .automatic)
   // 需要返回true，否则没有反应
   completionHandler(true)
   }
   topAction.backgroundColor = NEConstant.hexRGB(0x337EFF)
   rowActions.append(topAction)

   let actionConfig = UISwipeActionsConfiguration.init(actions: rowActions)
   actionConfig.performsFirstActionWithFullSwipe = false

   return actionConfig
   }
   */

  open func deleteActionHandler(action: UITableViewRowAction?, indexPath: IndexPath) {
    let conversationModel = viewModel.conversationListArray?[indexPath.row]

    if let deleteBottonClick = NEKitConversationConfig.shared.ui.deleteBottonClick {
      deleteBottonClick(conversationModel, indexPath)
      return
    }

    if let recentSession = conversationModel?.recentSession {
      viewModel.deleteRecentSession(recentSession: recentSession)
      didDeleteConversationCell(
        model: conversationModel ?? ConversationListModel(),
        indexPath: indexPath
      )
    }
  }

  open func topActionHandler(action: UITableViewRowAction?, indexPath: IndexPath, isTop: Bool) {
    if !NEChatDetectNetworkTool.shareInstance.isNetworkRecahability() {
      showToast(localizable("network_error"))
      return
    }
    let conversationModel = viewModel.conversationListArray?[indexPath.row]

    if let stickTopBottonClick = NEKitConversationConfig.shared.ui.stickTopBottonClick {
      stickTopBottonClick(conversationModel, indexPath)
      return
    }

    if let recentSession = conversationModel?.recentSession {
      onTopRecentAtIndexPath(
        rencent: recentSession,
        indexPath: indexPath,
        isTop: isTop
      ) { [weak self] error, sessionInfo in
        if error == nil {
          if isTop {
            self?.didRemoveStickTopSession(
              model: conversationModel ?? ConversationListModel(),
              indexPath: indexPath
            )
          } else {
            self?.didAddStickTopSession(
              model: conversationModel ?? ConversationListModel(),
              indexPath: indexPath
            )
          }
        }
      }
    }
  }

  private func onTopRecentAtIndexPath(rencent: NIMRecentSession, indexPath: IndexPath,
                                      isTop: Bool,
                                      _ completion: @escaping (NSError?, NIMStickTopSessionInfo?)
                                        -> Void) {
    guard let session = rencent.session else {
      NELog.errorLog(ModuleName + " " + className, desc: "❌session is nil")
      return
    }
    weak var weakSelf = self
    if isTop {
      guard let params = viewModel.stickTopInfos[session] else {
        return
      }

      viewModel.removeStickTopSession(params: params) { error, topSessionInfo in
        if let err = error {
          NELog.errorLog(
            ModuleName + " " + (weakSelf?.className ?? "ConversationController"),
            desc: "❌CALLBACK removeStickTopSession failed，error = \(err)"
          )
          completion(error as NSError?, nil)

          return
        } else {
          NELog.infoLog(
            ModuleName + " " + (weakSelf?.className ?? "ConversationController"),
            desc: "✅CALLBACK removeStickTopSession SUCCESS"
          )
          weakSelf?.viewModel.stickTopInfos[session] = nil
          weakSelf?.viewModel.sortRecentSession()
          weakSelf?.tableView.reloadData()
          completion(nil, topSessionInfo)
        }
      }

    } else {
      viewModel.addStickTopSession(session: session) { error, newInfo in
        if let err = error {
          NELog.errorLog(
            ModuleName + " " + (weakSelf?.className ?? "ConversationController"),
            desc: "❌CALLBACK addStickTopSession failed，error = \(err)"
          )
          completion(error as NSError?, nil)
          return
        } else {
          NELog.infoLog(ModuleName + " " + (weakSelf?.className ?? "ConversationController"),
                        desc: "✅CALLBACK addStickTopSession callback SUCCESS")
          weakSelf?.viewModel.stickTopInfos[session] = newInfo
          weakSelf?.viewModel.sortRecentSession()
          weakSelf?.tableView.reloadData()
          completion(nil, newInfo)
        }
      }
    }
  }
}

// MARK: UI UIKit提供的重写方法

extension NEBaseConversationController {
  /// cell点击事件,可重写该事件处理自己的逻辑业务，例如跳转到指定的会话页面
  /// - Parameters:
  ///   - sessionType: 会话类型
  ///   - sessionId: 会话id
  ///   - indexPath: indexpath
  open func onselectedTableRow(sessionType: NIMSessionType, sessionId: String,
                               indexPath: IndexPath) {
    if sessionType == .P2P {
      let session = NIMSession(sessionId, type: .P2P)
      Router.shared.use(
        PushP2pChatVCRouter,
        parameters: ["nav": navigationController as Any, "session": session as Any],
        closure: nil
      )
    } else if sessionType == .team {
      let session = NIMSession(sessionId, type: .team)
      Router.shared.use(
        PushTeamChatVCRouter,
        parameters: ["nav": navigationController as Any, "session": session as Any],
        closure: nil
      )
    }
  }

  /// 删除会话
  /// - Parameters:
  ///   - model: 会话模型
  ///   - indexPath: indexpath
  open func didDeleteConversationCell(model: ConversationListModel, indexPath: IndexPath) {}

  /// 删除一条置顶记录
  /// - Parameters:
  ///   - model: 会话模型
  ///   - indexPath: indexpath
  open func didRemoveStickTopSession(model: ConversationListModel, indexPath: IndexPath) {}

  /// 添加一条置顶记录
  /// - Parameters:
  ///   - model: 会话模型
  ///   - indexPath: indexpath
  open func didAddStickTopSession(model: ConversationListModel, indexPath: IndexPath) {}
}

// MARK: ================= ConversationViewModelDelegate===================

extension NEBaseConversationController: ConversationViewModelDelegate {
  open func didAddRecentSession() {
    NELog.infoLog("ConversationController", desc: "didAddRecentSession")
    emptyView.isHidden = (viewModel.conversationListArray?.count ?? 0) > 0
    viewModel.sortRecentSession()
    tableView.reloadData()
  }

  open func didUpdateRecentSession(index: Int) {
    let indexPath = IndexPath(row: index, section: 0)
    tableView.reloadRows(at: [indexPath], with: .none)
  }

  open func reloadData() {
    delegate?.onDataLoaded()
  }

  open func reloadTableView() {
    emptyView.isHidden = (viewModel.conversationListArray?.count ?? 0) > 0
    viewModel.sortRecentSession()
    tableView.reloadData()
  }
}
