
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import AVFoundation
import MJRefresh
import NEChatKit
import NECommonKit
import NECommonUIKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK
import Photos
import UIKit
import WebKit

@objcMembers
open class ChatViewController: ChatBaseViewController, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UIDocumentPickerDelegate, UIDocumentInteractionControllerDelegate, NIMMediaManagerDelegate, CLLocationManagerDelegate, UITextViewDelegate, ChatInputViewDelegate, ChatInputMultilineDelegate, ChatViewModelDelegate, MessageOperationViewDelegate, NEContactListener {
  private let kCallKitDismissNoti = "kCallKitDismissNoti"
  private let kCallKitShowNoti = "kCallKitShowNoti"
  public var titleContent = ""

  public var viewModel: ChatViewModel = .init()
  let interactionController = UIDocumentInteractionController()
  private lazy var manager = CLLocationManager()
  private var playingCell: ChatAudioCellProtocol?
  private var playingModel: MessageAudioModel?
  private var timer: Timer?
  private var isFile: Bool? // 是否以文件形式发送
  public var isCurrentPage = true
  public var isMute = false // 是否禁言
  private var isMutilSelect = false // 是否多选模式
  private var isUploadingData = false // 是否正在加载数据(上拉)
  private var uploadHasNoMore = false // 上拉无更多数据

  public var operationCellFilter: [OperationType]? // 消息长按菜单全局过滤列表
  public var cellRegisterDic = [String: UITableViewCell.Type]()
  private var needMarkReadMsgs = [V2NIMMessage]()
  private var atUsers = [NSRange]()

  var replyView = ReplyView()
  public var operationView: MessageOperationView?

  public var normalOffset: CGFloat = 0
  public var bottomExanpndHeight: CGFloat = 204 // 底部展开高度
  public var normalInputHeight: CGFloat = 100
  public var brokenNetworkViewHeight: CGFloat = 36
  public lazy var bodyTopViewHeight: CGFloat = 0 {
    didSet {
      bodyTopViewHeightAnchor?.constant = bodyTopViewHeight
      bodyTopView.isHidden = bodyTopViewHeight <= 0
    }
  }

  public lazy var bodyBottomViewHeight: CGFloat = 0 {
    didSet {
      bodyBottomViewHeightAnchor?.constant = bodyBottomViewHeight
      bodyBottomView.isHidden = bodyBottomViewHeight <= 0
    }
  }

  public lazy var bottomViewHeight: CGFloat = 404 {
    didSet {
      bottomViewHeightAnchor?.constant = bottomViewHeight
    }
  }

  public var currentKeyboardHeight: CGFloat = 0

  public var bodyTopViewHeightAnchor: NSLayoutConstraint?
  public var bodyBottomViewHeightAnchor: NSLayoutConstraint?
  public var contentViewTopAnchor: NSLayoutConstraint?
  public var bottomViewTopAnchor: NSLayoutConstraint?
  public var bottomViewHeightAnchor: NSLayoutConstraint?

  public init(conversationId: String) {
    super.init(nibName: nil, bundle: nil)

    NEKeyboardManager.shared.enable = false
    NEKeyboardManager.shared.enableAutoToolbar = false
    NIMSDK.shared().mediaManager.add(self)
    ContactRepo.shared.addContactListener(self)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  deinit {
    NEALog.infoLog(className(), desc: "deinit")
    viewModel.clearUnreadCount()
    cleanDelegate()
  }

  func cleanDelegate() {
    NIMSDK.shared().mediaManager.remove(self)
    viewModel.delegate = nil
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    NEKeyboardManager.shared.enable = false
    NEKeyboardManager.shared.shouldResignOnTouchOutside = false
    isCurrentPage = true
    markNeedReadMsg()
    clearAtRemind()

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
    viewModel.delegate = self
    commonUI()
    addObseve()
    weak var weakSelf = self
    getSessionInfo(sessionId: viewModel.sessionId) {
      weakSelf?.loadData()
    }
    Router.shared.register(NERouterUrl.LocationSearchResult) { result in
      if let model = ChatLocaitonModel.yx_model(with: result) {
        weakSelf?.viewModel.sendLocationMessage(model: model) { error in
          weakSelf?.showErrorToast(error)
        }
      }
    }
  }

  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    NEKeyboardManager.shared.enable = true
    NEKeyboardManager.shared.shouldResignOnTouchOutside = true
    isCurrentPage = false
    operationView?.removeFromSuperview()
    if NIMSDK.shared().mediaManager.isPlaying() {
      NIMSDK.shared().mediaManager.stopPlay()
    }

    clearAtRemind()
    chatInputView.textView.resignFirstResponder()
    chatInputView.titleField.resignFirstResponder()
  }

  override open func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    stopPlay()
  }

  open func setMoreButton() {
    if NEKitChatConfig.shared.ui.messageProperties.showTitleBarRightIcon {
      let image = NEKitChatConfig.shared.ui.messageProperties.titleBarRightRes ?? UIImage.ne_imageNamed(name: "three_point")
      addRightAction(image, #selector(toSetting), self)
      navigationView.setMoreButtonImage(image)
    } else {
      navigationView.moreButton.isHidden = true
    }
  }

  open func commonUI() {
    title = viewModel.sessionId
    navigationView.titleBarBottomLine.isHidden = false
    setMoreButton()
    setMutilSelectBottomView()

    view.addSubview(bodyTopView)
    view.addSubview(bodyView)
    view.addSubview(bodyBottomView)
    view.addSubview(bottomView)

    var bodyTopViewTopConstant: CGFloat = 0
    if #available(iOS 10, *) {
      bodyTopViewTopConstant += KStatusBarHeight
    }
    if NEKitChatConfig.shared.ui.messageProperties.showTitleBar {
      bodyTopViewTopConstant += kNavigationHeight
    }
    bodyTopViewHeightAnchor = bodyTopView.heightAnchor.constraint(equalToConstant: bodyTopViewHeight)
    bodyTopViewHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      bodyTopView.topAnchor.constraint(equalTo: view.topAnchor, constant: bodyTopViewTopConstant),
      bodyTopView.leftAnchor.constraint(equalTo: view.leftAnchor),
      bodyTopView.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])

    bottomViewTopAnchor = bottomView.topAnchor.constraint(equalTo: view.bottomAnchor, constant: -normalInputHeight)
    bottomViewTopAnchor?.isActive = true
    bottomViewHeightAnchor = bottomView.heightAnchor.constraint(equalToConstant: bottomViewHeight)
    bottomViewHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      bottomView.leftAnchor.constraint(equalTo: view.leftAnchor),
      bottomView.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])

    bodyBottomViewHeightAnchor = bodyBottomView.heightAnchor.constraint(equalToConstant: bodyBottomViewHeight)
    bodyBottomViewHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      bodyBottomView.bottomAnchor.constraint(equalTo: bottomView.topAnchor),
      bodyBottomView.leftAnchor.constraint(equalTo: view.leftAnchor),
      bodyBottomView.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])

    NSLayoutConstraint.activate([
      bodyView.topAnchor.constraint(equalTo: bodyTopView.bottomAnchor),
      bodyView.leftAnchor.constraint(equalTo: view.leftAnchor),
      bodyView.rightAnchor.constraint(equalTo: view.rightAnchor),
      bodyView.bottomAnchor.constraint(equalTo: bodyBottomView.topAnchor),
    ])

    tableView.register(
      NEBaseChatMessageCell.self,
      forCellReuseIdentifier: "\(NEBaseChatMessageCell.self)"
    )

    for (key, value) in NEChatUIKitClient.instance.getRegisterCustomCell() {
      cellRegisterDic[key] = value
    }

    for (key, value) in cellRegisterDic {
      tableView.register(value, forCellReuseIdentifier: key)
    }

    expandMoreAction()

    if let customController = NEKitChatConfig.shared.ui.customController {
      customController(self)
    }
  }

  // MARK: 子类可重写方法

  public func onTeamMemberChange(team: V2NIMTeam) {}

  override open func backEvent() {
    super.backEvent()
    cleanDelegate()
  }

  // load data的时候会调用
  open func getSessionInfo(sessionId: String, _ completion: @escaping () -> Void) {
    if viewModel.getShowName(IMKitClient.instance.account()).user == nil {
      ContactRepo.shared.getMyUserInfo { _ in
        completion()
      }
    } else {
      completion()
    }
  }

  /// 点击头像回调
  /// - Parameter model: cell模型
  open func didTapHeadPortrait(model: MessageContentModel?) {
    if let isOut = model?.message?.isSelf, isOut {
      Router.shared.use(
        MeSettingRouter,
        parameters: ["nav": navigationController as Any],
        closure: nil
      )
      return
    }
    if let uid = model?.message?.senderId {
      Router.shared.use(
        ContactUserInfoPageRouter,
        parameters: ["nav": navigationController as Any, "uid": uid],
        closure: nil
      )
    }
  }

  open func setOperationItems(items: inout [OperationItem], model: MessageContentModel?) {}

  /// 长按消息内容
  /// - Parameters:
  ///   - cell: 长按cell
  ///   - model: cell模型
  open func didLongTouchMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    if model?.isRevoked == true {
      return
    }

    // 多选模式下屏蔽消息长按事件
    if isMutilSelect {
      return
    }

    // 底部收起
    if chatInputView.textView.isFirstResponder || chatInputView.titleField.isFirstResponder {
      chatInputView.textView.resignFirstResponder()
      chatInputView.titleField.resignFirstResponder()
      layoutInputView(offset: 0)
    }

    operationView?.removeFromSuperview()

    // get operations
    guard let items = viewModel.avalibleOperationsForMessage(model) else {
      return
    }

    var filterItems = items
    if let filter = operationCellFilter {
      filterItems = items.filter { item in
        if let type = item.type {
          return !filter.contains(type)
        }
        return true
      }
    }

    // 配置项自定义 items
    if let chatPopMenu = NEKitChatConfig.shared.ui.chatPopMenu {
      chatPopMenu(&filterItems, model)
    }

    // 供用户自定义 items
    setOperationItems(items: &filterItems, model: model)

    viewModel.operationModel = model
    guard let index = tableView.indexPath(for: cell) else { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: DispatchWorkItem(block: { [self] in
      //        size
      let w = filterItems.count <= 5 ? 60.0 * Double(filterItems.count) + 16.0 : 60.0 * 5 + 16.0
      let h = filterItems.count <= 5 ? 56.0 + 16.0 : 56.0 * 2 + 16.0

      let rectInTableView = tableView.rectForRow(at: index)
      let rectInView = tableView.convert(rectInTableView, to: view)
      let topOffset = NEConstant.navigationAndStatusHeight
      var operationY = 0.0
      if topOffset + h + bodyTopViewHeight > rectInView.origin.y {
        // under the cell
        operationY = rectInView.origin.y + rectInView.size.height
      } else {
        operationY = rectInView.origin.y - h
      }
      var frameX = 0.0
      if let msg = model?.message,
         msg.isSelf {
        frameX = kScreenWidth - w
      }
      var frame = CGRect(x: frameX, y: operationY, width: w, height: h)
      if frame.origin.y + h < tableView.frame.origin.y {
        frame.origin.y = tableView.frame.origin.y
      } else if frame.origin.y + h > view.frame.size.height {
        frame.origin.y = tableView.frame.origin.y + tableView.frame.size.height - h
      }

      operationView = MessageOperationView(frame: frame)
      operationView!.delegate = self
      operationView!.items = filterItems
      view.addSubview(operationView!)
    }))
  }

  // MARK: lazy Method

  public lazy var bodyTopView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.clear
    return view
  }()

  public lazy var bodyView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.clear
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
    let contentView = UIView()
    contentView.translatesAutoresizingMaskIntoConstraints = false
    contentView.backgroundColor = UIColor.clear
    contentView.addSubview(tableView)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: contentView.topAnchor),
      tableView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    return contentView
  }()

  public lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.showsVerticalScrollIndicator = false
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = .clear
    tableView.mj_header = MJRefreshNormalHeader(
      refreshingTarget: self,
      refreshingAction: #selector(loadMoreData)
    )
    tableView.keyboardDismissMode = .onDrag
    return tableView
  }()

  public lazy var bodyBottomView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.clear
    return view
  }()

  public lazy var bottomView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.clear

    view.addSubview(chatInputView)
    NSLayoutConstraint.activate([
      chatInputView.leftAnchor.constraint(equalTo: view.leftAnchor),
      chatInputView.rightAnchor.constraint(equalTo: view.rightAnchor),
      chatInputView.heightAnchor.constraint(equalToConstant: 404),
      chatInputView.topAnchor.constraint(equalTo: view.topAnchor),
    ])

    view.addSubview(mutilSelectBottomView)
    NSLayoutConstraint.activate([
      mutilSelectBottomView.leftAnchor.constraint(equalTo: view.leftAnchor),
      mutilSelectBottomView.rightAnchor.constraint(equalTo: view.rightAnchor),
      mutilSelectBottomView.heightAnchor.constraint(equalToConstant: 304),
      mutilSelectBottomView.topAnchor.constraint(equalTo: view.topAnchor),
    ])

    return view
  }()

  public lazy var chatInputView: NEBaseChatInputView = {
    let inputView = getMenuView()
    inputView.translatesAutoresizingMaskIntoConstraints = false
    inputView.backgroundColor = .ne_backgroundColor
    inputView.delegate = self
    return inputView
  }()

  public lazy var mutilSelectBottomView: NEMutilSelectBottomView = {
    let view = NEMutilSelectBottomView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.delegate = self
    view.isHidden = true
    return view
  }()

  // MARK: UIGestureRecognizerDelegate

  open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                              shouldReceive touch: UITouch) -> Bool {
    guard let view = touch.view else {
      return true
    }

    // 点击重发按钮
    // 点击撤回重新编辑按钮
    if view.isKind(of: UIButton.self) {
      return false
    }

    // 回复消息view
    // 已读未读按钮
    // 消息操作按钮（撤回、删除）
    // 地图view
    // 文件消息图标
    if view.accessibilityIdentifier == "id.replyTextView" ||
      view.accessibilityIdentifier == "id.readView" ||
      view.accessibilityIdentifier == "id.menuCell" ||
      view.accessibilityIdentifier == "id.mapView" ||
      view.accessibilityIdentifier == "id.fileStatus" {
      return false
    }

    return true
  }

  open func remoteUserEditing() {
    title = chatLocalizable("editing")
    trigerEndTimer()
  }

  open func remoteUserEndEditing() {
    title = titleContent
  }

  func timeoutEndEditing() {
    remoteUserEndEditing()
  }

  func trigerEndTimer() {
    if let t = timer, t.isValid == true {
      t.invalidate()
      timer = nil
    }
    timer = Timer.scheduledTimer(
      timeInterval: 3,
      target: self,
      selector: #selector(timeoutEndEditing),
      userInfo: nil,
      repeats: false
    )
  }

  // MARK: objc 方法

  func getUserSettingViewController() -> NEBaseUserSettingViewController {
    UserSettingViewController(userId: viewModel.sessionId)
  }

  /// 设置按钮点击事件
  override open func toSetting() {
    // 自定义设置按钮点击事件
    if let block = NEKitChatConfig.shared.ui.messageProperties.titleBarRightClick {
      block()
      return
    }

    // 多选模式下屏蔽设置按钮点击事件
    if isMutilSelect {
      return
    }

    if V2NIMConversationIdUtil.conversationType(viewModel.conversationId) == .CONVERSATION_TYPE_TEAM {
      Router.shared.use(
        TeamSettingViewRouter,
        parameters: ["nav": navigationController as Any,
                     "teamid": viewModel.sessionId as Any],
        closure: nil
      )
    } else if V2NIMConversationIdUtil.conversationType(viewModel.conversationId) == .CONVERSATION_TYPE_P2P {
      let userSetting = getUserSettingViewController()
      navigationController?.pushViewController(userSetting, animated: true)
    }
  }

  open func viewTap(tap: UITapGestureRecognizer) {
    if isMutilSelect {
      return
    }

    if let opeView = operationView,
       view.subviews.contains(opeView) {
      opeView.removeFromSuperview()

    } else {
      if chatInputView.textView.isFirstResponder || chatInputView.titleField.isFirstResponder {
        chatInputView.textView.resignFirstResponder()
        chatInputView.titleField.resignFirstResponder()
      } else {
        if tap.location(in: view).y < kScreenHeight - bottomExanpndHeight {
          layoutInputView(offset: 0)
        }
      }
    }
  }

  // MARK: private 方法

  func loadData() {
    weak var weakSelf = self

    // 多端登录清空未读数
    viewModel.clearUnreadCount()

    viewModel.loadData { error, historyEnd, newEnd, index in
      NEALog.infoLog(
        ModuleName + " " + ChatViewController.className(),
        desc: #function + "CALLBACK loadData " + (error?.localizedDescription ?? "no error")
      )

      if let ms = weakSelf?.viewModel.messages, ms.count > 0 {
        weakSelf?.tableViewReload()
        if weakSelf?.viewModel.isHistoryChat == true,
           let num = weakSelf?.tableView.numberOfRows(inSection: 0),
           index < num, index >= 0 {
          let indexPath = IndexPath(row: index, section: 0)
          weakSelf?.tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
          if newEnd > 0 {
            weakSelf?.addBottomLoadMore()
          }
        } else {
          if let last = weakSelf?.tableView.numberOfRows(inSection: 0) {
            let indexPath = IndexPath(row: last - 1, section: 0)
            weakSelf?.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
          }
        }
      } else if let err = error {
        weakSelf?.showErrorToast(err)
      }
      weakSelf?.loadDataFinish()
    }
  }

  func loadMoreData() {
    weak var weakSelf = self
    viewModel.dropDownRemoteRefresh { error, count, messages in
      NEALog.infoLog(
        ModuleName + " " + ChatViewController.className(),
        desc: #function + "CALLBACK dropDownRemoteRefresh " + (error?.localizedDescription ?? "no error")
      )

      weakSelf?.tableView.reloadData()
      if count > 0, let num = weakSelf?.tableView.numberOfRows(inSection: 0), count <= num {
        weakSelf?.tableView.scrollToRow(
          at: IndexPath(row: count - 1, section: 0),
          at: .top,
          animated: false
        )
      }
      weakSelf?.tableView.mj_header?.endRefreshing()
    }
  }

  func loadFartherToNowData() {}

  func loadCloserToNowData() {
    weak var weakSelf = self
    viewModel.pullRemoteRefresh { error, count, datas in
      NEALog.infoLog(
        ModuleName + " " + ChatViewController.className(),
        desc: #function + "CALLBACK pullRemoteRefresh " + (error?.localizedDescription ?? "no error")
      )
      if count <= 0 {
        weakSelf?.removeBottomLoadMore()
      } else {
        weakSelf?.tableView.mj_footer?.endRefreshing()
        weakSelf?.tableViewReload()
      }
    }
  }

  func addObseve() {
    NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

    NotificationCenter.default.addObserver(self, selector: #selector(appEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(appEnterForegournd), name: UIApplication.willEnterForegroundNotification, object: nil)

    NotificationCenter.default.addObserver(self, selector: #selector(didShowCallView), name: Notification.Name(kCallKitShowNoti), object: nil)

    let tap = UITapGestureRecognizer(target: self, action: #selector(viewTap))
    tap.delegate = self
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)

    if let pan = navigationController?.interactivePopGestureRecognizer {
      tableView.panGestureRecognizer.require(toFail: pan)
    }
  }

  open func addBottomLoadMore() {
    let footer = MJRefreshAutoFooter(
      refreshingTarget: self,
      refreshingAction: #selector(loadCloserToNowData)
    )
    footer.triggerAutomaticallyRefreshPercent = -10
    tableView.mj_footer = footer
  }

  open func removeBottomLoadMore() {
    tableView.mj_footer?.endRefreshingWithNoMoreData()
    tableView.mj_footer = nil
    viewModel.isHistoryChat = false // 转为普通聊天页面
  }

  func markNeedReadMsg() {
    if isCurrentPage, needMarkReadMsgs.count > 0 {
      viewModel.markRead(messages: needMarkReadMsgs) { error in
        NEALog.infoLog(
          ModuleName + " " + ChatViewController.className(),
          desc: #function + "CALLBACK markRead " + (error?.localizedDescription ?? "no error")
        )
      }
      needMarkReadMsgs = [V2NIMMessage]()
    }
  }

  func appEnterBackground() {
    isCurrentPage = false
  }

  func appEnterForegournd() {
    isCurrentPage = true
    markNeedReadMsg()
  }

  //    MARK: 键盘通知相关操作

  open func keyBoardWillShow(_ notification: Notification) {
    if !isCurrentPage {
      return
    }
    operationView?.removeFromSuperview()
    if chatInputView.currentType != .text {
      return
    }
    chatInputView.currentButton?.isSelected = false

    chatInputView.contentSubView?.isHidden = true
    let oldKeyboardRect = (notification
      .userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue

    let keyboardRect = (notification
      .userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
    var animationDuration: TimeInterval = 0.1

    if let userInfo = notification.userInfo,
       let keyboardAnimationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval {
      animationDuration = keyboardAnimationDuration
    }

    // oldKeyboardRect == keyboardRect 说明键盘已经弹出，无需重复滚动
    layoutInputViewWithAnimation(offset: keyboardRect.size.height, animationDuration, oldKeyboardRect != keyboardRect)
  }

  open func keyBoardWillHide(_ notification: Notification) {
    if chatInputView.currentType != .text {
      return
    }
    chatInputView.currentButton?.isSelected = false
    var animationDuration: TimeInterval = 0.1

    if let userInfo = notification.userInfo,
       let keyboardAnimationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval {
      animationDuration = keyboardAnimationDuration
    }
    layoutInputViewWithAnimation(offset: 0, animationDuration)
  }

  private func scrollTableViewToBottom() {
    NEALog.infoLog(className(), desc: "self.viewModel.messages.count\(viewModel.messages.count)")
    NEALog.infoLog(className(), desc: "self.tableView.numberOfRows(inSection: 0)\(tableView.numberOfRows(inSection: 0))")
    let row = tableView.numberOfRows(inSection: 0)
    if row > 0 {
      let indexPath = IndexPath(row: row - 1, section: 0)
      tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
  }

  open func layoutInputView(offset: CGFloat, _ scrollToBottom: Bool = false) {
    layoutInputViewWithAnimation(offset: offset, 0.1, scrollToBottom)
  }

  open func layoutInputViewWithAnimation(offset: CGFloat, _ animation: CGFloat = 0.1, _ scrollToBottom: Bool = false) {
    NEALog.infoLog(className(), desc: "normal height : \(normalInputHeight) normal offset: \(normalOffset) offset : \(offset)")
    weak var weakSelf = self
    var topValue = normalInputHeight
    if chatInputView.chatInpuMode != .multipleReturn {
      topValue -= normalOffset
    }
    if offset == 0 {
      chatInputView.contentSubView?.isHidden = true
      chatInputView.currentButton?.isSelected = false
    }

    UIView.animate(withDuration: animation) {
      weakSelf?.bottomViewTopAnchor?.constant = -topValue - offset
      if scrollToBottom {
        weakSelf?.view.layoutIfNeeded()
        weakSelf?.scrollTableViewToBottom()
      }
    }
  }

  //    MARK: ChatInputViewDelegate

  open func sendText(text: String?, attribute: NSAttributedString?) {
    if let title = chatInputView.titleField.text, title.trimmingCharacters(in: .whitespaces).isEmpty == false {
      // 换行消息
      NEALog.infoLog(className(), desc: "换行消息: \(title)")
      var dataDic = [String: Any]()
      dataDic["title"] = title
      if let t = text?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty {
        dataDic["body"] = text
      }

      var attachDic = [String: Any]()
      attachDic["type"] = customRichTextType
      attachDic["data"] = dataDic

      let rawAttachment = getJSONStringFromDictionary(attachDic)
      let customMessage = MessageUtils.customMessage(text: title, rawAttachment: rawAttachment)
      if let remoteExt = chatInputView.getRemoteExtension(attribute) {
        customMessage.serverExtension = getJSONStringFromDictionary(remoteExt)
      }

      if viewModel.isReplying, let msg = viewModel.operationModel?.message {
        viewModel.replyMessageWithoutThread(message: customMessage,
                                            target: msg) { [weak self] error in
          NEALog.infoLog(
            ModuleName + " " + ChatViewController.className(),
            desc: #function + "CALLBACK replyMessage " + (error?.localizedDescription ?? "no error")
          )
          if error != nil {
            self?.showErrorToast(error)
          }
          self?.chatInputView.titleField.text = nil
          self?.chatInputView.textView.text = nil
          self?.didSendFinishAndCheckoutInput()
        }
        closeReply(button: nil)
      } else {
        viewModel.sendMessage(message: customMessage) { [weak self] error in
          self?.showErrorToast(error)
          self?.chatInputView.titleField.text = nil
          self?.chatInputView.textView.text = nil
          self?.didSendFinishAndCheckoutInput()
        }
      }
    } else {
      // 文本消息
      sendContentText(text: text, attribute: attribute)
    }
  }

  func sendContentText(text: String?, attribute: NSAttributedString?) {
    guard let removeSpace = text?.trimmingCharacters(in: .whitespaces), removeSpace.count > 0 else {
      chatInputView.titleField.text = nil
      view.makeToast(chatLocalizable("null_message_not_support"), position: .center)
      return
    }
    guard let content = text, content.count > 0 else {
      return
    }
    let remoteExt = chatInputView.getRemoteExtension(attribute)
    chatInputView.cleartAtCache()

    if viewModel.isReplying, let msg = viewModel.operationModel?.message {
      viewModel.replyMessageWithoutThread(message: MessageUtils.textMessage(text: content, remoteExt: remoteExt), target: msg) { [weak self] error in
        NEALog.infoLog(
          ModuleName + " " + ChatViewController.className(),
          desc: #function + "CALLBACK replyMessage " + (error?.localizedDescription ?? "no error")
        )
        if error != nil {
          self?.showErrorToast(error)
        }
        self?.didSendFinishAndCheckoutInput()
      }
      closeReply(button: nil)
    } else {
      viewModel.sendTextMessage(text: content, remoteExt: remoteExt) { [weak self] error in
        NEALog.infoLog(
          ModuleName + " " + ChatViewController.className(),
          desc: #function + "CALLBACK sendTextMessage " + (error?.localizedDescription ?? "no error")
        )
        self?.showErrorToast(error)
        self?.chatInputView.titleField.text = nil
        self?.chatInputView.textView.text = nil
        self?.didSendFinishAndCheckoutInput()
      }
    }
  }

  open func didSelectMoreCell(cell: NEInputMoreCell) {
    if let delegate = cell.cellData?.customDelegate as? AnyObject, let action = cell.cellData?.action {
      // 用户自定义更多面板按钮
      _ = delegate.perform(action)
      return
    }

    if let type = cell.cellData?.type, type == .location {
      if #available(iOS 14.0, *) {
        if manager.authorizationStatus == .denied {
          showSingleAlert(message: commonLocalizable("jump_location_setting")) {}
          return
        } else if manager.authorizationStatus == .notDetermined {
          manager.delegate = self
          manager.requestAlwaysAuthorization()
          manager.requestWhenInUseAuthorization()
          return
        }
      } else {
        if CLLocationManager.authorizationStatus() == .denied {
          showSingleAlert(message: commonLocalizable("jump_location_setting")) {}
          return
        } else if CLLocationManager.authorizationStatus() == .notDetermined {
          manager.delegate = self
          manager.requestAlwaysAuthorization()
          manager.requestWhenInUseAuthorization()
          return
        }
      }

      didToSearchLocationView()

    } else if let type = cell.cellData?.type, type == .takePicture {
      isFile = false
      showTakePicture()
    } else if let type = cell.cellData?.type, type == .file {
      isFile = true
      showFileAction()
    } else if let type = cell.cellData?.type, type == .rtc {
      showRtcCallAction()
    } else {}
  }

  open func showTakePicture() {
    showBottomVideoAction(self, false)
  }

  open func showFileAction() {
    showBottomFileAction(self)
  }

  open func showRtcCallAction() {
    let sessionId = viewModel.sessionId

    var param = [String: Any]()
    param["remoteUserAccid"] = sessionId
    param["currentUserAccid"] = IMKitClient.instance.account()
    param["remoteShowName"] = titleContent

    if let user = viewModel.getShowName(sessionId).user {
      param["remoteAvatar"] = user.user?.avatar
    }

    let videoCallAction = UIAlertAction(title: chatLocalizable("video_call"), style: .default) { _ in
      param["type"] = NSNumber(integerLiteral: 2)
      Router.shared.use(CallViewRouter, parameters: param)
    }

    let audioCallAction = UIAlertAction(title: chatLocalizable("audio_call"), style: .default) { _ in
      param["type"] = NSNumber(integerLiteral: 1)
      Router.shared.use(CallViewRouter, parameters: param)
    }

    let cancelAction = UIAlertAction(title: chatLocalizable("cancel"),
                                     style: .cancel) { action in
    }

    showActionSheet([videoCallAction, audioCallAction, cancelAction])
  }

  func didToSearchLocationView() {
    var params = [String: Any]()
    params["type"] = NEMapType.search.rawValue
    params["nav"] = navigationController
    Router.shared.use(NERouterUrl.LocationVCRouter, parameters: params)
  }

  open func textChanged(text: String) -> Bool {
    if text == "@" {
      // 做p2p类型判断
      if V2NIMConversationIdUtil.conversationType(viewModel.conversationId) == .CONVERSATION_TYPE_P2P {
        return true
      } else {
        DispatchQueue.main.async {
          self.showUserSelectVC(text: text)
        }
        return true
      }

    } else {
      return true
    }
  }

  open func textDelete(range: NSRange, text: String) -> Bool {
    var index = -1
    var removeRange: NSRange?
    for (i, r) in atUsers.enumerated() {
      let rightIndex = r.location + r.length - 1
      if rightIndex == range.location {
        index = i
        removeRange = r
        break
      }
    }

    if index >= 0 {
      atUsers.remove(at: index)
      if let rmRange = removeRange {
        // 删除rmRange后，rmRange.location后面所有的atUser的location都发生了变化
        var atUsersTmp = [NSRange]()
        for atUser in atUsers {
          if rmRange.location < atUser.location {
            atUsersTmp.append(NSRange(location: atUser.location - rmRange.length, length: atUser.length))
          } else {
            atUsersTmp.append(atUser)
          }
        }
        if atUsersTmp.count > 0 {
          atUsers = atUsersTmp
        }

        // 记录当前光标位置（removeSubrange后光标会直接跳到末尾）
        var selRange = chatInputView.textView.selectedTextRange
        if let oldCursor = chatInputView.textView.selectedTextRange {
          if let newCursor = chatInputView.textView.position(from: oldCursor.start, offset: -rmRange.length) {
            selRange = chatInputView.textView.textRange(from: newCursor, to: newCursor)
          }
        }

        // 删除rmRange范围内的字符串（"@xxx "）
        let subRange = chatInputView.textView.text.utf16.index(chatInputView.textView.text.startIndex, offsetBy: rmRange.location) ... chatInputView.textView.text.utf16.index(chatInputView.textView.text.startIndex, offsetBy: rmRange.location + rmRange.length - 1)

        let key = "\(rmRange.location)_\(rmRange.length - 1)"
        chatInputView.atRangeCache.removeValue(forKey: key)

        chatInputView.textView.text.removeSubrange(subRange)

        // 重新设置光标到删除前的位置
        chatInputView.textView.selectedTextRange = selRange
      }
      return false
    }
    return true
  }

  open func textFieldDidEndEditing(_ text: String?) {
    checkAndSendTypingState(endEdit: true)
  }

  open func textFieldDidBeginEditing(_ text: String?) {
    checkAndSendTypingState()
  }

  open func textFieldDidChange(_ text: String?) {
    checkAndSendTypingState()
  }

  /// 检查并发送正在输入状态
  /// - Parameter endEdit: 是否停止输入
  open func checkAndSendTypingState(endEdit: Bool = false) {}

  open func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    textView.typingAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ne_darkText, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
    return true
  }

  open func willSelectItem(button: UIButton?, index: Int) {
    operationView?.removeFromSuperview()
    if index == 2 || button?.isSelected == true {
      if index == 0 {
        // 语音
        layoutInputView(offset: bottomExanpndHeight, true)
      } else if index == 1 {
        // emoji
        layoutInputView(offset: bottomExanpndHeight, true)
      } else if index == 2 {
        // 相册
        isFile = false
        goPhotoAlbumWithVideo(self) { [weak self] in
          if NIMSDK.shared().mediaManager.isPlaying() {
            NIMSDK.shared().mediaManager.stopPlay()
            self?.playingCell?.stopAnimation(byRight: self?.playingModel?.message?.isSelf ?? true)
            self?.playingModel?.isPlaying = false
          }
        }
      } else if index == 3 {
        // 更多
        layoutInputView(offset: bottomExanpndHeight, true)
      }
    } else {
      layoutInputView(offset: 0)
    }
  }

  open func showMenue(sourceView: UIView) {
    let alert = UIAlertController(
      title: chatLocalizable("choose"),
      message: nil,
      preferredStyle: .actionSheet
    )
    alert.modalPresentationStyle = .popover
    let camera = UIAlertAction(title: commonLocalizable("take_picture"), style: .default) { action in
      self.takePhoto()
    }
    let photo = UIAlertAction(title: chatLocalizable("select_from_album"), style: .default) { action in
      self.willSelectImage()
    }

    let cancel = UIAlertAction(title: chatLocalizable("cancel"), style: .cancel) { action in
    }

    alert.addAction(camera)
    alert.addAction(photo)
    alert.addAction(cancel)
    let popover = alert.popoverPresentationController
    if popover != nil {
      popover?.sourceView = sourceView
      popover?.permittedArrowDirections = .any
    }
    present(alert, animated: true, completion: nil)
  }

  open func willSelectImage() {
    let imagePickerVC = UIImagePickerController()
    imagePickerVC.delegate = self
    imagePickerVC.allowsEditing = false
    imagePickerVC.sourceType = .photoLibrary
    present(imagePickerVC, animated: true)
  }

  open func takePhoto() {
    let imagePickerVC = UIImagePickerController()
    imagePickerVC.delegate = self
    imagePickerVC.allowsEditing = false
    imagePickerVC.sourceType = .camera
    present(imagePickerVC, animated: true)
  }

  open func clearAtRemind() {
    let param = ["sessionId": viewModel.conversationId]
    Router.shared.use("ClearAtMessageRemind", parameters: param, closure: nil)
  }

  open func sendMediaMessage(didFinishPickingMediaWithInfo info: [UIImagePickerController
      .InfoKey: Any]) {
    var imageName = "IMG_0001"
    var imageWidth: Int32 = 0
    var imageHeight: Int32 = 0
    var videoDuration: Int32 = 0

    // 获取展示名称
    if isFile == true,
       let imgUrl = info[.referenceURL] as? URL {
      let fetchRes = PHAsset.fetchAssets(withALAssetURLs: [imgUrl], options: nil)
      let asset = fetchRes.firstObject
      if let fileName = asset?.value(forKey: "filename") as? String {
        imageName = fileName
      }
    }

    // 获取图片宽高、视频时长
    // phAsset 不一定有
    if #available(iOS 11.0, *) {
      if let phAsset = info[.phAsset] as? PHAsset {
        imageWidth = Int32(phAsset.pixelWidth)
        imageHeight = Int32(phAsset.pixelHeight)
        videoDuration = Int32(phAsset.duration * 1000)
      }
    }

    // video
    if let videoUrl = info[.mediaURL] as? URL {
      print("image picker video : url", videoUrl)

      // 获取视频宽高、时长
      let asset = AVURLAsset(url: videoUrl)
      videoDuration = Int32(asset.duration.seconds * 1000)

      let track = asset.tracks(withMediaType: .video).first
      if let track = track {
        let size = track.naturalSize
        let transform = track.preferredTransform
        let correctedSize = size.applying(transform)
        imageWidth = Int32(abs(correctedSize.width))
        imageHeight = Int32(abs(correctedSize.height))
      }

      weak var weakSelf = self
      if isFile == true {
        copyFileToSend(url: videoUrl, displayName: imageName)
      } else {
        viewModel.sendVideoMessage(url: videoUrl, name: imageName, width: imageWidth, height: imageHeight, duration: videoDuration) { error in
          NEALog.infoLog(
            ModuleName + " " + ChatViewController.className(),
            desc: #function + "CALLBACK sendVideoMessage " + (error?.localizedDescription ?? "no error")
          )
          weakSelf?.showErrorToast(error)
        }
      }
      return
    }

    if #available(iOS 11.0, *) {
      var imageUrl = info[.imageURL] as? URL
      var image = info[.originalImage] as? UIImage
      image = image?.fixOrientation()

      // 获取图片宽度
      if let width = image?.size.width {
        imageWidth = Int32(width)
      }

      // 获取图片高度度
      if let height = image?.size.height {
        imageHeight = Int32(height)
      }

      let pngImage = image?.pngData()
      var needDelete = false

      // 无url则临时保存到本地，发送成功后删除临时文件
      if imageUrl == nil {
        if let data = pngImage, let path = NEPathUtils.getDirectoryForDocuments(dir: "NEIMUIKit/image/") {
          let url = URL(fileURLWithPath: path + "\(imageName).png")
          do {
            try data.write(to: url)
            imageUrl = url
            needDelete = true
          } catch {
            showToast(chatLocalizable("image_is_nil"))
          }
        }
      }

      guard let imageUrl = imageUrl else {
        showToast(chatLocalizable("image_is_nil"))
        return
      }

      if isFile == true {
        let imgSize_MB = Double(pngImage?.count ?? 0) / 1e6
        NEALog.infoLog(ModuleName + " " + ChatViewController.className(), desc: #function + "imgSize_MB: \(imgSize_MB) MB")
        if imgSize_MB > NEKitChatConfig.shared.ui.fileSizeLimit {
          showToast(String(format: chatLocalizable("fileSize_over_limit"), "\(NEKitChatConfig.shared.ui.fileSizeLimit)"))
        } else {
          viewModel.sendFileMessage(filePath: imageUrl.relativePath, displayName: imageName) { [weak self] error in
            NEALog.infoLog(
              ModuleName + " " + ChatViewController.className(),
              desc: #function + "CALLBACK sendFileMessage" + (error?.localizedDescription ?? "no error")
            )
            self?.showErrorToast(error)
          }
        }
      } else {
        if let url = info[.referenceURL] as? URL {
          if url.absoluteString.hasSuffix("ext=GIF") == true {
            // GIF 需要特殊处理
            let imageAsset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset
            let options = PHImageRequestOptions()
            options.version = .current
            guard let asset = imageAsset else {
              return
            }
            weak var weakSelf = self
            PHImageManager.default().requestImageData(for: asset, options: options) { imageData, dataUTI, orientation, info in
              if let data = imageData {
                let tempDirectoryURL = FileManager.default.temporaryDirectory
                let uniqueString = UUID().uuidString
                let temUrl = tempDirectoryURL.appendingPathComponent(uniqueString + ".gif")
                print("tem url path : ", temUrl.path)
                do {
                  try data.write(to: temUrl)
                  DispatchQueue.main.async {
                    weakSelf?.viewModel.sendImageMessage(path: temUrl.path, name: imageName, width: imageWidth, height: imageHeight) { error in
                      NEALog.infoLog(
                        ModuleName + " " + ChatViewController.className(),
                        desc: #function + "CALLBACK sendImageMessage " + (error?.localizedDescription ?? "no error")
                      )
                      weakSelf?.showErrorToast(error)
                    }
                  }
                } catch {
                  NEALog.infoLog(ModuleName, desc: #function + "write tem gif data error : \(error.localizedDescription)")
                }
              }
            }
            return
          }
        }

        viewModel.sendImageMessage(path: imageUrl.relativePath, name: imageName, width: imageWidth, height: imageHeight) { [weak self] error in
          NEALog.infoLog(
            ModuleName + " " + ChatViewController.className(),
            desc: #function + "CALLBACK sendImageMessage " + (error?.localizedDescription ?? "no error")
          )
          self?.showErrorToast(error)
          // 删除临时保存的图片
          if needDelete {
            try? FileManager.default.removeItem(at: imageUrl)
          }
        }
      }
    }
  }

  //    MARK: UIImagePickerControllerDelegate

  open func imagePickerController(_ picker: UIImagePickerController,
                                  didFinishPickingMediaWithInfo info: [UIImagePickerController
                                    .InfoKey: Any]) {
    weak var weakSelf = self
    picker.dismiss(animated: true, completion: {
      weakSelf?.sendMediaMessage(didFinishPickingMediaWithInfo: info)
    })
  }

  open func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
  }

  //    MARK: UIDocumentPickerDelegate

  /// 拷贝文件到沙盒，用于发送
  /// - Parameters:
  ///   - url: 原始路径
  ///   - displayName: 显示名称
  func copyFileToSend(url: URL, displayName: String) {
    let desPath = NSTemporaryDirectory() + "\(url.lastPathComponent)"
    let dirUrl = URL(fileURLWithPath: desPath)
    if !FileManager.default.fileExists(atPath: desPath) {
      NEALog.infoLog(ModuleName + " " + ChatViewController.className(), desc: #function + "file not exist")
      do {
        try FileManager.default.copyItem(at: url, to: dirUrl)
      } catch {
        NEALog.errorLog(ModuleName + " " + ChatViewController.className(), desc: #function + "copyItem [\(desPath)] ERROR: \(error)")
      }
    }
    if FileManager.default.fileExists(atPath: desPath) {
      NEALog.infoLog(ModuleName + " " + ChatViewController.className(), desc: #function + "fileExists")
      do {
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: desPath)
        if let size_B = fileAttributes[FileAttributeKey.size] as? Double {
          let size_MB = size_B / 1e6
          if size_MB > NEKitChatConfig.shared.ui.fileSizeLimit {
            showToast(String(format: chatLocalizable("fileSize_over_limit"), "\(NEKitChatConfig.shared.ui.fileSizeLimit)"))
            try? FileManager.default.removeItem(atPath: desPath)
          } else {
            viewModel.sendFileMessage(filePath: desPath, displayName: displayName) { [weak self] error in
              NEALog.infoLog(
                ModuleName + " " + ChatViewController.className(),
                desc: #function + "CALLBACK sendFileMessage " + (error?.localizedDescription ?? "no error")
              )
              self?.showErrorToast(error)
            }
          }
        }
      } catch {
        NEALog.errorLog(ModuleName + " " + ChatViewController.className(), desc: #function + "get file size error: \(error)")
      }
    }
  }

  open func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    controller.dismiss(animated: true)
    guard let url = urls.first else { return }

    // 开始安全访问权限
    let fileUrlAuthozied = url.startAccessingSecurityScopedResource()
    if fileUrlAuthozied {
      NSFileCoordinator().coordinate(readingItemAt: url, options: .withoutChanges, error: nil) { newUrl in
        let displayName = newUrl.lastPathComponent
        copyFileToSend(url: newUrl, displayName: displayName)
      }
      // 停止安全访问权限
      url.stopAccessingSecurityScopedResource()
    } else {
      NEALog.errorLog(ModuleName + " " + ChatViewController.className(), desc: #function + "fileUrlAuthozied FAILED")
    }
  }

  // MARK: UIDocumentInteractionControllerDelegate

  open func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
    self
  }

  open func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    controller.dismiss(animated: true)
  }

  // MARK: NEContactListener

  /// 好友（用户）信息变更回调
  /// - Parameter accountId: 用户 id
  func onUserOrFriendInfoChanged(_ accountId: String) {
    let sessionId = viewModel.sessionId

    if accountId == sessionId {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: DispatchWorkItem(block: { [weak self] in
        let showName = ChatTeamCache.shared.getShowName(sessionId).name
        self?.titleContent = showName
        self?.title = showName
      }))
    }
    viewModel.updateMessageInfo(accountId)
  }

  /// 用户信息变更回调
  /// - Parameter users: 用户列表
  public func onUserProfileChanged(_ users: [V2NIMUser]) {
    for user in users {
      if let accountId = user.accountId {
        onUserOrFriendInfoChanged(accountId)
        if NEFriendUserCache.shared.getFriendInfo(accountId) == nil {
          ChatTeamCache.shared.updateTeamMemberInfo(NEUserWithFriend(user: user))
        }
      }
    }
  }

  /// 好友信息变更回调
  /// - Parameter friendInfo: 好友信息
  public func onFriendInfoChanged(_ friendInfo: V2NIMFriend) {
    guard let accountId = friendInfo.accountId else {
      return
    }
    onUserOrFriendInfoChanged(accountId)
  }

  //    MARK: ChatviewModelDelegate

  open func didLeaveTeam() {
    weak var weakSelf = self
    showSingleAlert(message: chatLocalizable("team_has_quit")) {
      weakSelf?.navigationController?.popViewController(animated: true)
    }
  }

  open func didDismissTeam() {
    weak var weakSelf = self
    showSingleAlert(message: chatLocalizable("team_has_been_removed")) {
      weakSelf?.navigationController?.popViewController(animated: true)
    }
  }

  /// 收到消息
  /// - Parameter messages: 消息列表
  open func onRecvMessages(_ messages: [V2NIMMessage]) {
    operationView?.removeFromSuperview()
    insertRows()
    if isCurrentPage,
       UIApplication.shared.applicationState == .active {
      // 发送已读回执
      viewModel.markRead(messages: messages) { error in
        NEALog.infoLog(
          ModuleName + " " + ChatViewController.className(),
          desc: #function + "CALLBACK markRead " + (error?.localizedDescription ?? "no error")
        )
      }
    } else {
      needMarkReadMsgs += messages
    }
  }

  /// 消息即将发送
  /// - Parameter message: 消息
  open func sending(_ message: V2NIMMessage) {
    insertRows()
  }

  /// 消息发送成功
  /// - Parameter message: 消息
  public func sendSuccess(_ message: V2NIMMessage) {
    let indexs = indexPathsWithMessags([message])
    tableViewReloadIndexs(indexs)
  }

  private func indexPathsWithMessags(_ messages: [V2NIMMessage]) -> [IndexPath] {
    var indexPaths = [IndexPath]()
    for messageModel in messages {
      for (i, model) in viewModel.messages.enumerated() {
        if model.message?.messageClientId == messageModel.messageClientId {
          indexPaths.append(IndexPath(row: i, section: 0))
        }
      }
    }
    return indexPaths
  }

  public func onLoadMoreWithMessage(_ indexs: [IndexPath]) {
    tableViewReloadIndexs(indexs)
  }

  open func onDeleteMessage(_ messages: [V2NIMMessage], deleteIndexs: [IndexPath], reloadIndex: [IndexPath]) {
    if deleteIndexs.isEmpty {
      return
    }

    operationView?.removeFromSuperview()
    tableViewReloadIndexs(reloadIndex) { [weak self] in
      for index in reloadIndex {
        if let numberOfRows = self?.tableView.numberOfRows(inSection: 0), index.row == numberOfRows - 1 {
          self?.scrollTableViewToBottom()
        }
      }
    }

    for message in messages {
      viewModel.messages.removeAll { $0.message?.messageClientId == message.messageClientId }
    }
    tableViewDeleteIndexs(deleteIndexs)

    // 如果消息为空(加载的消息全部被删除)，则拉取更多数据
    if viewModel.messages.isEmpty {
      loadMoreData()
    }
  }

  open func onRevokeMessage(_ message: V2NIMMessage, atIndexs: [IndexPath]) {
    if atIndexs.isEmpty {
      return
    }
    viewModel.selectedMessages.removeAll(where: { $0.messageClientId == message.messageClientId })
    operationView?.removeFromSuperview()
    NEALog.infoLog(className(), desc: "on revoke message at indexs \(atIndexs)")
    tableViewReloadIndexs(atIndexs) { [weak self] in
      for index in atIndexs {
        if let numberOfRows = self?.tableView.numberOfRows(inSection: 0), index.row == numberOfRows - 1 {
          self?.scrollTableViewToBottom()
        }
      }
    }
  }

  public func onMessagePinStatusChange(_ message: V2NIMMessage?, atIndexs: [IndexPath]) {
    tableViewReloadIndexs(atIndexs) { [weak self] in
      for index in atIndexs {
        if let numberOfRows = self?.tableView.numberOfRows(inSection: 0), index.row == numberOfRows - 1 {
          self?.scrollTableViewToBottom()
        }
      }
    }
  }

  open func tableViewDeleteIndexs(_ indexs: [IndexPath]) {
    tableView.deleteData(indexs)
  }

  open func tableViewReloadIndexs(_ indexs: [IndexPath], _ completion: (() -> Void)? = nil) {
    if isUploadingData {
      return
    }

    let indexs = indexs.filter { index in
      index.row >= 0 && index.row < tableView.numberOfRows(inSection: 0)
    }

    if indexs.isEmpty {
      return
    }

    tableView.reloadData(indexs) { _ in
      completion?()
    }
  }

  open func tableViewReload() {
    tableView.reloadData()
  }

  open func selectedMessagesChanged(_ count: Int) {
    mutilSelectBottomView.setEnable(count > 0)
  }

  // record audio
  open func startRecord() {
    let dur = 60.0
    if NEAuthManager.hasAudioAuthoriztion() {
      NIMSDK.shared().mediaManager.record(forDuration: dur)
    } else {
      NEAuthManager.requestAudioAuthorization { [weak self] granted in
        if granted {
        } else {
          DispatchQueue.main.async {
            self?.showSingleAlert(message: commonLocalizable("jump_microphone_setting")) {}
          }
        }
      }
    }
  }

  open func moveOutView() {}

  open func moveInView() {}

  open func endRecord(insideView: Bool) {
    print("[record] stop:\(insideView)")
    if insideView {
      //            send
      NIMSDK.shared().mediaManager.stopRecord()
    } else {
      //            cancel
      NIMSDK.shared().mediaManager.cancelRecord()
    }
  }

  // MARK: audio play

  func startPlaying(audioMessage: V2NIMMessage?, isSend: Bool) {
    guard let message = audioMessage, let audio = message.attachment as? V2NIMMessageAudioAttachment else {
      return
    }
    playingCell?.startAnimation(byRight: isSend)
    let path = audio.path ?? ChatMessageHelper.createFilePath(message)
    if FileManager.default.fileExists(atPath: path) {
      NEALog.infoLog(className(), desc: #function + " play path : " + path)
      NIMSDK.shared().mediaManager.play(path)
    } else {
      NEALog.infoLog(className(), desc: #function + " audio path is empty, play url : " + (audio.url ?? ""))
      playingCell?.stopAnimation(byRight: isSend)
    }
  }

  private func startPlay(cell: ChatAudioCellProtocol?, model: MessageAudioModel?) {
    guard let isSend = model?.message?.isSelf else {
      return
    }
    if playingModel == model {
      if NIMSDK.shared().mediaManager.isPlaying() {
        stopPlay()
      } else {
        startPlaying(audioMessage: model?.message, isSend: isSend)
      }
    } else {
      stopPlay()
      playingCell = cell
      playingModel = model
      startPlaying(audioMessage: model?.message, isSend: isSend)
    }
  }

  open func stopPlay() {
    if NIMSDK.shared().mediaManager.isPlaying() {
      playingCell?.stopAnimation(byRight: playingModel?.message?.isSelf ?? true)
      NIMSDK.shared().mediaManager.stopPlay()
    }
  }

  //    private func startPlay() {
  //        if NIMSDK.shared().mediaManager.isPlaying() {
  //            self.playingCell?.startAnimation()
  //            NIMSDK.shared().mediaManager.stopPlay()
  //        }
  //    }

  //    MARK: NIMMediaManagerDelegate

  //    play
  open func playAudio(_ filePath: String, didBeganWithError error: Error?) {
    print(#function + "\(error?.localizedDescription ?? "")")
    NIMSDK.shared().mediaManager.switch(viewModel.getHandSetEnable() ? .receiver : .speaker)
    if error != nil {
      showErrorToast(error)
      // stop
      playingCell?.stopAnimation(byRight: playingModel?.message?.isSelf ?? true)
      playingModel?.isPlaying = false
    }
  }

  open func playAudio(_ filePath: String, didCompletedWithError error: Error?) {
    print(#function + "\(error?.localizedDescription ?? "")")
    showErrorToast(error)
    // stop
    playingCell?.stopAnimation(byRight: playingModel?.message?.isSelf ?? true)
    playingModel?.isPlaying = false
  }

  open func stopPlayAudio(_ filePath: String, didCompletedWithError error: Error?) {
    print(#function + "\(error?.localizedDescription ?? "")")
    showErrorToast(error)
    playingCell?.stopAnimation(byRight: playingModel?.message?.isSelf ?? true)
    playingModel?.isPlaying = false
  }

  open func playAudio(_ filePath: String, progress value: Float) {}

  open func playAudioInterruptionEnd() {
    playingCell?.stopAnimation(byRight: playingModel?.message?.isSelf ?? true)
    playingModel?.isPlaying = false
  }

  open func playAudioInterruptionBegin() {
    // stop play
    playingCell?.stopAnimation(byRight: playingModel?.message?.isSelf ?? true)
    playingModel?.isPlaying = false
  }

  //  record
  open func recordAudio(_ filePath: String?, didBeganWithError error: Error?) {
    print("[record] sdk Began error:\(error?.localizedDescription ?? "")")
  }

  open func recordAudio(_ filePath: String?, didCompletedWithError error: Error?) {
    print("[record] sdk Completed error:\(error?.localizedDescription ?? "")")
    chatInputView.stopRecordAnimation()
    guard let fp = filePath else {
      showErrorToast(error)
      return
    }
    let dur = recordDuration(filePath: fp)

    print("dur:\(dur)")
    if dur > 1 {
      viewModel.sendAudioMessage(filePath: fp) { error in
        NEALog.infoLog(
          ModuleName + " " + ChatViewController.className(),
          desc: #function + "CALLBACK sendAudioMessage " + (error?.localizedDescription ?? "no error")
        )
        self.showErrorToast(error)
      }
    } else {
      showToast(chatLocalizable("record_too_short"))
    }
  }

  open func recordAudioDidCancelled() {
    print("[record] sdk cancel")
  }

  open func recordAudioProgress(_ currentTime: TimeInterval) {}

  open func recordAudioInterruptionBegin() {}

  //    MARK: Private Method

  private func recordDuration(filePath: String) -> Float64 {
    let avAsset = AVURLAsset(url: URL(fileURLWithPath: filePath))
    return CMTimeGetSeconds(avAsset.duration)
  }

  private func insertRows() {
    let oldRows = tableView.numberOfRows(inSection: 0)
    if oldRows == 0 {
      tableView.reloadData()
      return
    }
    if oldRows == viewModel.messages.count {
      tableView.reloadData()
      return
    }
    var indexs = [IndexPath]()
    for (i, _) in viewModel.messages.enumerated() {
      if i >= oldRows {
        indexs.append(IndexPath(row: i, section: 0))
      }
    }

    if !indexs.isEmpty {
      tableView.insertData(indexs) { [weak self] _ in
        if let row = self?.tableView.numberOfRows(inSection: 0), row > 0 {
          self?.tableView.scrollToRow(
            at: IndexPath(row: row - 1, section: 0),
            at: .bottom,
            animated: false
          )
        }
      }
    }
  }

  open func addToAtUsers(addText: String, isReply: Bool = false, accid: String, _ isLongPress: Bool = false) {
    if let font = chatInputView.textView.font {
      let mutaString = NSMutableAttributedString(attributedString: chatInputView.textView.attributedText)
      let atString = NSAttributedString(string: addText, attributes: [NSAttributedString.Key.foregroundColor: UIColor.ne_blueText, NSAttributedString.Key.font: font])
      var selectRange = NSMakeRange(0, 0)
      var location = 0
      if chatInputView.textView.isFirstResponder == true {
        location = chatInputView.textView.selectedRange.location
        selectRange = chatInputView.textView.selectedRange
      } else {
        location = chatInputView.textView.attributedText.length
        selectRange = NSMakeRange(location, 0)
      }

      if isReply || isLongPress {
        let temMutaString = NSMutableAttributedString(attributedString: atString)
        let spaceStr = NSAttributedString(string: " ", attributes: [NSAttributedString.Key.font: font])
        temMutaString.append(spaceStr)
        mutaString.insert(temMutaString, at: location)

        chatInputView.nickAccidDic[addText] = accid.count > 0 ? accid : "ait_all"
        chatInputView.textView.attributedText = mutaString
        chatInputView.textView.selectedRange = NSMakeRange(selectRange.location + temMutaString.length, 0)
        return
      }

      if chatInputView.textView.selectedRange.location > 0 {
        mutaString.replaceCharacters(in: NSMakeRange(chatInputView.textView.selectedRange.location - 1, 1), with: "")
        let temMutaString = NSMutableAttributedString(attributedString: atString)
        let spaceStr = NSAttributedString(string: " ", attributes: [NSAttributedString.Key.font: font])
        temMutaString.append(spaceStr)
        mutaString.insert(temMutaString, at: chatInputView.textView.selectedRange.location - 1)
        selectRange = NSMakeRange(selectRange.location - 1, selectRange.length)
      }

      chatInputView.nickAccidDic[addText] = accid.count > 0 ? accid : "ait_all"

      chatInputView.textView.attributedText = mutaString
      chatInputView.textView.selectedRange = NSMakeRange(selectRange.location + addText.count + atRangeOffset, 0)
    }
  }

  func getUserSelectVC() -> NEBaseSelectUserViewController {
    NEBaseSelectUserViewController(sessionId: viewModel.sessionId, showSelf: false)
  }

  private func showUserSelectVC(text: String) {
    let selectVC = getUserSelectVC()
    selectVC.modalPresentationStyle = .formSheet
    selectVC.selectedBlock = { [weak self] index, model in
      var addText = ""
      var accid = ""

      if model == nil {
        addText += chatLocalizable("user_select_all")
      } else {
        if let m = model {
          addText += m.showNameInTeam() ?? ""
          if let uid = m.nimUser?.user?.accountId {
            accid = uid
          }
        }
      }
      addText = "@" + addText + ""
      self?.addToAtUsers(addText: addText, accid: accid)
    }
    present(selectVC, animated: true, completion: nil)
  }

  private func showErrorToast(_ error: Error?) {
    if let err = error as? NSError {
      switch err.code {
      case protocolSendFailed:
        showToast(commonLocalizable("network_error"))
      default:
        print(err.localizedDescription)
      }
    }
  }

  //    MARK: MessageOperationViewDelegate

  open func didSelectedItem(item: OperationItem) {
    if let popMenuClick = NEKitChatConfig.shared.ui.popMenuClick {
      popMenuClick(item)
      return
    }

    switch item.type {
    case .copy:
      copyMessage()
    case .delete:
      deleteMessage()
    case .reply:
      if !isMute {
        showReplyMessageView()
      }
    case .recall:
      recallMessage()
    case .forward:
      forwardMessage()
    case .pin:
      pinMessage()
    case .removePin:
      removePinMessage()
    case .multiSelect:
      selectMessage()
    default:
      customOperation()
    }
  }

  open func customOperation() {}

  open func copyMessage() {
    if let model = viewModel.operationModel as? MessageTextModel {
      if let text = model.message?.text, !text.isEmpty {
        UIPasteboard.general.string = text
        showToast(chatLocalizable("copy_success"))
      } else if let body = model.attributeStr?.string, !body.isEmpty {
        UIPasteboard.general.string = body
        showToast(chatLocalizable("copy_success"))
      } else if let model = viewModel.operationModel as? MessageRichTextModel {
        if let title = model.titleAttributeStr?.string, !title.isEmpty {
          UIPasteboard.general.string = title
          showToast(chatLocalizable("copy_success"))
        }
      }
    }
  }

  open func deleteMessage() {
    showAlert(message: chatLocalizable("message_delete_confirm")) { [weak self] in
      // 校验网络
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        self?.showToast(commonLocalizable("network_error"))
        return
      }

      self?.viewModel.deleteMessage { error in
        self?.showErrorToast(error)
      }
    }
  }

  open func showReplyMessageView(isReEdit: Bool = false) {
    viewModel.isReplying = true
    if chatInputView.chatInpuMode != .multipleReturn {
      view.addSubview(replyView)
      replyView.closeButton.addTarget(self, action: #selector(closeReply), for: .touchUpInside)
      replyView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        replyView.leadingAnchor.constraint(equalTo: chatInputView.leadingAnchor),
        replyView.trailingAnchor.constraint(equalTo: chatInputView.trailingAnchor),
        replyView.bottomAnchor.constraint(equalTo: chatInputView.topAnchor),
        replyView.heightAnchor.constraint(equalToConstant: 36),
      ])
    }

    if let message = viewModel.operationModel?.message {
      if isReEdit {
        replyView.textLabel.attributedText = NEEmotionTool.getAttWithStr(str: viewModel.operationModel?.replyText ?? "",
                                                                         font: replyView.textLabel.font,
                                                                         color: replyView.textLabel.textColor)
        viewModel.getReplyMessageWithoutThread(message: message) { model in
          if let replyMessage = model as? MessageContentModel {
            self.viewModel.operationModel = replyMessage
          }
        }
      } else {
        var text = chatLocalizable("msg_reply")
        if let uid = message.senderId {
          var (showName, _) = ChatTeamCache.shared.getShowName(uid, false)
          if V2NIMConversationIdUtil.conversationType(viewModel.conversationId) != .CONVERSATION_TYPE_P2P,
             !IMKitClient.instance.isMe(uid) {
            addToAtUsers(addText: "@" + showName + "", isReply: true, accid: uid)
          }
          (showName, _) = ChatTeamCache.shared.getShowName(uid)
          text += " " + showName
          text += ": \(ChatMessageHelper.contentOfMessage(message))"
          replyView.textLabel.attributedText = NEEmotionTool.getAttWithStr(str: text,
                                                                           font: replyView.textLabel.font,
                                                                           color: replyView.textLabel.textColor)
          chatInputView.textView.becomeFirstResponder()
        }
      }
    }
  }

  open func closeReply(button: UIButton?) {
    replyView.removeFromSuperview()
    viewModel.isReplying = false
  }

  open func recallMessage() {
    weak var weakSelf = self
    showAlert(message: chatLocalizable("message_revoke_confirm")) {
      // 校验网络
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        weakSelf?.showToast(commonLocalizable("network_error"))
        return
      }

      if let message = weakSelf?.viewModel.operationModel?.message {
        if message.messageType == .MESSAGE_TYPE_TEXT {
          weakSelf?.viewModel.operationModel?.isReedit = true
        }

        if message.messageType == .MESSAGE_TYPE_CUSTOM,
           let customType = NECustomAttachment.typeOfCustomMessage(message.attachment),
           customType == customRichTextType {
          weakSelf?.viewModel.operationModel?.isReedit = true
        }

        let isPin = weakSelf?.viewModel.operationModel?.isPined ?? false
        weakSelf?.viewModel.revokeMessage(message: message) { error in
          NEALog.infoLog(
            ModuleName + " " + ChatViewController.className(),
            desc: #function + "CALLBACK revokeMessage " + (error?.localizedDescription ?? "no error")
          )
          if let err = error as? NSError {
            if err.code == protocolSendFailed {
              weakSelf?.showToast(commonLocalizable("network_error"))
            } else if err.code == ravokableTimeExpired {
              weakSelf?.showToast(chatLocalizable("ravokable_time_expired"))
            } else {
              weakSelf?.showToast(chatLocalizable("ravoked_failed"))
            }
          } else {
            // 自己撤回成功 & 收到对方撤回 都会走回调方法 onRevokeMessage
            // 撤回成功的逻辑统一在代理方法中处理 onRevokeMessage
            if isPin {
              weakSelf?.viewModel.removePinMessage(message: message) { error, value in
              }
            }
          }
        }
      }
    }
  }

  open func getForwardAlertController() -> NEBaseForwardAlertViewController {
    NEBaseForwardAlertViewController()
  }

  func addForwardAlertController(items: [ForwardItem],
                                 type: String,
                                 _ sureBlock: ((String?) -> Void)? = nil) {
    let forwardAlert = getForwardAlertController()
    forwardAlert.setItems(items)
    forwardAlert.type = type
    forwardAlert.sureBlock = sureBlock
    forwardAlert.context = ChatMessageHelper.getSessionName(conversationId: viewModel.conversationId)

    addChild(forwardAlert)
    view.addSubview(forwardAlert.view)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: DispatchWorkItem(block: {
      UIApplication.shared.keyWindow?.endEditing(true)
    }))
  }

  func forwardMessageToUser(isMultiForward: Bool = false,
                            depth: Int = 0,
                            _ sureBlock: (() -> Void)? = nil) {
    weak var weakSelf = self
    Router.shared.register(ContactSelectedUsersRouter) { param in
      var items = [ForwardItem]()

      if let users = param["im_user"] as? [V2NIMUser] {
        for user in users {
          let item = ForwardItem()
          item.uid = user.accountId
          item.avatar = user.avatar
          item.name = user.name
          items.append(item)
        }

        let type = isMultiForward ? chatLocalizable("select_multi") :
          (weakSelf?.isMutilSelect == true ? chatLocalizable("select_per_item") : chatLocalizable("operation_forward"))
        weakSelf?.addForwardAlertController(items: items, type: type) { comment in
          if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
            weakSelf?.showToast(commonLocalizable("network_error"))
            return
          }

          weakSelf?.viewModel.forwardUserMessage(users, isMultiForward, depth, comment) { error in
            weakSelf?.showErrorToast(error)
            sureBlock?()
          }
        }
      }
    }

    var param = [String: Any]()
    param["nav"] = weakSelf?.navigationController as Any
    param["limit"] = 6

    // 转发人员选择页面不包含自己
    var filters = Set<String>()
    filters.insert(IMKitClient.instance.account())
    param["filters"] = filters

    Router.shared.use(ContactUserSelectRouter, parameters: param, closure: nil)
  }

  func forwardMessageToTeam(isMultiForward: Bool = false,
                            depth: Int = 0,
                            _ sureBlock: (() -> Void)? = nil) {
    weak var weakSelf = self
    Router.shared.register(ContactTeamDataRouter) { param in
      if let team = param["team"] as? V2NIMTeam {
        let item = ForwardItem()
        item.avatar = team.avatar
        item.name = team.getShowName()
        item.uid = team.teamId

        let type = isMultiForward ? chatLocalizable("select_multi") :
          (weakSelf?.isMutilSelect == true ? chatLocalizable("select_per_item") : chatLocalizable("operation_forward"))
        weakSelf?.addForwardAlertController(items: [item], type: type) { comment in
          if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
            weakSelf?.showToast(commonLocalizable("network_error"))
            return
          }

          weakSelf?.viewModel.forwardTeamMessage(team, isMultiForward, depth, comment) { error in
            weakSelf?.showErrorToast(error)
            sureBlock?()
          }
        }
      }
    }

    Router.shared.use(
      ContactTeamListRouter,
      parameters: ["nav": weakSelf?.navigationController as Any,
                   "isClickCallBack": true],
      closure: nil
    )
  }

  open func forwardMessage() {
    if let message = viewModel.operationModel?.message {
      viewModel.selectedMessages = [message]
      didClickSingleForwardButton()
    }
  }

  open func pinMessage() {
    // 校验网络
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    guard let optModel = viewModel.operationModel, !optModel.isPined else {
      return
    }
    if optModel.isRevoked == true {
      return
    }
    if let message = optModel.message {
      viewModel.addPinMessage(message: message) { [weak self] error, index in
        NEALog.infoLog(
          ModuleName + " " + ChatViewController.className(),
          desc: #function + "CALLBACK pinMessage " + (error?.localizedDescription ?? "no error")
        )
        if let err = error as? NSError {
          if err.code == pinAlreadyExist {
            return
          } else if err.code == protocolSendFailed {
            self?.view.makeToast(commonLocalizable("network_error"), position: .center)
          } else if err.code == pinLimitExceeded {
            self?.view.makeToast(chatLocalizable("pin_limit_exceeded"), position: .center)
          } else {
            self?.view.makeToast(error?.localizedDescription, position: .center)
          }
        } else {
          //                    update UI
          if index >= 0 {
            self?.tableViewReloadIndexs([IndexPath(row: index, section: 0)]) { [weak self] in
              if let numberOfRows = self?.tableView.numberOfRows(inSection: 0), index == numberOfRows - 1 {
                self?.scrollTableViewToBottom()
              }
            }
          }
        }
      }
    }
  }

  open func removePinMessage() {
    // 校验网络
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    guard let optModel = viewModel.operationModel, optModel.isPined else {
      return
    }

    if let message = optModel.message {
      viewModel.removePinMessage(message: message) { [weak self] error, index in
        NEALog.infoLog(
          ModuleName + " " + ChatViewController.className(),
          desc: #function + "CALLBACK removePinMessage " + (error?.localizedDescription ?? "no error")
        )
        if let err = error as? NSError {
          if err.code == pinNotExist {
            return
          } else if err.code == protocolSendFailed {
            self?.view.makeToast(commonLocalizable("network_error"), position: .center)
          } else {
            self?.view.makeToast(error?.localizedDescription, position: .center)
          }
        } else {
          //                    update UI
          if index >= 0 {
            self?.tableViewReloadIndexs([IndexPath(row: index, section: 0)]) { [weak self] in
              if let numberOfRows = self?.tableView.numberOfRows(inSection: 0), index == numberOfRows - 1 {
                self?.scrollTableViewToBottom()
              }
            }
          }
        }
      }
    }
  }

  open func selectMessage() {
    isMutilSelect = true
    if let model = viewModel.operationModel, let msg = model.message {
      model.isSelected = true
      viewModel.selectedMessages = [msg]
    }

    navigationView.setMoreButtonTitle(chatLocalizable("cancel"))
    navigationView.moreButton.setTitleColor(.ne_darkText, for: .normal)
    navigationView.addMoreButtonTarget(target: self, selector: #selector(cancelMutilSelect))
    setInputView(edit: false)
    tableView.reloadData()
  }

  func cancelMutilSelect() {
    isMutilSelect = false
    viewModel.selectedMessages.removeAll()
    for model in viewModel.messages {
      model.isSelected = false
    }
    setMoreButton()
    setInputView(edit: true)
    tableView.reloadData()
  }

  // edit: 是否显示输入框
  func setInputView(edit: Bool) {
    bottomViewTopAnchor?.constant = edit ? -normalInputHeight : -100
    chatInputView.isHidden = !edit
    mutilSelectBottomView.isHidden = edit
  }

  // MARK: UITableViewDataSource, UITableViewDelegate

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.messages.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard indexPath.row < viewModel.messages.count else { return NEBaseChatMessageCell() }
    let model = viewModel.messages[indexPath.row]
    var reuseId = "\(NEBaseChatMessageCell.self)"
    if model.replyedModel?.isReplay == true,
       model.isRevoked == false {
      if let customType = NECustomAttachment.typeOfCustomMessage(model.message?.attachment),
         customType == customRichTextType {
        reuseId = "\(MessageType.richText.rawValue)"
      } else {
        reuseId = "\(MessageType.reply.rawValue)"
      }
    } else {
      let key = "\(model.type.rawValue)"
      if model.type == .custom, let customType = NECustomAttachment.typeOfCustomMessage(model.message?.attachment) {
        if customType == customMultiForwardType {
          reuseId = "\(MessageType.multiForward.rawValue)"
        } else if customType == customRichTextType {
          reuseId = "\(MessageType.richText.rawValue)"
        } else if NEChatUIKitClient.instance.getRegisterCustomCell()["\(customType)"] != nil {
          reuseId = "\(customType)"
        } else {
          reuseId = "\(NEBaseChatMessageCell.self)"
        }
      } else if model.type == .notification || model.type == .tip {
        reuseId = "\(MessageType.time.rawValue)"
      } else if cellRegisterDic[key] != nil {
        reuseId = key
      } else {
        reuseId = "\(NEBaseChatMessageCell.self)"
      }
    }

    let cell = tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath)
    if let c = cell as? NEBaseChatMessageTipCell {
      if let m = model as? MessageTipsModel {
        c.setModel(m)
      }
      return c
    } else if let c = cell as? NEBaseChatMessageCell {
      c.delegate = self

      // 语音消息播放状态
      if let audioCell = cell as? ChatAudioCellProtocol,
         let m = model as? MessageAudioModel,
         m.message?.messageClientId == playingModel?.message?.messageClientId {
        if NIMSDK.shared().mediaManager.isPlaying() {
          playingCell = audioCell
          m.isPlaying = true
        }
      }

      if let m = model as? MessageContentModel {
        c.setModel(m, m.message?.isSelf ?? false)
        c.setSelect(m, isMutilSelect)
      }

      return c
    } else if let c = cell as? NEChatBaseCell, let m = model as? MessageContentModel {
      c.setModel(m, m.message?.isSelf ?? false)
      return cell
    } else {
      return NEBaseChatMessageCell()
    }
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard indexPath.row < viewModel.messages.count else { return }
    if isMutilSelect {
      if indexPath.row < viewModel.messages.count {
        let model = viewModel.messages[indexPath.row]
        if !model.isRevoked,
           let cell = tableView.cellForRow(at: indexPath) as? NEBaseChatMessageCell {
          model.isSelected = !model.isSelected
          cell.selectedButton.isSelected = model.isSelected
          viewModel.selectedMessages.removeAll(where: { $0.messageClientId == model.message?.messageClientId })
          if model.isSelected, let msg = model.message {
            viewModel.selectedMessages.append(msg)
          }
        }
      }
      return
    }

    operationView?.removeFromSuperview()
    if chatInputView.textView.isFirstResponder {
      chatInputView.textView.resignFirstResponder()
    } else {
//      layoutInputView(offset: 0)
    }
  }

  open func tableView(_ tableView: UITableView,
                      heightForRowAt indexPath: IndexPath) -> CGFloat {
    guard indexPath.row < viewModel.messages.count else { return 0 }
    let model = viewModel.messages[indexPath.row]
    return model.cellHeight() + chat_content_margin
  }

  open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    0
  }

  open func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
    0
  }

  public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    // 无更多消息
    if viewModel.messages.count < viewModel.messagPageNum {
      return
    }

    // 预加载
    let leaveCount = 10 // 剩余多少行开始预加载
    weak var weakSelf = self
    if indexPath.row <= leaveCount, !isUploadingData, !uploadHasNoMore {
      // 上拉预加载更多
      if !isUploadingData {
        isUploadingData = true
        viewModel.dropDownRemoteRefresh { error, count, messages in
          if let err = error {
            NEALog.errorLog(
              ModuleName + " " + ChatViewController.className(),
              desc: #function + "CALLBACK dropDownRemoteRefresh " + (err.localizedDescription)
            )
          } else {
            NEALog.infoLog(
              ModuleName + " " + ChatViewController.className(),
              desc: #function + "CALLBACK dropDownRemoteRefresh " + (error?.localizedDescription ?? "no error")
            )
            if count <= 0 {
              // 校验网络
              if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
                return
              }

              // 无更多数据
              weakSelf?.uploadHasNoMore = true
              weakSelf?.tableView.mj_header = nil
            } else {
              weakSelf?.tableViewReload()
              if let num = weakSelf?.tableView.numberOfRows(inSection: 0), indexPath.row + count <= num {
                weakSelf?.tableView.scrollToRow(
                  at: IndexPath(row: indexPath.row + count - 1, section: 0),
                  at: .top,
                  animated: false
                )
              }
              weakSelf?.isUploadingData = false
            }
          }
        }
      }
    }
  }

  // MARK: UIScrollViewDelegate

  open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    operationView?.removeFromSuperview()
  }

  // MARK: CLLocationManagerDelegate

//    open func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
//        if #available(iOS 14.0, *) {
//            if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
//                didToSearchLocationView()
//            }
//        } else {
//            if CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
//                didToSearchLocationView()
//            }
//        }
//    }

  open func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    if isCurrentPage == false {
      return
    }
    if #available(iOS 14.0, *) {
      if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
        didToSearchLocationView()
      }
    } else {
      if CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
        didToSearchLocationView()
      }
    }
  }

  open func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {}

  open func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

//    open func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        print(error)
//    }

  func getTextViewController(title: String?, body: String?) -> TextViewController {
    let textViewController = TextViewController(title: title, body: body)
    textViewController.view.backgroundColor = .white
    return textViewController
  }

  // MARK: OVERRIDE

  open func getMenuView() -> NEBaseChatInputView {
    NEBaseChatInputView()
  }

  open func setMutilSelectBottomView() {
    mutilSelectBottomView.backgroundColor = .ne_backgroundColor
  }

  open func getMultiForwardViewController(_ messageAttachmentUrl: String?,
                                          _ messageAttachmentFilePath: String,
                                          _ messageAttachmentMD5: String?) -> MultiForwardViewController {
    MultiForwardViewController(messageAttachmentUrl, messageAttachmentFilePath, messageAttachmentMD5)
  }

  open func expandMoreAction() {
    var data = NEChatUIKitClient.instance.getMoreActionData(sessionType: V2NIMConversationIdUtil.conversationType(viewModel.conversationId))
    if NEChatKitClient.instance.delegate == nil {
      data = data.filter { item in
        if item.type == .location {
          return false
        }
        return true
      }
    }
    chatInputView.chatAddMoreView.configData(data: NEChatUIKitClient.instance.getMoreActionData(sessionType: V2NIMConversationIdUtil.conversationType(viewModel.conversationId)))
  }

  open func showTextViewController(_ model: MessageContentModel?) {
    let title = NECustomAttachment.titleOfRichText(model?.message?.attachment)
    let body = NECustomAttachment.bodyOfRichText(model?.message?.attachment) ?? model?.message?.text
    let textView = getTextViewController(title: title, body: body)
    textView.modalPresentationStyle = .fullScreen
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: DispatchWorkItem(block: { [weak self] in
      self?.navigationController?.present(textView, animated: false)
    }))
  }

  /// 单击消息
  /// - Parameters:
  ///   - cell: 消息所在单元格
  ///   - model: 消息模型
  ///   - replyIndex: 被回复消息的下标
  open func didTapMessage(_ cell: UITableViewCell?, _ model: MessageContentModel?, _ replyIndex: Int? = nil) {
    if model?.type == .audio, let audioObject = model?.message?.attachment as? V2NIMMessageAudioAttachment {
      let path = audioObject.path ?? ChatMessageHelper.createFilePath(model?.message)
      if !FileManager.default.fileExists(atPath: path) {
        if let urlString = audioObject.url {
          viewModel.downLoad(urlString, path, nil) { [weak self] _, error in
            if error == nil {
              NEALog.infoLog(ModuleName + " " + ChatViewController.className(), desc: #function + "CALLBACK downLoad")
              self?.startPlay(cell: cell as? ChatAudioCellProtocol, model: model as? MessageAudioModel)
            } else {
              self?.showErrorToast(error)
            }
          }
        }
      } else {
        startPlay(cell: cell as? ChatAudioCellProtocol, model: model as? MessageAudioModel)
      }
    } else if model?.type == .image {
      if let imageObject = model?.message?.attachment as? V2NIMMessageImageAttachment {
        var imageUrl = ""

        if let url = imageObject.url {
          imageUrl = url
        } else {
          if let path = imageObject.path, FileManager.default.fileExists(atPath: path) {
            imageUrl = path
          }
        }
        if imageUrl.count > 0 {
          var showImages = [imageUrl]
          if let index = replyIndex, index >= 0 {
            showImages = ChatMessageHelper.getUrls(messages: viewModel.messages)
          }

          let showController = PhotoBrowserController(urls: showImages, url: imageUrl)
          showController.modalPresentationStyle = .overFullScreen
          present(showController, animated: false, completion: nil)
        }
      }
    } else if model?.type == .video,
              let object = model?.message?.attachment as? V2NIMMessageVideoAttachment {
      stopPlay()

      let path = object.path ?? ChatMessageHelper.createFilePath(model?.message)
      if FileManager.default.fileExists(atPath: path) {
        let url = URL(fileURLWithPath: path)
        let videoPlayer = VideoPlayerViewController()
        videoPlayer.modalPresentationStyle = .overFullScreen
        videoPlayer.videoUrl = url
        videoPlayer.totalTime = Int(object.duration)
        present(videoPlayer, animated: true, completion: nil)
      } else {
        if let index = replyIndex, index >= 0,
           index < tableView.numberOfRows(inSection: 0) {
          tableView.scrollToRow(at: IndexPath(row: index, section: 0),
                                at: .middle,
                                animated: true)
        }
        downloadFile(cell, model, object.url, path)
      }
    } else if replyIndex != nil, model?.type == .text || model?.type == .reply {
      showTextViewController(model)
    } else if model?.type == .location {
      if let locationModel = model as? MessageLocationModel, let lat = locationModel.lat, let lng = locationModel.lng {
        var params = [String: Any]()
        params["type"] = NEMapType.detail.rawValue
        params["nav"] = navigationController
        params["lat"] = lat
        params["lng"] = lng
        params["locationTitle"] = locationModel.title
        params["subTitle"] = locationModel.subTitle
        Router.shared.use(NERouterUrl.LocationVCRouter, parameters: params)
      }
    } else if model?.type == .file,
              let object = model?.message?.attachment as? V2NIMMessageFileAttachment {
      let path = object.path ?? ChatMessageHelper.createFilePath(model?.message)
      if !FileManager.default.fileExists(atPath: path) {
        if let index = replyIndex, index >= 0,
           index < tableView.numberOfRows(inSection: 0) {
          tableView.scrollToRow(at: IndexPath(row: index, section: 0),
                                at: .middle,
                                animated: true)
        }
        downloadFile(cell, model, object.url, path)
      } else {
        let url = URL(fileURLWithPath: path)
        interactionController.url = url
        interactionController.delegate = self // UIDocumentInteractionControllerDelegate
        if interactionController.presentPreview(animated: true) {}
        else {
          interactionController.presentOptionsMenu(from: view.bounds, in: view, animated: true)
        }
      }
    } else if model?.type == .rtcCallRecord,
              let attachment = model?.message?.attachment as? V2NIMMessageCallAttachment {
      let sessionId = viewModel.sessionId

      var param = [String: Any]()
      param["remoteUserAccid"] = sessionId
      param["currentUserAccid"] = IMKitClient.instance.account()
      param["remoteShowName"] = titleContent
      param["type"] = attachment.type == 1 ? NSNumber(integerLiteral: 1) : NSNumber(integerLiteral: 2)

      if let user = viewModel.getShowName(sessionId).user {
        param["remoteAvatar"] = user.user?.avatar
      }

      Router.shared.use(CallViewRouter, parameters: param)
    } else if model?.type == .custom,
              let customType = NECustomAttachment.typeOfCustomMessage(model?.message?.attachment) {
      if customType == customRichTextType {
        if replyIndex != nil {
          showTextViewController(model)
        }
      } else if customType == customMultiForwardType,
                let data = NECustomAttachment.dataOfCustomMessage(model?.message?.attachment) {
        let url = data["url"] as? String
        let md5 = data["md5"] as? String
        guard let fileDirectory = NEPathUtils.getDirectoryForDocuments(dir: "NEIMUIKit/file/") else { return }
        let fileName = multiForwardFileName + (model?.message?.messageClientId ?? "")
        let filePath = fileDirectory + fileName
        let multiForwardVC = getMultiForwardViewController(url, filePath, md5)
        navigationController?.pushViewController(multiForwardVC, animated: true)
      }
    } else {
      print(#function + "message did tap, type:\(String(describing: model?.type.rawValue))")
    }
  }

  /// 下载附件（文件、视频消息）
  /// - Parameters:
  ///   - cell: 当前单元格
  ///   - model: 消息模型
  ///   - url: 远端下载链接
  ///   - path: 本地保存路径
  func downloadFile(_ cell: UITableViewCell?, _ model: MessageContentModel?, _ url: String?, _ path: String) {
    // 判断是否是视频或者文件对象
    guard let urlString = url, let fileModel = model as? MessageVideoModel else {
      NEALog.infoLog(ModuleName + " " + className(), desc: #function + "MessageFileModel not exit")
      return
    }

    // 判断状态，如果是下载中不能进行预览
    if fileModel.state == .Downalod {
      NEALog.infoLog(ModuleName + " " + className(), desc: #function + "downLoad state, click ingore")
      return
    }

    fileModel.state = .Downalod
    if let fileCell = cell as? NEBaseChatMessageCell {
      fileCell.setModel(fileModel, fileModel.message?.isSelf ?? false)
    }

    viewModel.downLoad(urlString, path) { progress in
      NEALog.infoLog(ModuleName + " " + ChatViewController.className(), desc: #function + "downLoad file progress: \(progress)")
      fileModel.progress = progress
      if progress >= 100 {
        fileModel.state = .Success
      }
      fileModel.cell?.uploadProgress(byRight: fileModel.message?.isSelf ?? true, progress)

    } _: { [weak self] _, error in
      self?.showErrorToast(error)
    }
  }
}

// MARK: NEMutilSelectBottomViewDelegate

extension ChatViewController: NEMutilSelectBottomViewDelegate {
  /// 移除不可转发的消息
  /// - Parameters invalidMessages: 不可转发的消息
  func filterSelectedMessage(invalidMessages: [V2NIMMessage]) {
    // 取消勾选
    for msg in viewModel.selectedMessages {
      if invalidMessages.contains(msg) {
        for (row, model) in viewModel.messages.enumerated() {
          if msg.messageClientId == model.message?.messageClientId {
            let indexPath = IndexPath(row: row, section: 0)
            let model = viewModel.messages[indexPath.row]
            if !model.isRevoked,
               let cell = tableView.cellForRow(at: indexPath) as? NEBaseChatMessageCell {
              model.isSelected = !model.isSelected
              cell.selectedButton.isSelected = model.isSelected
            }
          }
        }
      }
    }

    // 无论UI上是否取消勾选，都需要移除该消息
    viewModel.selectedMessages.removeAll(where: { invalidMessages.contains($0) })
  }

  /// 点击合并转发
  open func didClickMultiForwardButton() {
    // 校验网络
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    if viewModel.selectedMessages.count > customMultiForwardLimitCount {
      showToast(String(format: chatLocalizable("multiForward_forward_limit"), customMultiForwardLimitCount))
      return
    }

    var depth = 0
    var invalidMessages = [V2NIMMessage]()
    for msg in viewModel.selectedMessages {
      if msg.sendingState == .MESSAGE_SENDING_STATE_FAILED
//            || msg.isBlackListed
      {
        invalidMessages.append(msg)
        continue
      }

      // 解析消息中的depth
      if let data = NECustomAttachment.dataOfCustomMessage(msg.attachment) {
        if let dep = data["depth"] as? Int {
          if dep >= customMultiForwardMaxDepth {
            invalidMessages.append(msg)
          } else if dep >= depth {
            depth = dep
          }
        }
      }
    }

    depth += 1

    // 存在不可转发的消息：提示+取消勾选
    if invalidMessages.count > 0 {
      showAlert(title: chatLocalizable("exception_description"),
                message: chatLocalizable("exist_invalid")) { [self] in
        filterSelectedMessage(invalidMessages: invalidMessages)
        if !viewModel.selectedMessages.isEmpty {
          multiForwardForward(depth)
        }
      }
    } else {
      if !viewModel.selectedMessages.isEmpty {
        multiForwardForward(depth)
      }
    }
  }

  /// 合并转发
  /// - Parameter depth: 层数
  open func multiForwardForward(_ depth: Int) {
    weak var weakSelf = self
    if IMKitClient.instance.getConfigCenter().teamEnable {
      let userAction = UIAlertAction(title: chatLocalizable("contact_user"), style: .default) { action in
        weakSelf?.forwardMessageToUser(isMultiForward: true, depth: depth) {
          weakSelf?.cancelMutilSelect()
        }
      }

      let teamAction = UIAlertAction(title: chatLocalizable("team"), style: .default) { action in
        weakSelf?.forwardMessageToTeam(isMultiForward: true, depth: depth) {
          weakSelf?.cancelMutilSelect()
        }
      }

      let cancelAction = UIAlertAction(title: chatLocalizable("cancel"), style: .cancel)
      showActionSheet([teamAction, userAction, cancelAction])
    } else {
      forwardMessageToUser(isMultiForward: true, depth: depth) {
        weakSelf?.cancelMutilSelect()
      }
    }
  }

  /// 点击逐条转发
  open func didClickSingleForwardButton() {
    // 校验网络
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    if viewModel.selectedMessages.count > customSingleForwardLimitCount {
      showToast(String(format: chatLocalizable("per_item_forward_limit"), customSingleForwardLimitCount))
      return
    }

    var invalidMessages = [V2NIMMessage]()
    for msg in viewModel.selectedMessages {
      if msg.messageType == .MESSAGE_TYPE_AUDIO ||
        msg.messageType == .MESSAGE_TYPE_CALL ||
        msg.sendingState == .MESSAGE_SENDING_STATE_FAILED
//        || msg.isBlackListed
      {
        invalidMessages.append(msg)
      }
    }

    if invalidMessages.count > 0 {
      showAlert(title: chatLocalizable("exception_description"),
                message: chatLocalizable("exist_invalid")) { [self] in
        filterSelectedMessage(invalidMessages: invalidMessages)
        if !viewModel.selectedMessages.isEmpty {
          singleForward()
        }
      }
    } else {
      if !viewModel.selectedMessages.isEmpty {
        singleForward()
      }
    }
  }

  /// 逐条转发
  open func singleForward() {
    weak var weakSelf = self
    if IMKitClient.instance.getConfigCenter().teamEnable {
      let userAction = UIAlertAction(title: chatLocalizable("contact_user"), style: .default) { action in
        weakSelf?.forwardMessageToUser {
          weakSelf?.cancelMutilSelect()
        }
      }

      let teamAction = UIAlertAction(title: chatLocalizable("team"), style: .default) { action in
        weakSelf?.forwardMessageToTeam {
          weakSelf?.cancelMutilSelect()
        }
      }

      let cancelAction = UIAlertAction(title: chatLocalizable("cancel"), style: .cancel)
      showActionSheet([teamAction, userAction, cancelAction])
    } else {
      forwardMessageToUser {
        weakSelf?.cancelMutilSelect()
      }
    }
  }

  /// 多选删除
  open func didClickDeleteButton() {
    // 校验网络
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    // 批量删除条数限制
    if viewModel.selectedMessages.count > deleteMessagesLimitCount {
      showToast(String(format: chatLocalizable("selete_messages_limit"), deleteMessagesLimitCount))
      return
    }

    showAlert(message: chatLocalizable("message_delete_confirm")) { [weak self] in
      if let messages = self?.viewModel.selectedMessages {
        self?.viewModel.deleteMessages(messages: messages) { error in
          self?.showErrorToast(error)
        }
      }
      self?.cancelMutilSelect()
    }
  }
}

// MARK: ChatBaseCellDelegate

extension ChatViewController: ChatBaseCellDelegate {
  open func didLongPressAvatar(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    // 非群聊
    // 禁言
    // 多选
    guard V2NIMConversationIdUtil.conversationType(viewModel.conversationId) == .CONVERSATION_TYPE_TEAM,
          !isMute,
          !isMutilSelect else {
      return
    }

    var addText = ""
    var accid = ""

    if let m = model, let senderId = m.message?.senderId {
      accid = senderId
      let (name, _) = ChatTeamCache.shared.getShowName(senderId, false)
      addText += name
      addText = "@" + addText + ""

      addToAtUsers(addText: addText, accid: accid, true)
    }
  }

  open func didTapAvatarView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    // 多选模式下屏蔽头像点击事件
    if isMutilSelect {
      return
    }
    didTapHeadPortrait(model: model)
  }

  open func didTapMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?, _ replyModel: MessageModel?) {
    if let tapClick = NEKitChatConfig.shared.ui.messageItemClick {
      tapClick(cell, model)
      return
    }

    // 已撤回消息不可点击
    // 多选模式下屏蔽消息点击事件
    guard model?.isRevoked == false,
          !isMutilSelect else {
      return
    }

    if var replyModel = replyModel as? MessageContentModel {
      var index = -1
      for (i, m) in viewModel.messages.enumerated() {
        if replyModel.message?.messageClientId == m.message?.messageClientId {
          index = i
          if let m = m as? MessageContentModel {
            replyModel = m
          }
          break
        }
      }

      let replyCell = tableView.cellForRow(at: IndexPath(row: index, section: 0))

      didTapMessage(replyCell, replyModel, index)

    } else {
      didTapMessage(cell, model)
    }
  }

  open func didLongPressMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    didLongTouchMessageView(cell, model)
  }

  open func didTapResendView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    if isMutilSelect {
      return
    }

    if playingCell?.messageId == model?.message?.messageClientId {
      if playingCell?.isPlaying == true {
        stopPlay()
      }
    }

    if let m = model, let msg = m.message {
      let messages = viewModel.messages
      var index = -1
      for i in 0 ..< messages.count {
        if let message = messages[i].message {
          if message.messageClientId == msg.messageClientId {
            index = i
            break
          }
        }
      }

      if index >= 0 {
        viewModel.messages.remove(at: index)
        tableViewDeleteIndexs([IndexPath(row: index, section: 0)])
      }

      viewModel.sendMessage(message: msg) { error in
        if let err = error {
          print("resend message error: \(err.localizedDescription)")
        }
      }
    }
  }

  open func didTapReeditButton(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    // 禁言下不可重新编辑
    // 多选下不可重新编辑
    guard !isMute,
          !isMutilSelect else {
      return
    }

    if model?.type == .revoke, let message = model?.message,
       message.messageType == .MESSAGE_TYPE_TEXT || message.messageType == .MESSAGE_TYPE_CUSTOM {
      if message.messageType == .MESSAGE_TYPE_CUSTOM {
        guard let customType = NECustomAttachment.typeOfCustomMessage(message.attachment),
              customType == customRichTextType else {
          return
        }
      }
      let data = NECustomAttachment.dataOfCustomMessage(model?.message?.attachment)

      let time = message.createTime
      let date = Date()
      let currentTime = date.timeIntervalSince1970
      if currentTime - time >= 60 * 2 {
        showToast(chatLocalizable("editable_time_expired"))
        tableViewReload()
        return
      }
      if let remoteExt = getDictionaryFromJSONString(message.serverExtension ?? ""), remoteExt[keyReplyMsgKey] != nil {
        viewModel.operationModel = model
        showReplyMessageView(isReEdit: true)
      } else {
        closeReply(button: nil)
      }

      var attributeStr: NSMutableAttributedString?
      var text = ""
      if message.messageType == .MESSAGE_TYPE_TEXT, let txt = message.text {
        text = txt
      } else if message.messageType == .MESSAGE_TYPE_CUSTOM, let body = data?["body"] as? String {
        text = body
      }

      attributeStr = NSMutableAttributedString(string: text)
      attributeStr?.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.ne_darkText, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], range: NSMakeRange(0, text.utf16.count))

      if let remoteExt = getDictionaryFromJSONString(message.serverExtension ?? ""),
         let dic = remoteExt[yxAtMsg] as? [String: AnyObject] {
        for (key, value) in dic {
          if let contentDic = value as? [String: AnyObject] {
            if let array = contentDic[atSegmentsKey] as? [AnyObject] {
              if let models = NSArray.yx_modelArray(with: MessageAtInfoModel.self, json: array) as? [MessageAtInfoModel] {
                for model in models {
                  if var text = contentDic[atTextKey] as? String {
                    if text.last == " " {
                      text = String(text.prefix(text.count - 1))
                    }
                    chatInputView.nickAccidDic[text] = key
                  }

                  if (attributeStr?.length ?? 0) > model.end {
                    attributeStr?.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.ne_blueText, range: NSMakeRange(model.start, model.end - model.start))
                  }
                }
              }
            }
          }
        }
      }

      if let title = data?["title"] as? String {
        // 切换换行输入框
        // 标题填入
        chatInputView.titleField.text = title
        expandButtonDidClick()
      } else {
        chatInputView.titleField.text = nil
        if chatInputView.chatInpuMode != .normal {
          didHideMultipleButtonClick()
        }
      }

      chatInputView.textView.attributedText = attributeStr
      chatInputView.textView.becomeFirstResponder()
    }
  }

  open func didTapReadView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    if isMutilSelect {
      return
    }

    // 校验网络
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    if let msg = model?.message, msg.conversationType == .CONVERSATION_TYPE_TEAM {
      let readVC = getReadView(msg, viewModel.sessionId)
      navigationController?.pushViewController(readVC, animated: true)
    }
  }

  open func didTapSelectButton(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    viewModel.selectedMessages.removeAll(where: { $0.messageClientId == model?.message?.messageClientId })
    if model?.isSelected == true, let msg = model?.message {
      viewModel.selectedMessages.append(msg)
    }
  }

  open func getReadView(_ message: V2NIMMessage, _ teamId: String) -> NEBaseReadViewController {
    ReadViewController(message: message, teamId: teamId)
  }

  open func loadDataFinish() {}

  // MARK: call kit noti

  open func didShowCallView() {
    stopPlay()
  }

  open func didDismissCallView() {}

  // MARK: mutile line delegate

  open func expandButtonDidClick() {
    chatInputView.textView.resignFirstResponder()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: DispatchWorkItem(block: {
      self.scrollTableViewToBottom()
    }))
    operationView?.removeFromSuperview()
  }

  open func didHideMultipleButtonClick() {
    chatInputView.restoreNormalInputStyle()
    chatInputView.textView.resignFirstResponder()
    chatInputView.titleField.resignFirstResponder()
  }

  open func titleTextDidClearEmpty() {}

  open func didSendFinishAndCheckoutInput() {
    if chatInputView.chatInpuMode != .normal {
      chatInputView.chatInpuMode = .normal
      chatInputView.restoreNormalInputStyle()
      if chatInputView.textView.isFirstResponder || chatInputView.titleField.isFirstResponder {
        chatInputView.textView.becomeFirstResponder()
      }
      didHideMultiple()
    }
  }

  open func didHideMultiple() {}
}
