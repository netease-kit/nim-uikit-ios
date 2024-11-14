
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import AVFoundation
import MJRefresh
import NEChatKit
import NECommonKit
import NECommonUIKit
import NECoreIMKit
import NECoreKit
import NIMSDK
import Photos
import UIKit
import WebKit

@objcMembers
open class ChatViewController: ChatBaseViewController, UINavigationControllerDelegate,
  ChatInputViewDelegate, ChatViewModelDelegate, NIMMediaManagerDelegate,
  MessageOperationViewDelegate, UITableViewDataSource,
  UITableViewDelegate, UIDocumentPickerDelegate, UIDocumentInteractionControllerDelegate, CLLocationManagerDelegate, UITextViewDelegate, ChatInputMultilineDelegate, UIImagePickerControllerDelegate {
  private let tag = "ChatViewController"
  private let kCallKitDismissNoti = "kCallKitDismissNoti"
  private let kCallKitShowNoti = "kCallKitShowNoti"
  public var titleContent = ""

  public var viewmodel: ChatViewModel
  let interactionController = UIDocumentInteractionController()
  private lazy var manager = CLLocationManager()
  private var playingCell: ChatAudioCellProtocol?
  private var playingModel: MessageAudioModel?
  private var timer: Timer?
  private var isFile: Bool? // 是否以文件形式发送
  public var isCurrentPage = true
  public var isMute = false // 是否禁言
  private var isMutilSelect = false // 是否多选模式

  public var operationCellFilter: [OperationType]? // 消息长按菜单全局过滤列表
  public var cellRegisterDic = [String: UITableViewCell.Type]()
  private var needMarkReadMsgs = [NIMMessage]()
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

  public init(session: NIMSession) {
    viewmodel = ChatViewModel(session: session, anchor: nil)
    super.init(nibName: nil, bundle: nil)

    NEKeyboardManager.shared.enable = false
    NEKeyboardManager.shared.enableAutoToolbar = false
    NIMSDK.shared().mediaManager.add(self)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    NEKeyboardManager.shared.enable = false
    NEKeyboardManager.shared.shouldResignOnTouchOutside = false
    isCurrentPage = true
    markNeedReadMsg()
    getSessionInfo(session: viewmodel.session)
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
    viewmodel.delegate = self
    commonUI()
    addObseve()
    weak var weakSelf = self
    viewmodel.fetchPinMessage {
      weakSelf?.loadData()
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
    title = viewmodel.session.sessionId
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

  public func onTeamMemberChange(team: NIMTeam) {}

  override open func backEvent() {
    super.backEvent()
    cleanDelegate()
  }

  // load data的时候会调用
  open func getSessionInfo(session: NIMSession) {}

  /// 点击头像回调
  /// - Parameter model: cell模型
  open func didTapHeadPortrait(model: MessageContentModel?) {
    if let isOut = model?.message?.isOutgoingMsg, isOut {
      Router.shared.use(
        MeSettingRouter,
        parameters: ["nav": navigationController as Any],
        closure: nil
      )
      return
    }
    if let uid = model?.message?.from {
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
    guard let items = viewmodel.avalibleOperationsForMessage(model) else {
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

    viewmodel.operationModel = model
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
         msg.isOutgoingMsg {
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
    let content = UIView()
    content.translatesAutoresizingMaskIntoConstraints = false
    content.backgroundColor = UIColor.clear
    content.addSubview(tableView)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: content.topAnchor),
      tableView.leftAnchor.constraint(equalTo: content.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: content.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: content.bottomAnchor),
    ])

    return content
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

  deinit {
    NELog.infoLog(className(), desc: "deinit")
    cleanDelegate()
  }

  func cleanDelegate() {
    NIMSDK.shared().mediaManager.remove(self)
    viewmodel.delegate = nil
  }

  // MARK: objc 方法

  func getUserSettingViewController() -> NEBaseUserSettingViewController {
    UserSettingViewController(userId: viewmodel.session.sessionId)
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

    if viewmodel.session.sessionType == .team {
      Router.shared.use(
        TeamSettingViewRouter,
        parameters: ["nav": navigationController as Any,
                     "teamid": viewmodel.session.sessionId],
        closure: nil
      )
    } else if viewmodel.session.sessionType == .P2P {
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
        layoutInputView(offset: 0)
      }
    }
  }

  // MARK: private 方法

  func loadData() {
    weak var weakSelf = self

    viewmodel.queryRoamMsgHasMoreTime_v2 { error, historyEnd, newEnd, index in
      NELog.infoLog(
        ModuleName + " " + self.tag,
        desc: #function + "CALLBACK queryRoamMsgHasMoreTime_v2 " + (error?.localizedDescription ?? "no error")
      )

      if let ms = weakSelf?.viewmodel.messages, ms.count > 0 {
        weakSelf?.didRefreshTable()
        if weakSelf?.viewmodel.isHistoryChat == true {
          let indexPath = IndexPath(row: index, section: 0)
          weakSelf?.tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
          if newEnd > 0 {
            weakSelf?.addBottomLoadMore()
          }
        } else {
          if let tempArray = weakSelf?.viewmodel.messages, tempArray.count > 0 {
            weakSelf?.tableView.scrollToRow(
              at: IndexPath(row: tempArray.count - 1, section: 0),
              at: .bottom,
              animated: false
            )
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
    viewmodel.dropDownRemoteRefresh { error, count, messages in
      NELog.infoLog(
        ModuleName + " " + self.tag,
        desc: #function + "CALLBACK dropDownRemoteRefresh " + (error?.localizedDescription ?? "no error")
      )

      weakSelf?.tableView.reloadData()
      if count > 0 {
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
    viewmodel.pullRemoteRefresh { error, count, datas in
      NELog.infoLog(
        ModuleName + " " + self.tag,
        desc: #function + "CALLBACK pullRemoteRefresh " + (error?.localizedDescription ?? "no error")
      )
      if count <= 0 {
        weakSelf?.removeBottomLoadMore()
      } else {
        weakSelf?.tableView.mj_footer?.endRefreshing()
        weakSelf?.didRefreshTable()
      }
    }
  }

  func addObseve() {
    NotificationCenter.default.addObserver(self, selector: #selector(didRefreshTable), name: NENotificationName.updateFriendInfo, object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(keyBoardWillShow(_:)),
                                           name: UIResponder.keyboardWillShowNotification,
                                           object: nil)

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(keyBoardWillHide(_:)),
                                           name: UIResponder.keyboardWillHideNotification,
                                           object: nil)

    NotificationCenter.default.addObserver(self, selector: #selector(didShowCallView), name: Notification.Name(kCallKitShowNoti), object: nil)

    NotificationCenter.default.addObserver(self, selector: #selector(appEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)

    NotificationCenter.default.addObserver(self, selector: #selector(appEnterForegournd), name: UIApplication.willEnterForegroundNotification, object: nil)

    let tap = UITapGestureRecognizer(target: self, action: #selector(viewTap))
    tap.delegate = self
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)

    if let pan = navigationController?.interactivePopGestureRecognizer {
      tableView.panGestureRecognizer.require(toFail: pan)
    }
  }

  open func addBottomLoadMore() {
    tableView.mj_footer = MJRefreshBackNormalFooter(
      refreshingTarget: self,
      refreshingAction: #selector(loadCloserToNowData)
    )
  }

  open func removeBottomLoadMore() {
    tableView.mj_footer?.endRefreshingWithNoMoreData()
    tableView.mj_footer = nil
    viewmodel.isHistoryChat = false // 转为普通聊天页面
  }

  func markNeedReadMsg() {
    if isCurrentPage, needMarkReadMsgs.count > 0 {
      viewmodel.markRead(messages: needMarkReadMsgs) { error in
        NELog.infoLog(
          ModuleName + " " + self.tag,
          desc: #function + "CALLBACK markRead " + (error?.localizedDescription ?? "no error")
        )
      }
      needMarkReadMsgs = [NIMMessage]()
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

    layoutInputViewWithAnimation(offset: keyboardRect.size.height, animationDuration)
    weak var weakSelf = self
    UIView.animate(withDuration: 0.25, animations: {
      weakSelf?.view.layoutIfNeeded()
    })

    // 键盘已经弹出
    if oldKeyboardRect == keyboardRect {
      return
    }

    scrollTableViewToBottom()
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
    NELog.infoLog(className(), desc: "self.viewmodel.messages.count\(viewmodel.messages.count)")
    NELog.infoLog(className(), desc: "self.tableView.numberOfRows(inSection: 0)\(tableView.numberOfRows(inSection: 0))")
    if viewmodel.messages.count > 0 {
      weak var weakSelf = self
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: DispatchWorkItem(block: {
        if let row = weakSelf?.tableView.numberOfRows(inSection: 0) {
          let indexPath = IndexPath(row: row - 1, section: 0)
          weakSelf?.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
      }))
    }
  }

  open func layoutInputView(offset: CGFloat) {
    layoutInputViewWithAnimation(offset: offset)
  }

  open func layoutInputViewWithAnimation(offset: CGFloat, _ animation: CGFloat = 0.1) {
    NELog.infoLog(className(), desc: "normal height : \(normalInputHeight) normal offset: \(normalOffset) offset : \(offset)")
    weak var weakSelf = self
    var topValue = normalInputHeight
    if chatInputView.chatInpuMode != .multipleReturn {
      topValue -= normalOffset
    }
    if offset == 0 {
      chatInputView.contentSubView?.isHidden = true
      chatInputView.currentButton?.isSelected = false
    }
    UIView.animate(withDuration: animation, animations: {
      weakSelf?.bottomViewTopAnchor?.constant = -topValue - offset
    })
  }

  //    MARK: ChatInputViewDelegate

  open func sendText(text: String?, attribute: NSAttributedString?) {
    if let title = chatInputView.titleField.text, title.trimmingCharacters(in: .whitespaces).isEmpty == false {
      // 换行消息
      NELog.infoLog(className(), desc: "换行消息: \(title)")
      var dataDic = [String: Any]()
      dataDic["title"] = title
      if let t = text?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty {
        dataDic["body"] = text
      }

      var attachDic = [String: Any]()
      attachDic["type"] = customRichTextType
      attachDic["data"] = dataDic

      let attachment = NECustomAttachment(customType: customRichTextType, data: attachDic)
      let remoteExt = chatInputView.getRemoteExtension(attribute)

      weak var weakSelf = self
      if viewmodel.isReplying, let msg = viewmodel.operationModel?.message {
        viewmodel.replyMessageWithoutThread(message:
          MessageUtils.customMessage(attachment: attachment,
                                     remoteExt: remoteExt,
                                     apnsContent: title),
          target: msg) { [weak self] error in
            NELog.infoLog(
              ModuleName + " " + (self?.tag ?? "ChatViewController"),
              desc: #function + "CALLBACK replyMessage " + (error?.localizedDescription ?? "no error")
            )
            if error != nil {
              weakSelf?.showErrorToast(error)
            } else {
              weakSelf?.closeReply(button: nil)
            }
            self?.chatInputView.titleField.text = nil
            self?.chatInputView.textView.text = nil
            self?.didSendFinishAndCheckoutInput()
          }
      } else {
        viewmodel.sendCustomMessage(attachment: attachment,
                                    remoteExt: remoteExt,
                                    apnsConstent: title) { [weak self] error in
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
      showToast(chatLocalizable("null_message_not_support"))
      return
    }
    guard let content = text, content.count > 0 else {
      return
    }
    let remoteExt = chatInputView.getRemoteExtension(attribute)
    chatInputView.clearAtCache()
    weak var weakSelf = self
    if viewmodel.isReplying, let msg = viewmodel.operationModel?.message {
      viewmodel.replyMessageWithoutThread(message: MessageUtils.textMessage(text: content, remoteExt: remoteExt), target: msg) { [weak self] error in
        NELog.infoLog(
          ModuleName + " " + (self?.tag ?? "ChatViewController"),
          desc: #function + "CALLBACK replyMessage " + (error?.localizedDescription ?? "no error")
        )
        if error != nil {
          weakSelf?.showErrorToast(error)
        } else {
          weakSelf?.closeReply(button: nil)
        }
        weakSelf?.didSendFinishAndCheckoutInput()
      }

    } else {
      viewmodel.sendTextMessage(text: content, remoteExt: remoteExt) { [weak self] error in
        NELog.infoLog(
          ModuleName + " " + (self?.tag ?? "ChatViewController"),
          desc: #function + "CALLBACK sendTextMessage " + (error?.localizedDescription ?? "no error")
        )
        weakSelf?.showErrorToast(error)
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
    } else if let type = cell.cellData?.type, type == .photo {
      willSelectItem(button: nil, index: 2)
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
    var param = [String: AnyObject]()
    param["remoteUserAccid"] = viewmodel.session.sessionId as AnyObject
    param["currentUserAccid"] = NIMSDK.shared().loginManager.currentAccount() as AnyObject
    param["remoteShowName"] = titleContent as AnyObject
    if let user = viewmodel.repo.getUserInfo(userId: viewmodel.session.sessionId), let avatar = user.userInfo?.avatarUrl {
      param["remoteAvatar"] = avatar as AnyObject
    }

    let videoCallAction = UIAlertAction(title: chatLocalizable("video_call"), style: .default) { _ in
      param["type"] = NSNumber(integerLiteral: 2) as AnyObject
      Router.shared.use(CallViewRouter, parameters: param)
    }
    let audioCallAction = UIAlertAction(title: chatLocalizable("audio_call"), style: .default) { _ in
      param["type"] = NSNumber(integerLiteral: 1) as AnyObject
      Router.shared.use(CallViewRouter, parameters: param)
    }
    let cancelAction = UIAlertAction(title: chatLocalizable("cancel"),
                                     style: .cancel) { action in
    }
    showActionSheet([videoCallAction, audioCallAction, cancelAction])
  }

  func didToSearchLocationView() {
    let ctrl = NEDetailMapController(type: .search)
    navigationController?.pushViewController(ctrl, animated: true)
    weak var weakSelf = self
    ctrl.completion = { model in
      NELog.infoLog(self.className(), desc: "position : \(model.yx_modelToJSONString() ?? "")")
      weakSelf?.viewmodel.sendLocationMessage(model) { error in
        weakSelf?.showErrorToast(error)
      }
    }
  }

  open func textChanged(text: String) -> Bool {
    if text == "@" {
      // 做p2p类型判断
      if viewmodel.session.sessionType == .P2P {
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
    viewmodel.sendInputTypingEndState()
  }

  open func textFieldDidBeginEditing(_ text: String?) {
    checkAndSendTypingState()
  }

  open func textFieldDidChange(_ text: String?) {
    checkAndSendTypingState()
  }

  func checkAndSendTypingState() {
    if chatInputView.chatInpuMode == .normal {
      if let content = chatInputView.textView.text, content.count > 0 {
        viewmodel.sendInputTypingState()
      } else {
        viewmodel.sendInputTypingEndState()
      }
    } else {
      var title = ""
      var content = ""

      if let titleText = chatInputView.titleField.text {
        title = titleText
      }

      if let contentText = chatInputView.textView.text {
        content = contentText
      }
      if title.count <= 0, content.count <= 0 {
        viewmodel.sendInputTypingEndState()
      } else {
        viewmodel.sendInputTypingState()
      }
    }
  }

  open func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    textView.typingAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ne_darkText, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
    return true
  }

  open func willSelectItem(button: UIButton?, index: Int) {
    operationView?.removeFromSuperview()
    if index == 2 || button?.isSelected == true {
      if index == 0 {
        // 语音
        layoutInputView(offset: bottomExanpndHeight)
        scrollTableViewToBottom()
      } else if index == 1 {
        // emoji
        layoutInputView(offset: bottomExanpndHeight)
        scrollTableViewToBottom()
      } else if index == 2 {
        // 相册
        isFile = false
        goPhotoAlbumWithVideo(self) { [weak self] in
          if NIMSDK.shared().mediaManager.isPlaying() {
            NIMSDK.shared().mediaManager.stopPlay()
            self?.playingCell?.stopAnimation(byRight: self?.playingModel?.message?.isOutgoingMsg ?? true)
            self?.playingModel?.isPlaying = false
          }
        }
      } else if index == 3 {
        // 更多
        layoutInputView(offset: bottomExanpndHeight)
        scrollTableViewToBottom()
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
    let camera = UIAlertAction(title: chatLocalizable("take_photo"), style: .default) { action in
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
    present(imagePickerVC, animated: true) {}
  }

  open func takePhoto() {
    let imagePickerVC = UIImagePickerController()
    imagePickerVC.delegate = self
    imagePickerVC.allowsEditing = false
    imagePickerVC.sourceType = .camera
    present(imagePickerVC, animated: true) {}
  }

  open func clearAtRemind() {
    let sessionId = viewmodel.session.sessionId
    let param = ["sessionId": sessionId]
    Router.shared.use("ClearAtMessageRemind", parameters: param, closure: nil)
  }

  open func sendMediaMessage(didFinishPickingMediaWithInfo info: [UIImagePickerController
      .InfoKey: Any]) {
    var imageName = "IMG_0001"
    if isFile == true,
       let imgUrl = info[.referenceURL] as? URL {
      let fetchRes = PHAsset.fetchAssets(withALAssetURLs: [imgUrl], options: nil)
      let asset = fetchRes.firstObject
      if let fileName = asset?.value(forKey: "filename") as? String {
        imageName = fileName
      }
    }

    if let url = info[.mediaURL] as? URL {
      // video
      print("image picker video : url", url)
      weak var weakSelf = self
      if isFile == true {
        copyFileToSend(url: url, displayName: imageName)
      } else {
        viewmodel.sendVideoMessage(url: url) { error in
          NELog.infoLog(
            ModuleName + " " + (weakSelf?.tag ?? "ChatViewController"),
            desc: #function + "CALLBACK sendVideoMessage " + (error?.localizedDescription ?? "no error")
          )
          weakSelf?.showErrorToast(error)
        }
      }
      return
    }

    guard let image = info[.originalImage] as? UIImage else {
      showToast(chatLocalizable("image_is_nil"))
      return
    }

    if isFile == true,
       let imgData = image.pngData() {
      let imgSize_MB = Double(imgData.count) / 1e6
      NELog.infoLog(ModuleName + " " + tag, desc: #function + "imgSize_MB: \(imgSize_MB) MB")
      if imgSize_MB > NEKitChatConfig.shared.ui.fileSizeLimit {
        showToast(String(format: chatLocalizable("fileSize_over_limit"), "\(NEKitChatConfig.shared.ui.fileSizeLimit)"))
      } else {
        viewmodel.sendFileMessage(data: imgData, displayName: imageName) { [weak self] error in
          NELog.infoLog(
            ModuleName + " " + (self?.tag ?? "ChatViewController"),
            desc: #function + "CALLBACK sendFileMessage" + (error?.localizedDescription ?? "no error")
          )
          if error != nil {
            self?.view.makeToast(error!.localizedDescription)
          }
        }
      }
    } else {
      if let url = info[.referenceURL] as? URL {
        if url.absoluteString.hasSuffix("ext=GIF") == true {
          // GIF 需要特殊处理
          let imageAsset: PHAsset?
          if #available(iOS 11.0, *) {
            imageAsset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset
          } else {
            imageAsset = PHAsset.fetchAssets(withALAssetURLs: [url], options: nil).firstObject
          }
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
                  weakSelf?.viewmodel.sendImageMessage(path: temUrl.path) { error in
                    NELog.infoLog(
                      ModuleName + " " + (weakSelf?.tag ?? "ChatViewController"),
                      desc: #function + "CALLBACK sendImageMessage " + (error?.localizedDescription ?? "no error")
                    )
                    if error != nil {
                      weakSelf?.view.makeToast(error?.localizedDescription)
                    }
                  }
                }
              } catch {
                NELog.infoLog(ModuleName, desc: #function + "write tem gif data error : \(error.localizedDescription)")
              }
            }
          }
          return
        }
      }

      viewmodel.sendImageMessage(image: image) { [weak self] error in
        NELog.infoLog(
          ModuleName + " " + (self?.tag ?? "ChatViewController"),
          desc: #function + "CALLBACK sendImageMessage " + (error?.localizedDescription ?? "no error")
        )
        if error != nil {
          self?.view.makeToast(error?.localizedDescription)
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

  func copyFileToSend(url: URL, displayName: String) {
    let desPath = NSTemporaryDirectory() + "\(url.lastPathComponent)"
    let dirUrl = URL(fileURLWithPath: desPath)
    if !FileManager.default.fileExists(atPath: desPath) {
      NELog.infoLog(ModuleName + " " + tag, desc: #function + "file not exist")
      do {
        try FileManager.default.copyItem(at: url, to: dirUrl)
      } catch {
        NELog.errorLog(ModuleName + " " + tag, desc: #function + "copyItem [\(desPath)] ERROR: \(error)")
      }
    }
    if FileManager.default.fileExists(atPath: desPath) {
      NELog.infoLog(ModuleName + " " + tag, desc: #function + "fileExists")
      do {
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: desPath)
        if let size_B = fileAttributes[FileAttributeKey.size] as? Double {
          let size_MB = size_B / 1e6
          if size_MB > NEKitChatConfig.shared.ui.fileSizeLimit {
            showToast(String(format: chatLocalizable("fileSize_over_limit"), "\(NEKitChatConfig.shared.ui.fileSizeLimit)"))
            try? FileManager.default.removeItem(atPath: desPath)
          } else {
            viewmodel.sendFileMessage(filePath: desPath, displayName: displayName) { [weak self] error in
              NELog.infoLog(
                ModuleName + " " + (self?.tag ?? "ChatViewController"),
                desc: #function + "CALLBACK sendFileMessage " + (error?.localizedDescription ?? "no error")
              )
              if error != nil {
                self?.view.makeToast(error!.localizedDescription)
              }
            }
          }
        }
      } catch {
        NELog.errorLog(ModuleName + " " + tag, desc: #function + "get file size error: \(error)")
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
      NELog.errorLog(ModuleName + " " + tag, desc: #function + "fileUrlAuthozied FAILED")
    }
  }

  // MARK: UIDocumentInteractionControllerDelegate

  open func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
    self
  }

  open func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    controller.dismiss(animated: true)
  }

  //    MARK: ChatViewModelDelegate

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

  open func onRecvMessages(_ messages: [NIMMessage]) {
    operationView?.removeFromSuperview()
    insertRows()
    if isCurrentPage,
       UIApplication.shared.applicationState == .active {
      viewmodel.markRead(messages: messages) { error in
        NELog.infoLog(
          ModuleName + " " + self.tag,
          desc: #function + "CALLBACK markRead " + (error?.localizedDescription ?? "no error")
        )
      }
    } else {
      needMarkReadMsgs += messages
    }
  }

  open func willSend(_ message: NIMMessage) {
    insertRows()
  }

  open func send(_ message: NIMMessage, progress: Float) {}

  open func send(_ message: NIMMessage, didCompleteWithError error: Error?) {
    if indexPathsWithMessags([message]).count > 0 {
      tableViewReloadIndexs(indexPathsWithMessags([message]))
    }
  }

  private func indexPathsWithMessags(_ messages: [NIMMessage]) -> [IndexPath] {
    var indexPaths = [IndexPath]()
    for messageModel in messages {
      for (i, model) in viewmodel.messages.enumerated() {
        if model.message?.messageId == messageModel.messageId {
          indexPaths.append(IndexPath(row: i, section: 0))
        }
      }
    }
    return indexPaths
  }

  open func onDeleteMessage(_ message: NIMMessage, atIndexs: [IndexPath], reloadIndex: [IndexPath]) {
    if atIndexs.isEmpty {
      return
    }
    viewmodel.selectedMessages.removeAll(where: { $0.messageId == message.messageId })
    operationView?.removeFromSuperview()
    tableViewDeleteIndexs(atIndexs)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: DispatchWorkItem(block: { [weak self] in
      self?.tableViewReloadIndexs(reloadIndex)
    }))
  }

  open func updateDownloadProgress(_ message: NIMMessage, atIndex: IndexPath, progress: Float) {
    tableViewUpdateDownload(atIndex)
  }

  open func onRevokeMessage(_ message: NIMMessage, atIndexs: [IndexPath]) {
    if atIndexs.isEmpty {
      return
    }
    viewmodel.selectedMessages.removeAll(where: { $0.messageId == message.messageId })
    operationView?.removeFromSuperview()
    NELog.infoLog(className(), desc: "on revoke message at indexs \(atIndexs)")
    tableViewReloadIndexs(atIndexs)
  }

  open func onAddMessagePin(_ message: NIMMessage, atIndexs: [IndexPath]) {
    tableViewReloadIndexs(atIndexs)
  }

  open func onRemoveMessagePin(_ message: NIMMessage, atIndexs: [IndexPath]) {
    tableViewReloadIndexs(atIndexs)
  }

  open func tableViewDeleteIndexs(_ indexs: [IndexPath]) {
    tableView.beginUpdates()
    tableView.deleteRows(at: indexs, with: .none)
    tableView.endUpdates()
  }

  open func tableViewReloadIndexs(_ indexs: [IndexPath]) {
    weak var weakSelf = self
    if #available(iOS 11.0, *) {
      tableView.performBatchUpdates {
        weakSelf?.tableView.reloadRows(at: indexs, with: .none)
      }
    } else {
      tableView.beginUpdates()
      tableView.reloadRows(at: indexs, with: .none)
      tableView.endUpdates()
    }

    for index in indexs {
      if index.row == tableView.numberOfRows(inSection: 0) - 1 {
        tableView.scrollToRow(at: index, at: .bottom, animated: true)
      }
    }
  }

  open func didReadedMessageIndexs() {
    didRefreshTable()
  }

  open func tableViewUpdateDownload(_ index: IndexPath) {
    if #available(iOS 11.0, *) {
      tableView.performBatchUpdates {
        tableView.reloadRows(at: [index], with: .none)
      }
    } else {
      tableView.beginUpdates()
      tableView.reloadRows(at: [index], with: .none)
      tableView.endUpdates()
    }
  }

  open func didRefreshTable() {
    getSessionInfo(session: viewmodel.session)
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

  func startPlaying(audioMessage: NIMMessage?, isSend: Bool) {
    guard let message = audioMessage, let audio = message.messageObject as? NIMAudioObject else {
      return
    }
    playingCell?.startAnimation(byRight: isSend)
    if let path = audio.path, FileManager.default.fileExists(atPath: path) {
      NELog.infoLog(className(), desc: #function + " play path : " + path)

      if viewmodel.getHandSetEnable() == true {
        NIMSDK.shared().mediaManager.switch(.receiver)
      } else {
        NIMSDK.shared().mediaManager.switch(.speaker)
      }
      NIMSDK.shared().mediaManager.play(path)
    } else {
      NELog.infoLog(className(), desc: #function + " audio path is empty, play url : " + (audio.url ?? ""))
      playingCell?.stopAnimation(byRight: isSend)
      ChatMessageHelper.downloadAudioFile(message: message)
    }
  }

  private func startPlay(cell: ChatAudioCellProtocol?, model: MessageAudioModel?) {
    guard let audio = model?.message?.messageObject as? NIMAudioObject,
          let isSend = model?.message?.isOutgoingMsg else {
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
      playingCell?.startAnimation(byRight: playingModel?.message?.isOutgoingMsg ?? true)
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
    NIMSDK.shared().mediaManager.switch(viewmodel.getHandSetEnable() ? .receiver : .speaker)
    if let e = error {
      showErrorToast(error)
      // stop
      playingCell?.stopAnimation(byRight: playingModel?.message?.isOutgoingMsg ?? true)
      playingModel?.isPlaying = false
    }
  }

  open func playAudio(_ filePath: String, didCompletedWithError error: Error?) {
    print(#function + "\(error?.localizedDescription ?? "")")
    showErrorToast(error)
    // stop
    playingCell?.stopAnimation(byRight: playingModel?.message?.isOutgoingMsg ?? true)
    playingModel?.isPlaying = false
  }

  open func stopPlayAudio(_ filePath: String, didCompletedWithError error: Error?) {
    print(#function + "\(error?.localizedDescription ?? "")")
    showErrorToast(error)
    playingCell?.stopAnimation(byRight: playingModel?.message?.isOutgoingMsg ?? true)
    playingModel?.isPlaying = false
  }

  open func playAudio(_ filePath: String, progress value: Float) {}

  open func playAudioInterruptionEnd() {
    print(#function)
    playingCell?.stopAnimation(byRight: playingModel?.message?.isOutgoingMsg ?? true)
    playingModel?.isPlaying = false
  }

  open func playAudioInterruptionBegin() {
    print(#function)
    // stop play
    playingCell?.stopAnimation(byRight: playingModel?.message?.isOutgoingMsg ?? true)
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
      viewmodel.sendAudioMessage(filePath: fp) { error in
        NELog.infoLog(
          ModuleName + " " + self.tag,
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

  open func recordAudioInterruptionBegin() {
    print(#function)
  }

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
    if oldRows == viewmodel.messages.count {
      tableView.reloadData()
      return
    }
    var indexs = [IndexPath]()
    for (i, _) in viewmodel.messages.enumerated() {
      if i >= oldRows {
        indexs.append(IndexPath(row: i, section: 0))
      }
    }

    if !indexs.isEmpty {
      if #available(iOS 11.0, *) {
        self.tableView.performBatchUpdates {
          self.tableView.insertRows(at: indexs, with: .bottom)
        } completion: { finished in
          self.tableView.scrollToRow(
            at: IndexPath(row: self.viewmodel.messages.count - 1, section: 0),
            at: .bottom,
            animated: false
          )
        }
      } else {
        tableView.insertRows(at: indexs, with: .bottom)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: DispatchWorkItem(block: {
          self.tableView.scrollToRow(
            at: IndexPath(row: self.viewmodel.messages.count - 1, section: 0),
            at: .bottom,
            animated: false
          )
        }))
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
    NEBaseSelectUserViewController(sessionId: viewmodel.session.sessionId, showSelf: false)
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
          addText += m.showNameInTeam()
          if let uid = m.nimUser?.userId {
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
      case noNetworkCode:
        showToast(commonLocalizable("network_error"))
      default:
        showToast(err.localizedDescription)
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
    case .collection:
      collectionMessage()
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
    if let model = viewmodel.operationModel as? MessageTextModel {
      if let text = model.message?.text, !text.isEmpty {
        UIPasteboard.general.string = text
        showToast(chatLocalizable("copy_success"))
      } else if let body = model.attributeStr?.string, !body.isEmpty {
        UIPasteboard.general.string = body
        showToast(chatLocalizable("copy_success"))
      } else if let model = viewmodel.operationModel as? MessageRichTextModel {
        if let title = model.titleAttributeStr?.string, !title.isEmpty {
          UIPasteboard.general.string = title
          showToast(chatLocalizable("copy_success"))
        }
      }
    }
  }

  open func deleteMessage() {
    showAlert(message: chatLocalizable("message_delete_confirm")) {
      self.viewmodel.deleteMessage { error in
        self.showErrorToast(error)
      }
    }
  }

  open func showReplyMessageView(isReEdit: Bool = false) {
    viewmodel.isReplying = true
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

    if let message = viewmodel.operationModel?.message {
      if isReEdit {
        replyView.textLabel.attributedText = NEEmotionTool.getAttWithStr(str: viewmodel.operationModel?.replyText ?? "",
                                                                         font: replyView.textLabel.font,
                                                                         color: replyView.textLabel.textColor)
        if let replyMessage = viewmodel.getReplyMessageWithoutThread(message: message) as? MessageContentModel {
          viewmodel.operationModel = replyMessage
        }
      } else {
        var text = chatLocalizable("msg_reply")
        if let uid = message.from {
          var showName = ChatUserCache.getShowName(userId: uid, teamId: viewmodel.session.sessionId, false)
          if viewmodel.session.sessionType != .P2P,
             !IMKitClient.instance.isMySelf(uid) {
            addToAtUsers(addText: "@" + showName + "", isReply: true, accid: uid)
          }
          let user = viewmodel.getUserInfo(userId: uid)
          if let alias = user?.alias, !alias.isEmpty {
            showName = alias
          }
          text += " " + showName
        }
        text += ": \(ChatMessageHelper.contentOfMessage(message))"
        replyView.textLabel.attributedText = NEEmotionTool.getAttWithStr(str: text,
                                                                         font: replyView.textLabel.font,
                                                                         color: replyView.textLabel.textColor)
        chatInputView.textView.becomeFirstResponder()
      }
    }
  }

  open func closeReply(button: UIButton?) {
    replyView.removeFromSuperview()
    viewmodel.isReplying = false
  }

  open func recallMessage() {
    weak var weakSelf = self
    showAlert(message: chatLocalizable("message_revoke_confirm")) {
      if let message = weakSelf?.viewmodel.operationModel?.message {
        if message.messageType == .text {
          weakSelf?.viewmodel.operationModel?.isRevokedText = true
        }

        if message.messageType == .custom,
           let attach = NECustomAttachment.attachmentOfCustomMessage(message: message), attach.customType == customRichTextType {
          weakSelf?.viewmodel.operationModel?.isRevokedText = true
        }

        let isPin = weakSelf?.viewmodel.operationModel?.isPined ?? false
        weakSelf?.viewmodel.revokeMessage(message: message) { error in
          NELog.infoLog(
            ModuleName + " " + (weakSelf?.tag ?? ""),
            desc: #function + "CALLBACK revokeMessage " + (error?.localizedDescription ?? "no error")
          )
          if let err = error as? NSError {
            if err.code == 508 {
              weakSelf?.showToast(chatLocalizable("ravokable_time_expired"))
            } else {
              weakSelf?.showToast(chatLocalizable("ravoked_failed"))
            }
          } else {
            // 自己撤回成功 & 收到对方撤回 都会走回调方法 onRevokeMessage
            // 撤回成功的逻辑统一在代理方法中处理 onRevokeMessage
            if isPin {
              weakSelf?.viewmodel.removePinMessage(message) { error, pinItem, value in
              }
            }
            weakSelf?.viewmodel.saveRevokeMessage(message) { error in
              print("message id : ", message.messageId)
              if let err = error {
                NELog.infoLog(weakSelf?.className() ?? "chat view controller", desc: err.localizedDescription)
              }
            }
          }
        }
      }
    }
  }

  open func collectionMessage() {
    if let message = viewmodel.operationModel?.message {
      viewmodel.addColletion(message) { error, info in
        NELog.infoLog(
          ModuleName + " " + self.tag,
          desc: #function + "CALLBACK addColletion " + (error?.localizedDescription ?? "no error")
        )
        if error != nil {
          self.showErrorToast(error)
        } else {
          self.showToast(chatLocalizable("collection_success"))
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
    forwardAlert.context = ChatMessageHelper.getSessionName(session: viewmodel.session)
    forwardAlert.sureBlock = sureBlock

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

      if let users = param["im_user"] as? [NIMUser] {
        for user in users {
          let item = ForwardItem()
          item.uid = user.userId
          item.avatar = user.userInfo?.avatarUrl
          item.name = user.getShowName()
          items.append(item)
        }

        let type = isMultiForward ? chatLocalizable("select_multi") :
          (weakSelf?.isMutilSelect == true ? chatLocalizable("select_per_item") : chatLocalizable("operation_forward"))
        weakSelf?.addForwardAlertController(items: items, type: type) { comment in
          if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
            weakSelf?.showToast(commonLocalizable("network_error"))
            return
          }

          weakSelf?.viewmodel.forwardUserMessage(users, isMultiForward, depth, comment) { error in
            if let err = error as? NSError {
              if err.code != 0 {
                weakSelf?.showErrorToast(err)
              }
            } else {
              sureBlock?()
            }
          }
        }
      }
    }

    var param = [String: Any]()
    param["nav"] = weakSelf?.navigationController as Any
    param["limit"] = 6
    Router.shared.use(ContactUserSelectRouter, parameters: param, closure: nil)
  }

  func forwardMessageToTeam(isMultiForward: Bool = false,
                            depth: Int = 0,
                            _ sureBlock: (() -> Void)? = nil) {
    weak var weakSelf = self
    Router.shared.register(ContactTeamDataRouter) { param in
      if let team = param["team"] as? NIMTeam {
        let item = ForwardItem()
        item.avatar = team.avatarUrl
        item.name = team.getShowName()
        item.uid = team.teamId

        let type = isMultiForward ? chatLocalizable("select_multi") :
          (weakSelf?.isMutilSelect == true ? chatLocalizable("select_per_item") : chatLocalizable("operation_forward"))
        weakSelf?.addForwardAlertController(items: [item], type: type) { comment in
          if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
            weakSelf?.showToast(commonLocalizable("network_error"))
            return
          }

          weakSelf?.viewmodel.forwardTeamMessage(team, isMultiForward, depth, comment) { error in
            if let err = error as? NSError {
              if err.code != 0 {
                weakSelf?.showErrorToast(err)
              }
            } else {
              sureBlock?()
            }
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
    if let message = viewmodel.operationModel?.message {
      viewmodel.selectedMessages = [message]
      didClickSingleForwardButton()
    }
  }

  open func pinMessage() {
    guard let optModel = viewmodel.operationModel, !optModel.isPined else {
      return
    }
    if optModel.isRevoked == true {
      return
    }
    if let message = optModel.message {
      viewmodel.pinMessage(message) { [weak self] error, pinItem, index in
        NELog.infoLog(
          ModuleName + " " + (self?.tag ?? "ChatViewController"),
          desc: #function + "CALLBACK pinMessage " + (error?.localizedDescription ?? "no error")
        )
        if let err = error as? NSError {
          if err.code == noNetworkCode {
            self?.view.makeToast(commonLocalizable("network_error"), position: .center)
          } else {
            self?.view.makeToast(error?.localizedDescription, position: .center)
          }
        } else {
          //                    update UI
          if index >= 0 {
            self?.tableViewReloadIndexs([IndexPath(row: index, section: 0)])
          }
        }
      }
    }
  }

  open func removePinMessage() {
    guard let optModel = viewmodel.operationModel, optModel.isPined else {
      return
    }

    if let message = optModel.message {
      viewmodel.removePinMessage(message) { [weak self] error, pinItem, index in
        NELog.infoLog(
          ModuleName + " " + (self?.tag ?? "ChatViewController"),
          desc: #function + "CALLBACK removePinMessage " + (error?.localizedDescription ?? "no error")
        )
        if let err = error as? NSError {
          if err.code == 404 {
            return
          } else if err.code == noNetworkCode {
            self?.view.makeToast(commonLocalizable("network_error"), position: .center)
          } else {
            self?.view.makeToast(error?.localizedDescription, position: .center)
          }
        } else {
          //                    update UI
          if index >= 0 {
            self?.tableViewReloadIndexs([IndexPath(row: index, section: 0)])
          }
        }
      }
    }
  }

  open func selectMessage() {
    isMutilSelect = true
    if let model = viewmodel.operationModel, let msg = model.message {
      model.isSelected = true
      viewmodel.selectedMessages = [msg]
    }

    navigationView.setMoreButtonTitle(chatLocalizable("cancel"))
    navigationView.moreButton.setTitleColor(.ne_darkText, for: .normal)
    navigationView.addMoreButtonTarget(target: self, selector: #selector(cancelMutilSelect))
    setInputView(edit: false)
    tableView.reloadData()
  }

  func cancelMutilSelect() {
    isMutilSelect = false
    viewmodel.selectedMessages.removeAll()
    for model in viewmodel.messages {
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
    let count = viewmodel.messages.count
    print("numberOfRowsInSection count : ", count)
    return count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard indexPath.row < viewmodel.messages.count else { return NEBaseChatMessageCell() }
    let model = viewmodel.messages[indexPath.row]
    var reuseId = ""
    if model.replyedModel?.isReplay == true,
       model.isRevoked == false {
      if model.replyedModel?.message?.serverID == nil ||
        model.replyedModel?.message?.serverID.isEmpty == true {
        if let message = model.message {
          model.replyedModel = viewmodel.getReplyMessageWithoutThread(message: message)
        }
      }

      if let attch = NECustomAttachment.attachmentOfCustomMessage(message: model.message),
         attch.customType == customRichTextType {
        reuseId = "\(MessageType.richText.rawValue)"
      } else {
        reuseId = "\(MessageType.reply.rawValue)"
      }
    } else {
      let key = "\(model.type.rawValue)"
      if model.type == .custom,
         let attch = NECustomAttachment.attachmentOfCustomMessage(message: model.message) {
        if attch.customType == customMultiForwardType {
          reuseId = "\(MessageType.multiForward.rawValue)"
        } else if attch.customType == customRichTextType {
          reuseId = "\(MessageType.richText.rawValue)"
        } else if NEChatUIKitClient.instance.getRegisterCustomCell()["\(attch.customType)"] != nil {
          reuseId = "\(attch.customType)"
        } else {
          reuseId = "\(NEBaseChatMessageCell.self)"
        }
      } else if model.type == .time || model.type == .notification || model.type == .tip {
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
        m.setText()
        c.setModel(m)
      }
      return c
    } else if let c = cell as? NEBaseChatMessageCell {
      c.delegate = self
      if let m = model as? MessageContentModel {
        // 更新好友昵称、头像
        if let from = model.message?.from,
           let user = ChatUserCache.getUserInfo(from) {
          if let uid = user.userId,
             viewmodel.session.sessionType == .team ||
             viewmodel.session.sessionType == .superTeam {
            m.fullName = ChatUserCache.getShowName(userId: uid, teamId: viewmodel.session.sessionId)
            m.shortName = ChatUserCache.getShortName(name: user.showName(false) ?? "", length: 2)
          }
          m.avatar = user.userInfo?.avatarUrl
        }
        c.setModel(m, m.message?.isOutgoingMsg ?? false)
        c.setSelect(m, isMutilSelect)
      }

      if let audioCell = cell as? ChatAudioCellProtocol,
         let m = model as? MessageAudioModel,
         m.message?.messageId == playingModel?.message?.messageId {
        if NIMSDK.shared().mediaManager.isPlaying() {
          playingCell = audioCell
          playingCell?.startAnimation(byRight: true)
        }
      }

      return c
    } else if let c = cell as? NEChatBaseCell, let m = model as? MessageContentModel {
      c.setModel(m, m.message?.isOutgoingMsg ?? false)
      return cell
    } else {
      return NEBaseChatMessageCell()
    }
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard indexPath.row < viewmodel.messages.count else { return }
    if isMutilSelect {
      if indexPath.row < viewmodel.messages.count {
        let model = viewmodel.messages[indexPath.row]
        if !model.isRevoked,
           let cell = tableView.cellForRow(at: indexPath) as? NEBaseChatMessageCell {
          model.isSelected = !model.isSelected
          cell.seletedBtn.isSelected = model.isSelected
          viewmodel.selectedMessages.removeAll(where: { $0.messageId == model.message?.messageId })
          if model.isSelected, let msg = model.message {
            viewmodel.selectedMessages.append(msg)
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
    guard indexPath.row < viewmodel.messages.count else { return 0 }
    let model = viewmodel.messages[indexPath.row]
    if let m = model as? MessageTipsModel {
      m.commonInit()
    }

    return model.cellHeight() + chat_content_margin
  }

  open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    0
  }

  open func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
    0
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
    chatInputView.chatAddMoreView.configData(data: NEChatUIKitClient.instance.getMoreActionData(sessionType: viewmodel.session.sessionType))
  }

  open func showTextViewController(_ model: MessageContentModel?) {
    let title = NECustomAttachment.titleOfRichText(message: model?.message)
    let body = NECustomAttachment.bodyOfRichText(message: model?.message) ?? model?.message?.text
    let textView = getTextViewController(title: title, body: body)
    textView.modalPresentationStyle = .fullScreen
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: DispatchWorkItem(block: { [weak self] in
      self?.navigationController?.present(textView, animated: false)
    }))
  }

  open func didTapMessage(_ cell: UITableViewCell?, _ model: MessageContentModel?, _ replyIndex: Int? = nil) {
    if model?.type == .audio {
      startPlay(cell: cell as? ChatAudioCellProtocol, model: model as? MessageAudioModel)
    } else if model?.type == .image {
      if let imageObject = model?.message?.messageObject as? NIMImageObject {
        var imageUrl = ""

        if let url = imageObject.url {
          imageUrl = url
        } else {
          if let path = imageObject.path, FileManager.default.fileExists(atPath: path) {
            imageUrl = path
          }
        }
        if imageUrl.count > 0 {
          let showController = PhotoBrowserController(
            urls: ChatMessageHelper.getUrls(messages: viewmodel.messages),
            url: imageUrl
          )
          showController.modalPresentationStyle = .overFullScreen
          present(showController, animated: false, completion: nil)
        }
      }
    } else if model?.type == .video,
              let object = model?.message?.messageObject as? NIMVideoObject {
      stopPlay()
      weak var weakSelf = self
      let videoPlayer = VideoPlayerViewController()
      videoPlayer.modalPresentationStyle = .overFullScreen
      if let path = object.path, FileManager.default.fileExists(atPath: path) == true {
        let url = URL(fileURLWithPath: path)
        videoPlayer.videoUrl = url
        videoPlayer.totalTime = object.duration
        print("video url : ", videoPlayer.videoUrl as Any)
        present(videoPlayer, animated: true, completion: nil)
      } else if let urlString = object.url, let path = object.path,
                let videoModel = model as? MessageVideoModel {
        print("fetch message attachment")
        if let index = replyIndex, index >= 0 {
          tableView.scrollToRow(at: IndexPath(row: index, section: 0),
                                at: .middle,
                                animated: true)
        }
        videoModel.state = .Downalod
        if let videoCell = cell as? NEBaseChatMessageCell {
          videoCell.setModel(videoModel, videoModel.message?.isOutgoingMsg ?? false)
        }

        viewmodel.downLoad(urlString, path) { progress in
          NELog.infoLog(ModuleName + " " + (weakSelf?.tag ?? "ChatViewController"), desc: #function + "CALLBACK downLoad: \(progress)")

          videoModel.progress = progress
          if progress >= 1.0 {
            videoModel.state = .Success
          }
          videoModel.cell?.uploadProgress(byRight: videoModel.message?.isOutgoingMsg ?? true, progress)
        } _: { error in
          weakSelf?.showErrorToast(error)
        }
      }
    } else if replyIndex != nil, model?.type == .text || model?.type == .reply {
      showTextViewController(model)
    } else if model?.type == .location {
      if let locationModel = model as? MessageLocationModel, let lat = locationModel.lat, let lng = locationModel.lng {
        let mapDetail = NEDetailMapController(type: .detail)
        mapDetail.currentPoint = CGPoint(x: lat, y: lng)
        mapDetail.locationTitle = locationModel.title
        mapDetail.subTitle = locationModel.subTitle
        navigationController?.pushViewController(mapDetail, animated: true)
      }
    } else if model?.type == .file,
              let object = model?.message?.messageObject as? NIMFileObject,
              let path = object.path {
      if !FileManager.default.fileExists(atPath: path) {
        if let urlString = object.url, let path = object.path,
           let fileModel = model as? MessageFileModel {
          if let index = replyIndex, index >= 0 {
            tableView.scrollToRow(at: IndexPath(row: index, section: 0),
                                  at: .middle,
                                  animated: true)
          }
          fileModel.state = .Downalod
          if let fileCell = cell as? NEBaseChatMessageCell {
            fileCell.setModel(fileModel, fileModel.message?.isOutgoingMsg ?? false)
          }

          viewmodel.downLoad(urlString, path) { [weak self] progress in
            NELog.infoLog(ModuleName + " " + (self?.tag ?? "ChatViewController"), desc: #function + "downLoad file progress: \(progress)")
            var newProgress = progress
            if newProgress < 0 {
              newProgress = abs(progress) / fileModel.size
            }
            fileModel.progress = newProgress
            if newProgress >= 1.0 {
              fileModel.state = .Success
            }
            fileModel.cell?.uploadProgress(byRight: fileModel.message?.isOutgoingMsg ?? true, newProgress)

          } _: { [weak self] error in
            self?.showErrorToast(error)
          }
        }
      } else {
        let url = URL(fileURLWithPath: path)
        interactionController.url = url
        interactionController.delegate = self // UIDocumentInteractionControllerDelegate
        if interactionController.presentPreview(animated: true) {}
        else {
          interactionController.presentOptionsMenu(from: view.bounds, in: view, animated: true)
        }
      }
    } else if model?.type == .rtcCallRecord, let object = model?.message?.messageObject as? NIMRtcCallRecordObject {
      var param = [String: AnyObject]()
      param["remoteUserAccid"] = viewmodel.session.sessionId as AnyObject
      param["currentUserAccid"] = NIMSDK.shared().loginManager.currentAccount() as AnyObject
      param["remoteShowName"] = titleContent as AnyObject
      if let user = viewmodel.repo.getUserInfo(userId: viewmodel.session.sessionId), let avatar = user.userInfo?.avatarUrl {
        param["remoteAvatar"] = avatar as AnyObject
      }
      if object.callType == .audio {
        param["type"] = NSNumber(integerLiteral: 1) as AnyObject
      } else {
        param["type"] = NSNumber(integerLiteral: 2) as AnyObject
      }
      Router.shared.use(CallViewRouter, parameters: param)
    } else if model?.type == .custom, let attach = NECustomAttachment.attachmentOfCustomMessage(message: model?.message) {
      if attach.customType == customRichTextType {
        if replyIndex != nil {
          showTextViewController(model)
        }
      } else if attach.customType == customMultiForwardType,
                let data = NECustomAttachment.dataOfCustomMessage(message: model?.message) {
        let url = data["url"] as? String
        let md5 = data["md5"] as? String
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileName = multiForwardFileName + (model?.message?.messageId ?? "")
        let filePath = documentsDirectory.appendingPathComponent("NEIMUIKit/\(fileName)").relativePath
        let multiForwardVC = getMultiForwardViewController(url, filePath, md5)
        navigationController?.pushViewController(multiForwardVC, animated: true)
      }
    } else {
      print(#function + "message did tap, type:\(String(describing: model?.type.rawValue))")
    }
  }
}

// MARK: NEMutilSelectBottomViewDelegate

extension ChatViewController: NEMutilSelectBottomViewDelegate {
  /// 移除不可转发的消息
  /// - Parameters cancelSelect: 是否取消勾选
  func filterSelectedMessage(invalidMessages: [NIMMessage]) {
    // 取消勾选
    for msg in viewmodel.selectedMessages {
      if invalidMessages.contains(msg) {
        for (row, model) in viewmodel.messages.enumerated() {
          if msg.messageId == model.message?.messageId {
            let indexPath = IndexPath(row: row, section: 0)
            let model = viewmodel.messages[indexPath.row]
            if !model.isRevoked,
               let cell = tableView.cellForRow(at: indexPath) as? NEBaseChatMessageCell {
              model.isSelected = !model.isSelected
              cell.seletedBtn.isSelected = model.isSelected
            }
          }
        }
      }
    }

    // 无论UI上是否取消勾选，都需要移除该消息
    viewmodel.selectedMessages.removeAll(where: { invalidMessages.contains($0) })
  }

  // 合并转发
  open func didClickMultiForwardButton() {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    if viewmodel.selectedMessages.count > customMultiForwardLimitCount {
      showToast(String(format: chatLocalizable("multiForward_forward_limit"), customMultiForwardLimitCount))
      return
    }

    var depth = 0
    var invalidMessages = [NIMMessage]()
    for msg in viewmodel.selectedMessages {
      if msg.deliveryState == .failed || msg.isBlackListed {
        invalidMessages.append(msg)
        continue
      }

      // 解析消息中的depth
      if let data = NECustomAttachment.dataOfCustomMessage(message: msg) {
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
        if !viewmodel.selectedMessages.isEmpty {
          multiForwardForward(depth)
        }
      }
    } else {
      if !viewmodel.selectedMessages.isEmpty {
        multiForwardForward(depth)
      }
    }
  }

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

  // 逐条转发
  open func didClickSingleForwardButton() {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    if viewmodel.selectedMessages.count > customSingleForwardLimitCount {
      showToast(String(format: chatLocalizable("per_item_forward_limit"), customSingleForwardLimitCount))
      return
    }

    var invalidMessages = [NIMMessage]()
    for msg in viewmodel.selectedMessages {
      if msg.messageType == .audio ||
        msg.messageType == .rtcCallRecord ||
        msg.deliveryState == .failed
        || msg.isBlackListed {
        invalidMessages.append(msg)
      }
    }

    if invalidMessages.count > 0 {
      showAlert(title: chatLocalizable("exception_description"),
                message: chatLocalizable("exist_invalid")) { [self] in
        filterSelectedMessage(invalidMessages: invalidMessages)
        if !viewmodel.selectedMessages.isEmpty {
          singleForward()
        }
      }
    } else {
      if !viewmodel.selectedMessages.isEmpty {
        singleForward()
      }
    }
  }

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

  // 多选删除
  open func didClickDeleteButton() {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    showAlert(message: chatLocalizable("message_delete_confirm")) { [weak self] in
      if let messages = self?.viewmodel.selectedMessages {
        self?.viewmodel.deleteMessages(messages: messages) { error in
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
    guard viewmodel.session.sessionType == .team,
          !isMute,
          !isMutilSelect else {
      return
    }

    var addText = ""
    var accid = ""

    if let m = model, let from = m.message?.from {
      accid = from
      addText += ChatUserCache.getShowName(userId: from, teamId: viewmodel.session.sessionId, false)
    }

    addText = "@" + addText + ""

    addToAtUsers(addText: addText, accid: accid, true)
  }

  open func didTapAvatarView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    // 多选模式下屏蔽头像点击事件
    if isMutilSelect {
      return
    }
    didTapHeadPortrait(model: model)
  }

  open func didTapMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
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

    var replyId: String? = model?.message?.repliedMessageId
    if let yxReplyMsg = model?.message?.remoteExt?[keyReplyMsgKey] as? [String: Any] {
      replyId = yxReplyMsg["idClient"] as? String
    }

    if let id = replyId, !id.isEmpty {
      var index = -1
      var replyModel: MessageModel?
      for (i, m) in viewmodel.messages.enumerated() {
        if id == m.message?.messageId {
          index = i
          replyModel = m
          break
        }
      }

      let replyCell = tableView.cellForRow(at: IndexPath(row: index, section: 0))
      if let replyContentModel = replyModel as? MessageContentModel {
        didTapMessage(replyCell, replyContentModel, index)
      }
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

    if playingCell?.messageId == model?.message?.messageId {
      if playingCell?.isPlaying == true {
        stopPlay()
      }
    }
    if let m = model, let msg = m.message {
      let messages = viewmodel.messages
      var index = -1
      for i in 0 ..< messages.count {
        if let message = messages[i].message {
          if message.messageId == msg.messageId {
            index = i
            break
          }
        }
      }
      if index >= 0 {
        viewmodel.messages.remove(at: index)
        viewmodel.messages.append(m)
      }
      viewmodel.resendMessage(message: msg)
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
       message.messageType == .text || message.messageType == .custom {
      if message.messageType == .custom {
        guard let attach = NECustomAttachment.attachmentOfCustomMessage(message: message),
              attach.customType == customRichTextType else {
          return
        }
      }
      let data = NECustomAttachment.dataOfCustomMessage(message: model?.message)

      let time = message.timestamp
      let date = Date()
      let currentTime = date.timeIntervalSince1970
      if currentTime - time >= 60 * 2 {
        showToast(chatLocalizable("editable_time_expired"))
        didRefreshTable()
        return
      }
      if message.remoteExt?[keyReplyMsgKey] != nil {
        viewmodel.operationModel = model
        showReplyMessageView(isReEdit: true)
      } else {
        closeReply(button: nil)
      }

      var attributeStr: NSMutableAttributedString?
      var text = ""
      if message.messageType == .text, let txt = message.text {
        text = txt
      } else if message.messageType == .custom, let body = data?["body"] as? String {
        text = body
      }

      attributeStr = NSMutableAttributedString(string: text)
      attributeStr?.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.ne_darkText, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], range: NSMakeRange(0, text.utf16.count))

      if let remoteExt = message.remoteExt, let dic = remoteExt[yxAtMsg] as? [String: AnyObject] {
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
      }

      chatInputView.textView.attributedText = attributeStr
      chatInputView.textView.becomeFirstResponder()
    }
  }

  open func didTapReadView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    if isMutilSelect {
      return
    }

    if let msg = model?.message, msg.session?.sessionType == .team {
      let readVC = getReadView(msg)
      navigationController?.pushViewController(readVC, animated: true)
    }
  }

  open func didTapSelectButton(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    viewmodel.selectedMessages.removeAll(where: { $0.messageId == model?.message?.messageId })
    if model?.isSelected == true, let msg = model?.message {
      viewmodel.selectedMessages.append(msg)
    }
  }

  open func getReadView(_ message: NIMMessage) -> NEBaseReadViewController {
    ReadViewController(message: message)
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
    scrollTableViewToBottom()
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
