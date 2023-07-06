
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECoreIMKit
import NIMSDK
import MJRefresh
import AVFoundation
import NECommonKit
import NECoreKit
import NECommonUIKit
import WebKit
import NEChatKit
import Photos

@objcMembers
open class ChatViewController: ChatBaseViewController, UINavigationControllerDelegate,
  ChatInputViewDelegate, ChatViewModelDelegate, NIMMediaManagerDelegate,
  MessageOperationViewDelegate, UITableViewDataSource,
  UITableViewDelegate, UIDocumentPickerDelegate, UIDocumentInteractionControllerDelegate, CLLocationManagerDelegate, UITextViewDelegate {
  private let tag = "ChatViewController"
  private let kCallKitDismissNoti = "kCallKitDismissNoti"
  private let kCallKitShowNoti = "kCallKitShowNoti"
  private var playingCell: ChatAudioCellProtocol?
  private var playingModel: MessageAudioModel?
  private var atUsers = [NSRange]()
  private var timer: Timer?
  private var isFile: Bool? // 是否以文件形式发送
  private var needMarkReadMsgs = [NIMMessage]()
  private var isCurrentPage = true

  var replyView = ReplyView()
  public var titleContent = ""
  let interactionController = UIDocumentInteractionController()

  public var viewmodel: ChatViewModel
  public var inputViewTopConstraint: NSLayoutConstraint?
  public var tableViewBottomConstraint: NSLayoutConstraint?
  public var menuView: NEBaseChatInputView!
  public var operationView: MessageOperationView?
  public var operationCellFilter: [OperationType]?
  public var bottomExanpndHeight: CGFloat = 204 // 底部展开高度
  public var normalInputHeight: CGFloat = 100
  public var normalOffset: CGFloat = 0
  public var registerCellDic = [String: UITableViewCell.Type]()

  public lazy var inputTopExtendView: UIView = {
    let content = UIView()
    content.translatesAutoresizingMaskIntoConstraints = false
    content.backgroundColor = UIColor.clear
    return content
  }()

  public lazy var navigationBarBottomExtendView: UIView = {
    let content = UIView()
    content.translatesAutoresizingMaskIntoConstraints = false
    content.backgroundColor = UIColor.clear
    return content
  }()

  public lazy var inputTopExtendHeight: CGFloat = 0
  public lazy var navigationBarBottomExtendHeight: CGFloat = 0
  public var inputTopExtendHeightConstant: NSLayoutConstraint?
  public var navigationBarBottomExtendHeightConstant: NSLayoutConstraint?

  private lazy var manager = CLLocationManager()

  public init(session: NIMSession) {
    viewmodel = ChatViewModel(session: session, anchor: nil)
    super.init(nibName: nil, bundle: nil)
    menuView = getMenuView()

    NEKeyboardManager.shared.enable = false
    NEKeyboardManager.shared.enableAutoToolbar = false
    NIMSDK.shared().mediaManager.add(self)
    NIMSDK.shared().mediaManager.setNeedProximityMonitor(viewmodel.getHandSetEnable())
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func backEvent() {
    super.backEvent()
    cleanDelegate()
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    commonUI()
    addObseve()
    weak var weakSelf = self
    viewmodel.fetchPinMessage {
      weakSelf?.loadData()
    }
  }

  func appEnterBackground() {
    isCurrentPage = false
  }

  func appEnterForegournd() {
    isCurrentPage = true
  }

  open func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    textView.typingAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ne_darkText, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
    return true
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    NEKeyboardManager.shared.enable = false
    NEKeyboardManager.shared.shouldResignOnTouchOutside = false
    isCurrentPage = true
    markNeedReadMsg()
    getSessionInfo(session: viewmodel.session)
    clearAtRemind()

    weak var weakSelf = self
    NEChatDetectNetworkTool.shareInstance.netWorkReachability { status in
      if status == .notReachable, let networkView = weakSelf?.brokenNetworkView {
        weakSelf?.view.addSubview(networkView)
      } else {
        weakSelf?.brokenNetworkView.removeFromSuperview()
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
  }

  override open func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    stopPlay()
  }

  // MARK: 子类可重写方法

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

    // 供用户自定义 items
    setOperationItems(items: &filterItems, model: model)

    if model?.isRevoked == true {
      return
    }

    viewmodel.operationModel = model

//        size
    let w = filterItems.count <= 5 ? 60.0 * Double(filterItems.count) + 16.0 : 60.0 * 5 + 16.0
    let h = filterItems.count <= 5 ? 56.0 + 16.0 : 56.0 * 2 + 16.0

    if let index = tableView.indexPath(for: cell) {
      let rectInTableView = tableView.rectForRow(at: index)
      let rectInView = tableView.convert(rectInTableView, to: tableView.superview)
      let topOffset = UIApplication.shared.statusBarFrame.size.height + navigationController!
        .navigationBar.frame.size.height
      var operationY = 0.0
      if topOffset + h > rectInView.origin.y {
//                under the cell
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
    }
  }

  // MARK: lazy Method

  public var networkToolHeight: CGFloat = 36

  public lazy var brokenNetworkView: NEBrokenNetworkView = {
    let view =
      NEBrokenNetworkView(frame: CGRect(x: 0, y: kNavigationHeight + KStatusBarHeight,
                                        width: kScreenWidth, height: networkToolHeight))
    return view
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

  // MARK: UIGestureRecognizerDelegate

  open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                              shouldReceive touch: UITouch) -> Bool {
//        print("touch.view:\(touch.view)")
    guard let view = touch.view else {
      return true
    }
    if view.bounds.size.width == 60 {
      return false
    }
    // 点击重发按钮
    // 点击撤回重新编辑按钮
    if view.isKind(of: UIButton.self) {
      return false
    }
    if view.isKind(of: UIImageView.self) {
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
    print("will deinit")
    cleanDelegate()
  }

  func cleanDelegate() {
    NIMSDK.shared().mediaManager.remove(self)
    viewmodel.delegate = nil
  }

  // MARK: objc 方法

  override open func toSetting() {}

  // MARK: private 方法

  open func commonUI() {
    title = viewmodel.session.sessionId
    customNavigationView.bottomLine.isHidden = false
    view.addSubview(tableView)
    tableViewBottomConstraint = tableView.bottomAnchor.constraint(
      equalTo: view.bottomAnchor,
      constant: -normalInputHeight - inputTopExtendHeight
    )
    tableViewBottomConstraint?.isActive = true
    view.addSubview(navigationBarBottomExtendView)

    if #available(iOS 10, *) {
      self.navigationBarBottomExtendHeightConstant = navigationBarBottomExtendView.heightAnchor.constraint(equalToConstant: navigationBarBottomExtendHeight)
      self.navigationBarBottomExtendHeightConstant?.isActive = true
      NSLayoutConstraint.activate([
        navigationBarBottomExtendView.topAnchor.constraint(equalTo: view.topAnchor, constant: kNavigationHeight + KStatusBarHeight),
        navigationBarBottomExtendView.leftAnchor.constraint(equalTo: view.leftAnchor),
        navigationBarBottomExtendView.rightAnchor.constraint(equalTo: view.rightAnchor),
      ])
      NSLayoutConstraint.activate([
        tableView.topAnchor.constraint(
          equalTo: navigationBarBottomExtendView.bottomAnchor,
          constant: 0
        ),
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      ])
    } else {
      navigationBarBottomExtendHeightConstant = navigationBarBottomExtendView.heightAnchor.constraint(equalToConstant: navigationBarBottomExtendHeight)
      navigationBarBottomExtendHeightConstant?.isActive = true
      NSLayoutConstraint.activate([
        navigationBarBottomExtendView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
        navigationBarBottomExtendView.leftAnchor.constraint(equalTo: view.leftAnchor),
        navigationBarBottomExtendView.rightAnchor.constraint(equalTo: view.rightAnchor),
      ])

      NSLayoutConstraint.activate([
        tableView.topAnchor.constraint(
          equalTo: navigationBarBottomExtendView.bottomAnchor,
          constant: 0
        ),
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      ])
    }

    tableView.register(
      NEBaseChatMessageCell.self,
      forCellReuseIdentifier: "\(NEBaseChatMessageCell.self)"
    )

    NEChatUIKitClient.instance.getRegisterCustomCell().forEach { (key: String, value: UITableViewCell.Type) in
      registerCellDic[key] = value
    }

    registerCellDic.forEach { (key: String, value: UITableViewCell.Type) in
      tableView.register(value, forCellReuseIdentifier: key)
    }

    viewmodel.delegate = self
    menuView.backgroundColor = UIColor(hexString: "#EFF1F3")
    menuView.translatesAutoresizingMaskIntoConstraints = false
    menuView.delegate = self
    expandMoreAction()
    view.addSubview(menuView)

    inputViewTopConstraint = menuView.topAnchor.constraint(
      equalTo: view.bottomAnchor,
      constant: -normalInputHeight
    )
    NSLayoutConstraint.activate([
      menuView.leftAnchor.constraint(equalTo: view.leftAnchor),
      menuView.rightAnchor.constraint(equalTo: view.rightAnchor),
      menuView.heightAnchor.constraint(equalToConstant: 304),
    ])
    inputViewTopConstraint?.isActive = true

    view.addSubview(inputTopExtendView)
    inputTopExtendHeightConstant = inputTopExtendView.heightAnchor.constraint(equalToConstant: inputTopExtendHeight)
    inputTopExtendHeightConstant?.isActive = true
    NSLayoutConstraint.activate([
      inputTopExtendView.bottomAnchor.constraint(equalTo: menuView.topAnchor),
      inputTopExtendView.leftAnchor.constraint(equalTo: view.leftAnchor),
      inputTopExtendView.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])

    if NEKitChatConfig.shared.ui.showTitleBarRightIcon {
      let image = NEKitChatConfig.shared.ui.titleBarRightRes ?? UIImage.ne_imageNamed(name: "three_point")
      addRightAction(image, #selector(toSetting), self)
      customNavigationView.setMoreButtonImage(image)
    } else {
      customNavigationView.moreButton.isHidden = true
    }

    if let pan = navigationController?.interactivePopGestureRecognizer {
      tableView.panGestureRecognizer.require(toFail: pan)
    }
  }

  func loadData() {
    weak var weakSelf = self

    viewmodel.queryRoamMsgHasMoreTime_v2 { error, historyEnd, newEnd, index in
      NELog.infoLog(
        ModuleName + " " + self.tag,
        desc: #function + "CALLBACK queryRoamMsgHasMoreTime_v2 " + (error?.localizedDescription ?? "no error")
      )

      if let ms = weakSelf?.viewmodel.messages, ms.count > 0 {
        weakSelf?.tableView.reloadData()
        if weakSelf?.viewmodel.isHistoryChat == true {
          let indexPath = IndexPath(row: index, section: 0)
          print("queryRoamMsgHasMoreTime_v2 index : ", index)
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
        weakSelf?.showToast(err.localizedDescription)
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
      print("dropDownRemoteRefresh messages count ", messages?.count as Any)

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
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(markNeedReadMsg),
                                           name: UIApplication.willEnterForegroundNotification,
                                           object: nil)
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

  //    MARK: 键盘通知相关操作

  open func keyBoardWillShow(_ notification: Notification) {
    if menuView.currentType != .text {
      return
    }
    menuView.currentButton?.isSelected = false

    menuView.contentSubView?.isHidden = true
    let oldKeyboardRect = (notification
      .userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue

    let keyboardRect = (notification
      .userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue

    print("chat view key board size : ", keyboardRect)
    layoutInputView(offset: keyboardRect.size.height)
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
    if menuView.currentType != .text {
      return
    }
    menuView.currentButton?.isSelected = false
    // 解决点击operation点击无效问题
//    if operationView?.superview != nil {
//      operationView?.removeFromSuperview()
//    }
    layoutInputView(offset: 0)
  }

  private func scrollTableViewToBottom() {
    print("self.viewmodel.messages.count\(viewmodel.messages.count)")
    print("self.tableView.numberOfRows(inSection: 0)\(tableView.numberOfRows(inSection: 0))")
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
    print("layoutInputView offset : ", offset)
    print("normalOffset : ", normalOffset)
    print("normalInputHeight : ", normalInputHeight)
    weak var weakSelf = self
    let topValue = normalInputHeight - normalOffset
    if offset == 0 {
      menuView.contentSubView?.isHidden = true
      menuView.currentButton?.isSelected = false
    }
    UIView.animate(withDuration: 0.1, animations: {
      weakSelf?.inputViewTopConstraint?.constant = -topValue - offset
      weakSelf?.tableViewBottomConstraint?.constant = -topValue - offset - (weakSelf?.inputTopExtendHeight ?? 0)
    })
  }

  //    MARK: ChatInputViewDelegate

  open func sendText(text: String?, attribute: NSAttributedString?) {
    guard let content = text, content.count > 0 else {
      return
    }
    let remoteExt = menuView.getRemoteExtension(attribute)
    menuView.cleartAtCache()
    weak var weakSelf = self
    if viewmodel.isReplying, let msg = viewmodel.operationModel?.message {
      viewmodel.replyMessageWithoutThread(message: MessageUtils.textMessage(text: content, remoteExt: remoteExt), target: msg) { [weak self] error in
        NELog.infoLog(
          ModuleName + " " + (self?.tag ?? "ChatViewController"),
          desc: #function + "CALLBACK replyMessage " + (error?.localizedDescription ?? "no error")
        )
        if error != nil {
          weakSelf?.view.makeToast(error?.localizedDescription)
        } else {
          weakSelf?.closeReply(button: nil)
        }
      }

    } else {
      viewmodel.sendTextMessage(text: content, remoteExt: remoteExt) { [weak self] error in
        NELog.infoLog(
          ModuleName + " " + (self?.tag ?? "ChatViewController"),
          desc: #function + "CALLBACK sendTextMessage " + (error?.localizedDescription ?? "no error")
        )
        if error != nil {
          weakSelf?.view.makeToast(error?.localizedDescription)
        }
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
        if let err = error {
          weakSelf?.showToast(err.localizedDescription)
        }
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
        var selRange = menuView.textView.selectedTextRange
        if let oldCursor = menuView.textView.selectedTextRange {
          if let newCursor = menuView.textView.position(from: oldCursor.start, offset: -rmRange.length) {
            selRange = menuView.textView.textRange(from: newCursor, to: newCursor)
          }
        }

        // 删除rmRange范围内的字符串（"@xxx "）
        let subRange = menuView.textView.text.utf16.index(menuView.textView.text.startIndex, offsetBy: rmRange.location) ... menuView.textView.text.utf16.index(menuView.textView.text.startIndex, offsetBy: rmRange.location + rmRange.length - 1)

        let key = "\(rmRange.location)_\(rmRange.length - 1)"
        menuView.atRangeCache.removeValue(forKey: key)

        menuView.textView.text.removeSubrange(subRange)

        // 重新设置光标到删除前的位置
        menuView.textView.selectedTextRange = selRange
      }
      return false
    }
    return true
  }

  open func textFieldDidChange(_ textField: UITextView) {
    if let text = textField.text {
      if text.count > 0 {
        viewmodel.sendInputTypingState()
      } else {
        viewmodel.sendInputTypingEndState()
      }
    }
  }

  open func textFieldDidEndEditing(_ textField: UITextView) {
    viewmodel.sendInputTypingEndState()
  }

  open func textFieldDidBeginEditing(_ textField: UITextView) {
    if let count = textField.text?.count, count > 0 {
      viewmodel.sendInputTypingState()
    }
  }

  open func willSelectItem(button: UIButton?, index: Int) {
    operationView?.removeFromSuperview()
    if button?.isSelected == true {
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
        goPhotoAlbumWithVideo(self)
      } else if index == 3 {
        // 更多
        layoutInputView(offset: bottomExanpndHeight)
        scrollTableViewToBottom()
        UIApplication.shared.keyWindow?.endEditing(true)
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
          if let err = error {
            weakSelf?.showToast(err.localizedDescription)
          }
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
        showToast(chatLocalizable("fileSize_over_limit").replacingOccurrences(of: "XXX", with: "\(NEKitChatConfig.shared.ui.fileSizeLimit)"))
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
//                                          picker.dismiss(animated: true, completion: nil)
//                                          sendMediaMessage(didFinishPickingMediaWithInfo: info)
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
            showToast(chatLocalizable("fileSize_over_limit").replacingOccurrences(of: "XXX", with: "\(NEKitChatConfig.shared.ui.fileSizeLimit)"))
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
    DispatchQueue.main.async { [weak self] in
      self?.tableView.reloadData()
    }
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

  open func viewTap(tap: UITapGestureRecognizer) {
    if let opeView = operationView,
       view.subviews.contains(opeView) {
      opeView.removeFromSuperview()

    } else {
      if menuView.textView.isFirstResponder {
        menuView.textView.resignFirstResponder()
      } else {
        layoutInputView(offset: 0)
      }
    }
  }

  // MARK: audio play

  func startPlaying(audio: NIMAudioObject, isSend: Bool) {
    playingCell?.startAnimation(byRight: isSend)
    if let url = audio.path {
      if viewmodel.getHandSetEnable() == true {
        NIMSDK.shared().mediaManager.switch(.receiver)
      } else {
        NIMSDK.shared().mediaManager.switch(.speaker)
      }
      NIMSDK.shared().mediaManager.play(url)
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
        startPlaying(audio: audio, isSend: isSend)
      }
    } else {
      stopPlay()
      playingCell = cell
      playingModel = model
      startPlaying(audio: audio, isSend: isSend)
    }
  }

  public func stopPlay() {
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
    print(#function + "\(error)")
    if let e = error {
      showToast(e.localizedDescription)
      // stop
      playingCell?.stopAnimation(byRight: playingModel?.message?.isOutgoingMsg ?? true)
      playingModel?.isPlaying = false
    }
  }

  open func playAudio(_ filePath: String, didCompletedWithError error: Error?) {
    print(#function + "\(error)")
    if let e = error {
      showToast(e.localizedDescription)
    }
    // stop
    playingCell?.stopAnimation(byRight: playingModel?.message?.isOutgoingMsg ?? true)
    playingModel?.isPlaying = false
  }

  open func stopPlayAudio(_ filePath: String, didCompletedWithError error: Error?) {
    print(#function + "\(error)")
    if let e = error {
      showToast(e.localizedDescription)
    }
    playingCell?.stopAnimation(byRight: playingModel?.message?.isOutgoingMsg ?? true)
    playingModel?.isPlaying = false
  }

  open func playAudio(_ filePath: String, progress value: Float) {}

  open func playAudioInterruptionEnd() {
    print(#function)
  }

  open func playAudioInterruptionBegin() {
    print(#function)
    // stop play
    playingCell?.stopAnimation(byRight: playingModel?.message?.isOutgoingMsg ?? true)
    playingModel?.isPlaying = false
  }

  //    record
  open func recordAudio(_ filePath: String?, didBeganWithError error: Error?) {
    print("[record] sdk Began error:\(error)")
  }

  open func recordAudio(_ filePath: String?, didCompletedWithError error: Error?) {
    print("[record] sdk Completed error:\(error)")
    menuView.stopRecordAnimation()
    guard let fp = filePath else {
      showToast(error?.localizedDescription ?? "")
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
        if let e = error {
          self.showToast(e.localizedDescription)
        } else {}
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
    if let font = menuView.textView.font {
      let mutaString = NSMutableAttributedString(attributedString: menuView.textView.attributedText)
      let atString = NSAttributedString(string: addText, attributes: [NSAttributedString.Key.foregroundColor: UIColor.ne_blueText, NSAttributedString.Key.font: font])
      var selectRange = NSMakeRange(0, 0)
      var location = 0
      if menuView.textView.isFirstResponder == true {
        location = menuView.textView.selectedRange.location
        selectRange = menuView.textView.selectedRange
      } else {
        location = menuView.textView.attributedText.length
        selectRange = NSMakeRange(location, 0)
      }

      if isReply || isLongPress {
        let temMutaString = NSMutableAttributedString(attributedString: atString)
        let spaceStr = NSAttributedString(string: " ", attributes: [NSAttributedString.Key.font: font])
        temMutaString.append(spaceStr)
        mutaString.insert(temMutaString, at: location)

        menuView.nickAccidDic[addText] = accid.count > 0 ? accid : "ait_all"
        menuView.textView.attributedText = mutaString
        menuView.textView.selectedRange = NSMakeRange(selectRange.location + temMutaString.length, 0)
        return
      }

      if menuView.textView.selectedRange.location > 0 {
        mutaString.replaceCharacters(in: NSMakeRange(menuView.textView.selectedRange.location - 1, 1), with: "")
        let temMutaString = NSMutableAttributedString(attributedString: atString)
        let spaceStr = NSAttributedString(string: " ", attributes: [NSAttributedString.Key.font: font])
        temMutaString.append(spaceStr)
        mutaString.insert(temMutaString, at: menuView.textView.selectedRange.location - 1)
        selectRange = NSMakeRange(selectRange.location - 1, selectRange.length)
      }

      menuView.nickAccidDic[addText] = accid.count > 0 ? accid : "ait_all"

      menuView.textView.attributedText = mutaString
      menuView.textView.selectedRange = NSMakeRange(selectRange.location + addText.count + atRangeOffset, 0)
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

      if index == 0 {
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

  //    MARK: MessageOperationViewDelegate

  open func didSelectedItem(item: OperationItem) {
    switch item.type {
    case .copy:
      copyMessage()
    case .delete:
      deleteMessage()
    case .reply:
      showReplyMessageView()
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
    default:
      customOperation()
    }
  }

  open func customOperation() {}

  open func copyMessage() {
    if let model = viewmodel.operationModel as? MessageTextModel,
       let text = model.message?.text {
      let pasteboard = UIPasteboard.general
      pasteboard.string = text
      view.makeToast(chatLocalizable("copy_success"), duration: 2, position: .center)
    }
  }

  open func deleteMessage() {
    showAlert(message: chatLocalizable("message_delete_comfirm")) {
      if let message = self.viewmodel.operationModel?.message {
        self.viewmodel.deleteMessage(message: message) { error in
          if error != nil {
            self.showToast(chatLocalizable("delete_failed"))
          }
        }
      }
    }
  }

  open func showReplyMessageView(isReEdit: Bool = false) {
    viewmodel.isReplying = true
    view.addSubview(replyView)
    replyView.closeButton.addTarget(self, action: #selector(closeReply), for: .touchUpInside)
    replyView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      replyView.leadingAnchor.constraint(equalTo: menuView.leadingAnchor),
      replyView.trailingAnchor.constraint(equalTo: menuView.trailingAnchor),
      replyView.bottomAnchor.constraint(equalTo: menuView.topAnchor),
      replyView.heightAnchor.constraint(equalToConstant: 36),
    ])
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
          var showName = viewmodel.getShowName(userId: uid, teamId: viewmodel.session.sessionId, false)
          if viewmodel.session.sessionType != .P2P,
             !IMKitClient.instance.isMySelf(uid) {
            addToAtUsers(addText: "@" + showName + "", isReply: true, accid: uid)
          }
          let user = viewmodel.getUserInfo(userId: uid)
          if let alias = user?.alias {
            showName = alias
          }
          text += " " + showName
        }
        text += ": "
        switch message.messageType {
        case .text:
          if let t = message.text {
            text += t
          }
        case .image:
          text += "[\(chatLocalizable("msg_image"))]"
        case .audio:
          text += "[\(chatLocalizable("msg_audio"))]"
        case .video:
          text += "[\(chatLocalizable("msg_video"))]"
        case .file:
          text += "[\(chatLocalizable("msg_file"))]"
        case .location:
          text += "[\(chatLocalizable("msg_location"))]"
        case .custom:
          text += "[\(chatLocalizable("msg_custom"))]"
        default:
          text += "[\(chatLocalizable("msg_unknown"))]"
        }
        replyView.textLabel.attributedText = NEEmotionTool.getAttWithStr(str: text,
                                                                         font: replyView.textLabel.font,
                                                                         color: replyView.textLabel.textColor)
        menuView.textView.becomeFirstResponder()
      }
    }
  }

  open func closeReply(button: UIButton?) {
    replyView.removeFromSuperview()
    viewmodel.isReplying = false
  }

  open func recallMessage() {
    weak var weakSelf = self
    showAlert(message: chatLocalizable("message_revoke_confim")) {
      if let message = weakSelf?.viewmodel.operationModel?.message {
        if let messageType = weakSelf?.viewmodel.operationModel?.message?.messageType, messageType == .text {
          weakSelf?.viewmodel.operationModel?.isRevokedText = true
        }
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(120)) {
//          weakSelf?.tableView.reloadData()
//        }
        weakSelf?.viewmodel.revokeMessage(message: message) { error in
          NELog.infoLog(
            ModuleName + " " + (weakSelf?.tag ?? ""),
            desc: #function + "CALLBACK revokeMessage " + (error?.localizedDescription ?? "no error")
          )
          if let err = error as? NSError {
            if err.code == 408 {
              weakSelf?.showToast(chatLocalizable("ravoked_failed"))
            } else if err.code == 508 {
              weakSelf?.showToast(chatLocalizable("ravokable_time_expired"))
            } else {
              weakSelf?.showToast(err.localizedDescription)
            }
          } else {
            // 自己撤回成功 & 收到对方撤回 都会走回调方法 onRevokeMessage
            // 撤回成功的逻辑统一在代理方法中处理 onRevokeMessage
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
          self.showToast(error!.localizedDescription)
        } else {
          self.showToast(chatLocalizable("collection_success"))
        }
      }
    }
  }

  open func getForwardAlertController() -> NEBaseForwardAlertViewController {
    NEBaseForwardAlertViewController()
  }

  func forwardMessageToUser(message: NIMMessage) {
    weak var weakSelf = self
    Router.shared.register(ContactSelectedUsersRouter) { param in
      print("user setting accids : ", param)
      var items = [ForwardItem]()

      if let users = param["im_user"] as? [NIMUser] {
        users.forEach { user in
          let item = ForwardItem()
          item.uid = user.userId
          item.avatar = user.userInfo?.avatarUrl
          item.name = user.userInfo?.nickName
          items.append(item)
        }

        let forwardAlert = weakSelf?.getForwardAlertController() ?? NEBaseForwardAlertViewController()
        forwardAlert.setItems(items)
        if let senderName = message.senderName {
          forwardAlert.context = senderName
        }
        weakSelf?.addChild(forwardAlert)
        weakSelf?.view.addSubview(forwardAlert.view)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: DispatchWorkItem(block: {
          UIApplication.shared.keyWindow?.endEditing(true)
        }))

        forwardAlert.sureBlock = {
          print("sure click ")
          weakSelf?.viewmodel.forwardUserMessage(message, users)
        }
      }
    }
    var param = [String: Any]()
    param["nav"] = weakSelf?.navigationController as Any
    param["limit"] = 6
    if let session = weakSelf?.viewmodel.session, session.sessionType == .P2P {
      var filters = Set<String>()
      filters.insert(session.sessionId)
      param["filters"] = filters
    }
    Router.shared.use(ContactUserSelectRouter, parameters: param, closure: nil)
  }

  func forwardMessageToTeam(message: NIMMessage) {
    weak var weakSelf = self
    Router.shared.register(ContactTeamDataRouter) { param in
      if let team = param["team"] as? NIMTeam {
        let item = ForwardItem()
        item.avatar = team.avatarUrl
        item.name = team.getShowName()
        item.uid = team.teamId

        let forwardAlert = weakSelf!.getForwardAlertController()
        forwardAlert.setItems([item])
        if let senderName = message.senderName {
          forwardAlert.context = senderName
        }
        forwardAlert.sureBlock = {
          weakSelf?.viewmodel.forwardTeamMessage(message, team)
        }
        weakSelf?.addChild(forwardAlert)
        weakSelf?.view.addSubview(forwardAlert.view)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: DispatchWorkItem(block: {
          UIApplication.shared.keyWindow?.endEditing(true)
        }))
      }
    }

    Router.shared.use(
      ContactTeamListRouter,
      parameters: ["nav": weakSelf?.navigationController as Any],
      closure: nil
    )
  }

  open func forwardMessage() {
    if let message = viewmodel.operationModel?.message {
      weak var weakSelf = self
      let userAction = UIAlertAction(title: chatLocalizable("contact_user"),
                                     style: .default) { action in
        weakSelf?.forwardMessageToUser(message: message)
      }

      let teamAction = UIAlertAction(title: chatLocalizable("team"), style: .default) { action in
        weakSelf?.forwardMessageToTeam(message: message)
      }

      let cancelAction = UIAlertAction(title: chatLocalizable("cancel"),
                                       style: .cancel) { action in
      }

      showActionSheet([teamAction, userAction, cancelAction])
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
          if err.code == 408 {
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
          } else if err.code == 408 {
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

  // MARK: UITableViewDataSource, UITableViewDelegate

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let count = viewmodel.messages.count
    print("numberOfRowsInSection count : ", count)
    return count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = viewmodel.messages[indexPath.row]
    var reuseId = ""
    if model.replyedModel?.isReplay == true,
       model.isRevoked == false {
      reuseId = "\(MessageType.reply.rawValue)"
    } else {
      let key = "\(model.type.rawValue)"
      if model.type == .custom, let object = model.message?.messageObject as? NIMCustomObject, let custom = object.attachment as? NECustomAttachmentProtocol {
        if registerCellDic["\(custom.customType)"] != nil {
          reuseId = "\(custom.customType)"
        } else {
          reuseId = "\(NEBaseChatMessageCell.self)"
        }
      } else if model.type == .time || model.type == .notification || model.type == .tip {
        reuseId = "\(MessageType.time.rawValue)"
      } else if registerCellDic[key] != nil {
        reuseId = key
      } else {
        reuseId = "\(NEBaseChatMessageCell.self)"
      }
    }

    let cell = tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath)
    if let c = cell as? NEBaseChatMessageTipCell {
      if let m = model as? MessageTipsModel {
        m.resetNotiText()
        c.setModel(m)
      }
      return c
    } else if let c = cell as? NEBaseChatMessageCell {
      c.delegate = self
      if let m = model as? MessageContentModel {
        // 更新好友昵称、头像
        if let from = model.message?.from,
           let user = viewmodel.newUserInfoDic[from] {
          if let uid = user.userId,
             viewmodel.session.sessionType == .team ||
             viewmodel.session.sessionType == .superTeam {
            m.fullName = viewmodel.getShowName(userId: uid, teamId: viewmodel.session.sessionId)
            m.shortName = viewmodel.getShortName(name: user.showName(false) ?? "", length: 2)
          }
          m.avatar = user.userInfo?.avatarUrl
        }
        c.setModel(m)
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
      c.setModel(m)
      return cell
    } else {
      return NEBaseChatMessageCell()
    }
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    operationView?.removeFromSuperview()
    if menuView.textView.isFirstResponder {
      menuView.textView.resignFirstResponder()
    } else {
//      layoutInputView(offset: 0)
    }
  }

  open func tableView(_ tableView: UITableView,
                      heightForRowAt indexPath: IndexPath) -> CGFloat {
    let m = viewmodel.messages[indexPath.row]
    if m.type == .custom {
      if let object = m.message?.messageObject as? NIMCustomObject, let custom = object.attachment as? NECustomAttachmentProtocol {
        return custom.cellHeight
      }
    }
    return m.cellHeight()
  }

  open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    0
  }

  open func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
    0
  }

  // MARK: UIScrollViewDelegate

  public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
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

  func getTextViewController(text: String) -> TextViewController {
    let textViewController = TextViewController(content: text)
    textViewController.view.backgroundColor = .white
    return textViewController
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
            urls: viewmodel.getUrls(),
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
          videoCell.setModel(videoModel)
        }

        viewmodel.downLoad(urlString, path) { progress in
          NELog.infoLog(ModuleName + " " + (weakSelf?.tag ?? "ChatViewController"), desc: #function + "CALLBACK downLoad: \(progress)")

          videoModel.progress = progress
          if progress >= 1.0 {
            videoModel.state = .Success
          }
          videoModel.cell?.uploadProgress(byRight: videoModel.message?.isOutgoingMsg ?? true, progress)
        } _: { error in
          if let err = error as NSError? {
            weakSelf?.showToast(err.localizedDescription)
          }
        }
      }
    } else if replyIndex != nil, model?.type == .text || model?.type == .reply {
      print("message did tap: text")
      if let text = model?.message?.text {
        let textView = getTextViewController(text: text)
        textView.modalPresentationStyle = .fullScreen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: DispatchWorkItem(block: { [weak self] in
          self?.navigationController?.present(textView, animated: false)
        }))
      }
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
            fileCell.setModel(fileModel)
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
            if let err = error as NSError? {
              self?.showToast(err.localizedDescription)
            }
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
    } else {
      print(#function + "message did tap, type:\(model?.type.rawValue)")
    }
  }

  // MARK: OVERRIDE

  open func getMenuView() -> NEBaseChatInputView {
    NEBaseChatInputView()
  }

  open func expandMoreAction() {
    menuView.chatAddMoreView.configData(data: NEChatUIKitClient.instance.getMoreActionData(sessionType: viewmodel.session.sessionType))
  }
}

// MARK: ChatBaseCellDelegate

extension ChatViewController: ChatBaseCellDelegate {
  open func didLongPressAvatar(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    print("didLongPressAvatar")
    if viewmodel.session.sessionType == .P2P {
      return
    }
    var addText = ""
    var accid = ""

    if let m = model, let from = m.message?.from {
      accid = from
      addText += viewmodel.getShowName(userId: from, teamId: viewmodel.session.sessionId, false)
    }

    addText = "@" + addText + ""

    addToAtUsers(addText: addText, accid: accid, true)
  }

  open func didTapAvatarView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    didTapHeadPortrait(model: model)
  }

  open func didTapMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    if model?.isRevoked == true {
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
    if model?.type == .revoke, model?.message?.messageType == .text, let message = model?.message {
      let time = message.timestamp
      let date = Date()
      let currentTime = date.timeIntervalSince1970
      if currentTime - time >= 60 * 2 {
        showToast(chatLocalizable("editable_time_expired"))
        didRefreshTable()
        return
      }
      if model?.message?.remoteExt?[keyReplyMsgKey] != nil {
        viewmodel.operationModel = model
        showReplyMessageView(isReEdit: true)
      } else {
        closeReply(button: nil)
      }
      guard let text = message.text else {
        return
      }
      let attributeStr = NSMutableAttributedString(string: text)
      attributeStr.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.ne_darkText, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], range: NSMakeRange(0, text.utf16.count))
      if let remoteExt = message.remoteExt, let dic = remoteExt[yxAtMsg] as? [String: AnyObject] {
        dic.forEach { (key: String, value: AnyObject) in
          if let contentDic = value as? [String: AnyObject] {
            if let array = contentDic[atSegmentsKey] as? [AnyObject] {
              if let models = NSArray.yx_modelArray(with: MessageAtInfoModel.self, json: array) as? [MessageAtInfoModel] {
                models.forEach { model in
                  if var text = contentDic[atTextKey] as? String {
                    if text.last == " " {
                      text = String(text.prefix(text.count - 1))
                    }
                    menuView.nickAccidDic[text] = key
                  }

                  if attributeStr.length > model.end {
                    attributeStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.ne_blueText, range: NSMakeRange(model.start, model.end - model.start))
                  }
                }
              }
            }
          }
        }
      }
      menuView.textView.attributedText = attributeStr
      menuView.textView.becomeFirstResponder()
    }
  }

  open func didTapReadView(_ cell: UITableViewCell, _ model: MessageContentModel?) {}

  open func loadDataFinish() {}

  // MARK: call kit noti

  open func didShowCallView() {
    stopPlay()
  }

  open func didDismissCallView() {}
}
