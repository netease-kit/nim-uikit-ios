
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
  MessageOperationViewDelegate, UIGestureRecognizerDelegate, UITableViewDataSource,
  UITableViewDelegate, UIDocumentPickerDelegate, UIDocumentInteractionControllerDelegate, CLLocationManagerDelegate {
  private let tag = "ChatViewController"
  public var viewmodel: ChatViewModel
  public var inputViewTopConstraint: NSLayoutConstraint?
  public var tableViewBottomConstraint: NSLayoutConstraint?
  public var menuView: ChatInputView = .init()
  public var operationView: MessageOperationView?
  private var playingCell: ChatAudioCell?
  private var atUsers = [NSRange]()
  private var timer: Timer?
  var replyView = ReplyView()
  private var isFile = false
  let interactionController = UIDocumentInteractionController()
  private var needMarkReadMsgs = [NIMMessage]()
  private var isCurrentPage = true
  var titleContent = ""

  private lazy var manager = CLLocationManager()

  public init(session: NIMSession) {
    viewmodel = ChatViewModel(session: session, anchor: nil)
    super.init(nibName: nil, bundle: nil)
    NEKeyboardManager.shared.enable = false
    NEKeyboardManager.shared.enableAutoToolbar = false
    NIMSDK.shared().mediaManager.add(self)
    NIMSDK.shared().mediaManager.setNeedProximityMonitor(viewmodel.getHandSetEnable())
    // 注册自定义消息的解析器
    // NIMCustomObject.registerCustomDecoder(CustomAttachmentDecoder())
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func backEvent() {
    super.backEvent()
    cleanDelegate()
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    commonUI()
    addObseve()
    loadData()
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    NEKeyboardManager.shared.enable = false
    NEKeyboardManager.shared.shouldResignOnTouchOutside = false
    isCurrentPage = true
    navigationController?.isNavigationBarHidden = false
    markNeedReadMsg()
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
      UserInfoProvider.shared.fetchUserInfo([uid]) { [weak self] error, users in
        if let u = users?.first {
          Router.shared.use(
            ContactUserInfoPageRouter,
            parameters: ["nav": self?.navigationController as Any, "user": u],
            closure: nil
          )
        }
      }
    }
  }

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

    if model?.isRevoked == true {
      return
    }

    viewmodel.operationModel = model

//        size
    let w = items.count <= 5 ? 60.0 * Double(items.count) + 16.0 : 60.0 * 5 + 16.0
    let h = items.count <= 5 ? 56.0 + 16.0 : 56.0 * 2 + 16.0

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
      let frame = CGRect(x: frameX, y: operationY, width: w, height: h)
      operationView = MessageOperationView(frame: frame)
      operationView!.delegate = self
      operationView!.items = items
      view.addSubview(operationView!)
    }
  }

  // MARK: lazy Method

  private lazy var brokenNetworkView: ChatBrokenNetworkView = {
    let view =
      ChatBrokenNetworkView(frame: CGRect(x: 0, y: kNavigationHeight + KStatusBarHeight,
                                          width: kScreenWidth, height: 36))
    return view
  }()

  private lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.showsVerticalScrollIndicator = false
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = .white
    tableView.mj_header = MJRefreshNormalHeader(
      refreshingTarget: self,
      refreshingAction: #selector(loadMoreData)
    )
    tableView.keyboardDismissMode = .onDrag
    return tableView
  }()

  // MARK: UIGestureRecognizerDelegate

  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
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

  public func remoteUserEditing() {
    title = chatLocalizable("editing")
    trigerEndTimer()
  }

  public func remoteUserEndEditing() {
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

  func toSetting() {
    if viewmodel.session.sessionType == .team {
      Router.shared.use(
        TeamSettingViewRouter,
        parameters: ["nav": navigationController as Any,
                     "teamid": viewmodel.session.sessionId],
        closure: nil
      )
    } else if viewmodel.session.sessionType == .P2P {
      let userSetting = UserSettingViewController()
      userSetting.userId = viewmodel.session.sessionId
      navigationController?.pushViewController(userSetting, animated: true)
    }
  }

  // MARK: private 方法

  open func commonUI() {
    title = viewmodel.session.sessionId
    view.addSubview(tableView)
    tableViewBottomConstraint = tableView.bottomAnchor.constraint(
      equalTo: view.bottomAnchor,
      constant: -100
    )
    tableViewBottomConstraint?.isActive = true
    if #available(iOS 10, *) {
      NSLayoutConstraint.activate([
        tableView.topAnchor.constraint(
          equalTo: view.topAnchor,
          constant: kNavigationHeight + KStatusBarHeight
        ),
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      ])
    } else {
      NSLayoutConstraint.activate([
        tableView.topAnchor.constraint(
          equalTo: view.topAnchor,
          constant: 0
        ),
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      ])
    }

    tableView.register(ChatCallRecordLeftCell.self, forCellReuseIdentifier: "\(ChatCallRecordLeftCell.self)")

    tableView.register(ChatCallRecordRightCell.self, forCellReuseIdentifier: "\(ChatCallRecordRightCell.self)")

    tableView.register(
      ChatTimeTableViewCell.self,
      forCellReuseIdentifier: "\(ChatTimeTableViewCell.self)"
    )

    tableView.register(
      ChatBaseLeftCell.self,
      forCellReuseIdentifier: "\(ChatBaseLeftCell.self)"
    )
    tableView.register(
      ChatBaseRightCell.self,
      forCellReuseIdentifier: "\(ChatBaseRightCell.self)"
    )
    tableView.register(
      ChatTextRightCell.self,
      forCellReuseIdentifier: "\(ChatTextRightCell.self)"
    )
    tableView.register(
      ChatTextLeftCell.self,
      forCellReuseIdentifier: "\(ChatTextLeftCell.self)"
    )
    tableView.register(
      ChatAudioLeftCell.self,
      forCellReuseIdentifier: "\(ChatAudioLeftCell.self)"
    )
    tableView.register(
      ChatAudioRightCell.self,
      forCellReuseIdentifier: "\(ChatAudioRightCell.self)"
    )
    tableView.register(
      ChatImageLeftCell.self,
      forCellReuseIdentifier: "\(ChatImageLeftCell.self)"
    )
    tableView.register(
      ChatImageRightCell.self,
      forCellReuseIdentifier: "\(ChatImageRightCell.self)"
    )

    tableView.register(
      ChatRevokeLeftCell.self,
      forCellReuseIdentifier: "\(ChatRevokeLeftCell.self)"
    )
    tableView.register(
      ChatRevokeRightCell.self,
      forCellReuseIdentifier: "\(ChatRevokeRightCell.self)"
    )

    tableView.register(
      ChatVideoLeftCell.self,
      forCellReuseIdentifier: "\(ChatVideoLeftCell.self)"
    )
    tableView.register(
      ChatVideoRightCell.self,
      forCellReuseIdentifier: "\(ChatVideoRightCell.self)"
    )
    tableView.register(
      ChatFileLeftCell.self,
      forCellReuseIdentifier: "\(ChatFileLeftCell.self)"
    )
    tableView.register(
      ChatFileRightCell.self,
      forCellReuseIdentifier: "\(ChatFileRightCell.self)"
    )

    tableView.register(
      ChatReplyRightCell.self,
      forCellReuseIdentifier: "\(ChatReplyRightCell.self)"
    )
    tableView.register(
      ChatReplyLeftCell.self,
      forCellReuseIdentifier: "\(ChatReplyLeftCell.self)"
    )

    tableView.register(ChatLocationLeftCell.self, forCellReuseIdentifier: "\(ChatLocationLeftCell.self)")
    tableView.register(ChatLocationRightCell.self, forCellReuseIdentifier: "\(ChatLocationRightCell.self)")
    viewmodel.delegate = self

    menuView.backgroundColor = UIColor(hexString: "#EFF1F3")
    menuView.translatesAutoresizingMaskIntoConstraints = false
    menuView.delegate = self
    menuView.chatAddMoreView.configData(data: NEChatUIKitClient.instance.getMoreActionData(sessionType: viewmodel.session.sessionType))
    view.addSubview(menuView)

    inputViewTopConstraint = menuView.topAnchor.constraint(
      equalTo: view.bottomAnchor,
      constant: -100
    )
    NSLayoutConstraint.activate([
      menuView.leftAnchor.constraint(equalTo: view.leftAnchor),
      menuView.rightAnchor.constraint(equalTo: view.rightAnchor),
      menuView.heightAnchor.constraint(equalToConstant: 304),
    ])
    inputViewTopConstraint?.isActive = true

    weak var weakSelf = self
    NEChatDetectNetworkTool.shareInstance.netWorkReachability { status in
      if status == .notReachable, let networkView = weakSelf?.brokenNetworkView {
        weakSelf?.view.addSubview(networkView)
      } else {
        weakSelf?.brokenNetworkView.removeFromSuperview()
        weakSelf?.viewmodel.refreshReceipts()
      }
    }
    addRightAction(UIImage.ne_imageNamed(name: "three_point"), #selector(toSetting), self)
  }

  func loadData() {
    //        title
    getSessionInfo(session: viewmodel.session)
    weak var weakSelf = self

    viewmodel.queryRoamMsgHasMoreTime_v2 { error, historyEnd, newEnd, models, index in
      NELog.infoLog(
        ModuleName + " " + self.tag,
        desc: "CALLBACK queryRoamMsgHasMoreTime_v2 " + (error?.localizedDescription ?? "no error")
      )
      weakSelf?.viewmodel.refreshReceipts()
      if let ms = models, ms.count > 0 {
        weakSelf?.tableView.reloadData()
        if weakSelf?.viewmodel.isHistoryChat == true {
          let indexPath = IndexPath(row: index, section: 0)
          print("queryRoamMsgHasMoreTime_v2 index : ", index)
          weakSelf?.tableView.scrollToRow(at: indexPath, at: .none, animated: false)
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
    }
  }

  func loadMoreData() {
    weak var weakSelf = self
    viewmodel.dropDownRemoteRefresh { error, count, messages in
      NELog.infoLog(
        ModuleName + " " + self.tag,
        desc: "CALLBACK dropDownRemoteRefresh " + (error?.localizedDescription ?? "no error")
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
        desc: "CALLBACK pullRemoteRefresh " + (error?.localizedDescription ?? "no error")
      )
      if count <= 0 {
        weakSelf?.removeBottomLoadMore()
      } else {
        weakSelf?.tableView.mj_footer?.endRefreshing()
        weakSelf?.tableView.reloadData()
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
    let tap = UITapGestureRecognizer(target: self, action: #selector(viewTap))
    tap.delegate = self
    view.addGestureRecognizer(tap)
  }

  func addBottomLoadMore() {
    tableView.mj_footer = MJRefreshBackNormalFooter(
      refreshingTarget: self,
      refreshingAction: #selector(loadCloserToNowData)
    )
  }

  func removeBottomLoadMore() {
    tableView.mj_footer?.endRefreshingWithNoMoreData()
    tableView.mj_footer = nil
    viewmodel.isHistoryChat = false // 转为普通聊天页面
  }

  func markNeedReadMsg() {
    if isCurrentPage {
      viewmodel.markRead(messages: needMarkReadMsgs) { error in
        NELog.infoLog(
          ModuleName + " " + self.tag,
          desc: "CALLBACK markRead " + (error?.localizedDescription ?? "no error")
        )
      }
      needMarkReadMsgs = [NIMMessage]()
    }
  }

  //    MARK: 键盘通知相关操作

  func keyBoardWillShow(_ notification: Notification) {
    if menuView.currentType != .text {
      return
    }
    let oldKeyboardRect = (notification
      .userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
    let keyboardRect = (notification
      .userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue

    // 键盘已经弹出
    if oldKeyboardRect == keyboardRect {
      return
    }

    print("chat view key board size : ", keyboardRect)
    layoutInputView(offset: keyboardRect.size.height)

    UIView.animate(withDuration: 0.25, animations: {
      self.view.layoutIfNeeded()
    })
    scrollTableViewToBottom()
  }

  func keyBoardWillHide(_ notification: Notification) {
    if menuView.currentType != .text {
      return
    }
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
      let indexPath = IndexPath(row: viewmodel.messages.count - 1, section: 0)
      weak var weakSelf = self
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: DispatchWorkItem(block: {
        weakSelf?.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
      }))
    }
  }

  //    offset：value which from self.view.bottom to inputView.bottom
  var count = 0
  func layoutInputView(offset: CGFloat) {
    print("layoutInputView offset : ", offset)
    weak var weakSelf = self
    UIView.animate(withDuration: 0.1, animations: {
      weakSelf?.inputViewTopConstraint?.constant = -100 - offset
      weakSelf?.tableViewBottomConstraint?.constant = -100 - offset
    })
  }

  //    MARK: ChatInputViewDelegate

  public func sendText(text: String?) {
    guard let content = text, content.count > 0 else {
      return
    }
    if viewmodel.isReplying, let msg = viewmodel.operationModel?.message {
      viewmodel
        .replyMessage(MessageUtils.textMessage(text: content), msg) { [weak self] error in
          NELog.infoLog(
            ModuleName + " " + (self?.tag ?? "ChatViewController"),
            desc: "CALLBACK replyMessage " + (error?.localizedDescription ?? "no error")
          )
          if error != nil {
            self?.view.makeToast(error?.localizedDescription)
          } else {
            self?.viewmodel.isReplying = false
            self?.replyView.removeFromSuperview()
          }
        }

    } else {
      viewmodel.sendTextMessage(text: content) { [weak self] error in
        NELog.infoLog(
          ModuleName + " " + (self?.tag ?? "ChatViewController"),
          desc: "CALLBACK sendTextMessage " + (error?.localizedDescription ?? "no error")
        )
        if error != nil {
          self?.view.makeToast(error?.localizedDescription)
        }
      }
    }
  }

  public func didSelectMoreCell(cell: NEInputMoreCell) {
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
      showBottomVideoAction(self, false)
    } else if let type = cell.cellData?.type, type == .file {
      isFile = true
      showBottomFileAction(self)
    } else if let type = cell.cellData?.type, type == .rtc {
      showRtcCallAction()
    } else {}
  }

  func showRtcCallAction() {
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

  public func textChanged(text: String) -> Bool {
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

  public func textDelete(range: NSRange, text: String) -> Bool {
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
        var selRange = menuView.textField.selectedTextRange
        if let oldCursor = menuView.textField.selectedTextRange {
          if let newCursor = menuView.textField.position(from: oldCursor.start, offset: -rmRange.length) {
            selRange = menuView.textField.textRange(from: newCursor, to: newCursor)
          }
        }

        // 删除rmRange范围内的字符串（"@xxx "）
        let subRange = menuView.textField.text.utf16.index(menuView.textField.text.startIndex, offsetBy: rmRange.location) ... menuView.textField.text.utf16.index(menuView.textField.text.startIndex, offsetBy: rmRange.location + rmRange.length - 1)
        menuView.textField.text.removeSubrange(subRange)

        // 重新设置光标到删除前的位置
        menuView.textField.selectedTextRange = selRange
      }
      return false
    }
    return true
  }

  public func textFieldDidChange(_ textField: UITextView) {
    if let text = textField.text {
      if text.count > 0 {
        viewmodel.sendInputTypingState()
      } else {
        viewmodel.sendInputTypingEndState()
      }
    }
  }

  public func textFieldDidEndEditing(_ textField: UITextView) {
    viewmodel.sendInputTypingEndState()
  }

  public func textFieldDidBeginEditing(_ textField: UITextView) {
    if let count = textField.text?.count, count > 0 {
      viewmodel.sendInputTypingState()
    }
  }

  public func willSelectItem(button: UIButton, index: Int) {
    operationView?.removeFromSuperview()
    if index == 0 {
      layoutInputView(offset: 204)
      scrollTableViewToBottom()
    } else if index == 1 {
      layoutInputView(offset: 204)
      scrollTableViewToBottom()
    } else if index == 2 {
      goPhotoAlbumWithVideo(self)
    } else {
      // 更多
      layoutInputView(offset: 204)
      scrollTableViewToBottom()
      UIApplication.shared.keyWindow?.endEditing(true)
    }
  }

  func showMenue(sourceView: UIView) {
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

  func willSelectImage() {
    let imagePickerVC = UIImagePickerController()
    imagePickerVC.delegate = self
    imagePickerVC.allowsEditing = false
    imagePickerVC.sourceType = .photoLibrary
    present(imagePickerVC, animated: true) {}
  }

  func takePhoto() {
    let imagePickerVC = UIImagePickerController()
    imagePickerVC.delegate = self
    imagePickerVC.allowsEditing = false
    imagePickerVC.sourceType = .camera
    present(imagePickerVC, animated: true) {}
  }

  func sendMediaMessage(didFinishPickingMediaWithInfo info: [UIImagePickerController
      .InfoKey: Any]) {
    var imageName = "IMG_0001"
    if isFile,
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
      if isFile {
        copyFileToSend(url: url, displayName: imageName)
        isFile = false
      } else {
        viewmodel.sendVideoMessage(url: url) { error in
          NELog.infoLog(
            ModuleName + " " + self.tag,
            desc: "CALLBACK sendVideoMessage " + (error?.localizedDescription ?? "no error")
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

    if isFile,
       let imgData = image.pngData() {
      let imgSize_MB = Double(imgData.count) / 1e6
      print("@@# imgSize_MB: \(imgSize_MB) MB")
      if imgSize_MB > NEKitChatConfig.shared.ui.fileSizeLimit {
        showToast(chatLocalizable("fileSize_over_limit"))
      } else {
        viewmodel.sendFileMessage(data: imgData, displayName: imageName) { [weak self] error in
          NELog.infoLog(
            ModuleName + " " + (self?.tag ?? "ChatViewController"),
            desc: "CALLBACK sendFileMessage \(imageName) by Data " + (error?.localizedDescription ?? "no error")
          )
          if error != nil {
            self?.view.makeToast(error!.localizedDescription)
          }
        }
      }
      isFile = false
    } else {
      viewmodel.sendImageMessage(image: image) { [weak self] error in
        NELog.infoLog(
          ModuleName + " " + (self?.tag ?? "ChatViewController"),
          desc: "CALLBACK sendImageMessage " + (error?.localizedDescription ?? "no error")
        )
        if error != nil {
          self?.view.makeToast(error?.localizedDescription)
        }
      }
    }
  }

  //    MARK: UIImagePickerControllerDelegate

  public func imagePickerController(_ picker: UIImagePickerController,
                                    didFinishPickingMediaWithInfo info: [UIImagePickerController
                                      .InfoKey: Any]) {
//                                          picker.dismiss(animated: true, completion: nil)
//                                          sendMediaMessage(didFinishPickingMediaWithInfo: info)
    weak var weakSelf = self
    picker.dismiss(animated: true, completion: {
      weakSelf?.sendMediaMessage(didFinishPickingMediaWithInfo: info)
    })
  }

  public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
    isFile = false
  }

  //    MARK: UIDocumentPickerDelegate

  func copyFileToSend(url: URL, displayName: String) {
    let desPath = NSTemporaryDirectory() + "\(url.lastPathComponent)"
    let dirUrl = URL(fileURLWithPath: desPath)
    if !FileManager.default.fileExists(atPath: desPath) {
      print("@@# file not exist:", desPath)
      do {
        try FileManager.default.copyItem(at: url, to: dirUrl)
      } catch {
        print("❌ copyItem [\(desPath)] ERROR", error)
      }
    }
    if FileManager.default.fileExists(atPath: desPath) {
      print("@@# fileExists:", desPath)
      do {
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: desPath)
        if let size_B = fileAttributes[FileAttributeKey.size] as? Double {
          print("@@# size:\(size_B)B")
          let size_MB = size_B / 1e6
          print("@@# size:\(size_MB)MB")
          if size_MB > NEKitChatConfig.shared.ui.fileSizeLimit {
            showToast(chatLocalizable("fileSize_over_limit"))
            try? FileManager.default.removeItem(atPath: desPath)
          } else {
            viewmodel.sendFileMessage(filePath: desPath, displayName: displayName) { [weak self] error in
              NELog.infoLog(
                ModuleName + " " + (self?.tag ?? "ChatViewController"),
                desc: "CALLBACK sendFileMessage " + (error?.localizedDescription ?? "no error")
              )
              if error != nil {
                self?.view.makeToast(error!.localizedDescription)
              }
            }
          }
        }
      } catch {
        print("@@#\(#function) get file size error:", error)
      }
    }
  }

  public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    controller.dismiss(animated: true)
    guard let url = urls.first else { return }
    print("@@# url", url)

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
      print("@@#❌ fileUrlAuthozied FAILED, url:", url)
    }
    isFile = false
  }

  // MARK: UIDocumentInteractionControllerDelegate

  public func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
    self
  }

  public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    controller.dismiss(animated: true)
    isFile = false
  }

  //    MARK: ChatViewModelDelegate

  public func didLeaveTeam() {
    weak var weakSelf = self
    showSingleAlert(message: chatLocalizable("team_has_quit")) {
      weakSelf?.navigationController?.popViewController(animated: true)
    }
  }

  public func didDismissTeam() {
    weak var weakSelf = self
    showSingleAlert(message: chatLocalizable("team_has_been_removed")) {
      weakSelf?.navigationController?.popViewController(animated: true)
    }
  }

  public func onRecvMessages(_ messages: [NIMMessage]) {
    insertRows()
    if isCurrentPage,
       UIApplication.shared.applicationState == .active {
      viewmodel.markRead(messages: messages) { error in
        NELog.infoLog(
          ModuleName + " " + self.tag,
          desc: "CALLBACK markRead " + (error?.localizedDescription ?? "no error")
        )
      }
    } else {
      needMarkReadMsgs += messages
    }
  }

  public func willSend(_ message: NIMMessage) {
    insertRows()
  }

  public func send(_ message: NIMMessage, progress: Float) {}

  public func send(_ message: NIMMessage, didCompleteWithError error: Error?) {
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

  public func onDeleteMessage(_ message: NIMMessage, atIndexs: [IndexPath]) {
    if atIndexs.isEmpty {
      return
    }
    //        self.tableView.reloadData()
    tableViewDeleteIndexs(atIndexs)
  }

  public func updateDownloadProgress(_ message: NIMMessage, atIndex: IndexPath, progress: Float) {
    tableViewUpdateDownload(atIndex)
  }

  public func onRevokeMessage(_ message: NIMMessage, atIndexs: [IndexPath]) {
    if atIndexs.isEmpty {
      return
    }
    print("on revoke message at indexs :", atIndexs)
//    weak var weakSelf = self
//    viewmodel.saveRevokeMessage(message) { error in
//      print("message id : ", message.messageId)
//      if let err = error {
//        NELog.infoLog(weakSelf?.className() ?? "chat view controller", desc: err.localizedDescription)
//      }
//    }
    tableViewReloadIndexs(atIndexs)
  }

  public func onAddMessagePin(_ message: NIMMessage, atIndexs: [IndexPath]) {
    tableViewReloadIndexs(atIndexs)
  }

  public func onRemoveMessagePin(_ message: NIMMessage, atIndexs: [IndexPath]) {
    tableViewReloadIndexs(atIndexs)
  }

  public func tableViewDeleteIndexs(_ indexs: [IndexPath]) {
    tableView.beginUpdates()
    tableView.deleteRows(at: indexs, with: .none)
    tableView.endUpdates()
  }

  public func tableViewReloadIndexs(_ indexs: [IndexPath]) {
//      print("table view reload stack : ", Thread.callStackSymbols)
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

  public func didReadedMessageIndexs() {
    tableView.reloadData()
//    if let indexPaths = tableView.indexPathsForVisibleRows, indexPaths.count > 0 {
//      tableView.beginUpdates()
//      tableView.reloadRows(at: indexPaths, with: .none)
//      tableView.endUpdates()
//    }
  }

  public func tableViewUpdateDownload(_ index: IndexPath) {
    tableView.beginUpdates()
    tableView.reloadRows(at: [index], with: .none)
    tableView.endUpdates()
  }

  // record audio
  public func startRecord() {
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

  public func moveOutView() {}

  public func moveInView() {}

  public func endRecord(insideView: Bool) {
    print("[record] stop:\(insideView)")
    if insideView {
      //            send
      NIMSDK.shared().mediaManager.stopRecord()
    } else {
      //            cancel
      NIMSDK.shared().mediaManager.cancelRecord()
    }
  }

  func viewTap(tap: UITapGestureRecognizer) {
    if let opeView = operationView,
       view.subviews.contains(opeView) {
      opeView.removeFromSuperview()

    } else {
      if menuView.textField.isFirstResponder {
        menuView.textField.resignFirstResponder()
      } else {
        layoutInputView(offset: 0)
      }
    }
  }

  // MARK: audio play

  private func startPlay(cell: ChatAudioCell?, audio: NIMAudioObject) {
    if cell?.isPlaying == true {
      stopPlay()
    } else {
      stopPlay()
      playingCell = cell
      playingCell?.startAnimation()
      if let url = audio.path {
        if viewmodel.getHandSetEnable() == true {
          NIMSDK.shared().mediaManager.switch(.receiver)
        } else {
          NIMSDK.shared().mediaManager.switch(.speaker)
        }
        NIMSDK.shared().mediaManager.play(url)
      }
    }
  }

  private func stopPlay() {
    if NIMSDK.shared().mediaManager.isPlaying() {
      playingCell?.startAnimation()
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
  public func playAudio(_ filePath: String, didBeganWithError error: Error?) {
    print(#function + "\(error)")
    if let e = error {
      showToast(e.localizedDescription)
      // stop
      playingCell?.stopAnimation()
    }
  }

  public func playAudio(_ filePath: String, didCompletedWithError error: Error?) {
    print(#function + "\(error)")
    if let e = error {
      showToast(e.localizedDescription)
    }
    // stop
    playingCell?.stopAnimation()
  }

  public func stopPlayAudio(_ filePath: String, didCompletedWithError error: Error?) {
    print(#function + "\(error)")
    if let e = error {
      showToast(e.localizedDescription)
    }
    playingCell?.stopAnimation()
  }

  public func playAudio(_ filePath: String, progress value: Float) {}

  public func playAudioInterruptionEnd() {
    print(#function)
  }

  public func playAudioInterruptionBegin() {
    print(#function)
    // stop play
    playingCell?.stopAnimation()
  }

  //    record
  public func recordAudio(_ filePath: String?, didBeganWithError error: Error?) {
    print("[record] sdk Began error:\(error)")
  }

  public func recordAudio(_ filePath: String?, didCompletedWithError error: Error?) {
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
          desc: "CALLBACK sendAudioMessage " + (error?.localizedDescription ?? "no error")
        )
        if let e = error {
          self.showToast(e.localizedDescription)
        } else {}
      }
    } else {
      showToast(chatLocalizable("record_too_short"))
    }
  }

  public func recordAudioDidCancelled() {
    print("[record] sdk cancel")
  }

  public func recordAudioProgress(_ currentTime: TimeInterval) {}

  public func recordAudioInterruptionBegin() {
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
    for (i, model) in viewmodel.messages.enumerated() {
      if i >= oldRows {
        indexs.append(IndexPath(row: i, section: 0))
      }
    }

    if !indexs.isEmpty {
      tableView.insertRows(at: indexs, with: .none)
      tableView.scrollToRow(
        at: IndexPath(row: viewmodel.messages.count - 1, section: 0),
        at: .bottom,
        animated: false
      )
    }
  }

  func addToAtUsers(addText: String, isReply: Bool = false) {
    // @列表中添加一项
    let anIndex = menuView.textField.selectedRange.location
    var range = NSRange(location: anIndex - 1, length: addText.utf16.count + 1)
    if isReply {
      range = NSRange(location: anIndex, length: addText.utf16.count)
    }
    atUsers.append(range)

    //  添加range后，range.location后面所有的atUser的location都发生了变化
    var atUsersTmp = [NSRange]()
    for atUser in atUsers {
      if range.location < atUser.location {
        atUsersTmp.append(NSRange(location: atUser.location + range.length, length: atUser.length))
      } else {
        atUsersTmp.append(atUser)
      }
    }
    if atUsersTmp.count > 0 {
      atUsers = atUsersTmp
    }

    // range范围内添加字符串（"@xxx "）
    if let pos = menuView.textField.selectedTextRange {
      // 用replace代替insert（start==end）
      menuView.textField.replace(pos, withText: addText)
    } else {
      menuView.textField.text += addText
    }
  }

  private func showUserSelectVC(text: String) {
    let selectVC = SelectUserViewController(sessionId: viewmodel.session.sessionId, showSelf: false)
    selectVC.modalPresentationStyle = .formSheet
    selectVC.selectedBlock = { [weak self] index, model in
      var addText = ""

      if index == 0 {
        addText += chatLocalizable("user_select_all") + " "
      } else {
        if let m = model {
          var name = ""
          if let nick = m.nimUser?.userInfo?.nickName {
            name = nick
          } else if let uid = m.nimUser?.userId {
            name = uid
          }
          addText += name + " "
        }
      }

      self?.addToAtUsers(addText: addText)
    }
    present(selectVC, animated: true, completion: nil)
  }

  //    MARK: MessageOperationViewDelegate

  public func didSelectedItem(item: OperationItem) {
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
      doNothing()
    }
  }

  private func doNothing() {}

  private func copyMessage() {
    if let model = viewmodel.operationModel as? MessageTextModel,
       let text = model.message?.text {
      let pasteboard = UIPasteboard.general
      pasteboard.string = text
      view.makeToast(chatLocalizable("copy_success"), duration: 2, position: .center)
    }
  }

  private func deleteMessage() {
    showAlert(message: chatLocalizable("message_delete_comfirm")) {
      if let message = self.viewmodel.operationModel?.message {
        self.viewmodel.deleteMessage(message: message)
      }
    }
  }

  private func showReplyMessageView() {
    viewmodel.isReplying = true
    view.addSubview(replyView)
    replyView.closeButton.addTarget(self, action: #selector(cancelReply), for: .touchUpInside)
    replyView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      replyView.leadingAnchor.constraint(equalTo: menuView.leadingAnchor),
      replyView.trailingAnchor.constraint(equalTo: menuView.trailingAnchor),
      replyView.bottomAnchor.constraint(equalTo: menuView.topAnchor),
      replyView.heightAnchor.constraint(equalToConstant: 36),
    ])
    if let message = viewmodel.operationModel?.message {
      var text = chatLocalizable("msg_reply")
      if let uid = message.from {
        let user = viewmodel.getUserInfo(userId: uid)
        let name = user?.userInfo?.nickName
        if viewmodel.session.sessionType != .P2P,
           !IMKitClient.instance.isMySelf(uid) {
          addToAtUsers(addText: "@" + (name ?? uid) + " ", isReply: true)
        }
        text += " " + (name ?? uid)
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
        text += ""
      }
      replyView.textLabel.text = text
      menuView.textField.becomeFirstResponder()
    }
  }

  @objc private func cancelReply(button: UIButton) {
    replyView.removeFromSuperview()
    viewmodel.isReplying = false
  }

  private func recallMessage() {
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
            desc: "CALLBACK revokeMessage " + (error?.localizedDescription ?? "no error")
          )
          if error != nil {
            weakSelf?.showToast(error!.localizedDescription)
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

  private func collectionMessage() {
    if let message = viewmodel.operationModel?.message {
      viewmodel.addColletion(message) { error, info in
        NELog.infoLog(
          ModuleName + " " + self.tag,
          desc: "CALLBACK addColletion " + (error?.localizedDescription ?? "no error")
        )
        if error != nil {
          self.showToast(error!.localizedDescription)
        } else {
          self.showToast(chatLocalizable("collection_success"))
        }
      }
    }
  }

  private func forwardMessage() {
    if let message = viewmodel.operationModel?.message {
      weak var weakSelf = self
      let userAction = UIAlertAction(title: chatLocalizable("contact_user"),
                                     style: .default) { action in

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

            let forwardAlert = ForwardAlertViewController()
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

      let teamAction = UIAlertAction(title: chatLocalizable("team"), style: .default) { action in

        Router.shared.register(ContactTeamDataRouter) { param in
          if let team = param["team"] as? NIMTeam {
            let item = ForwardItem()
            item.avatar = team.avatarUrl
            item.name = team.getShowName()
            item.uid = team.teamId

            let forwardAlert = ForwardAlertViewController()
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

      let cancelAction = UIAlertAction(title: chatLocalizable("cancel"),
                                       style: .cancel) { action in
      }

      showActionSheet([teamAction, userAction, cancelAction])
    }
  }

  private func pinMessage() {
    if let message = viewmodel.operationModel?.message {
      viewmodel.pinMessage(message) { [weak self] error, pinItem, index in
        NELog.infoLog(
          ModuleName + " " + (self?.tag ?? "ChatViewController"),
          desc: "CALLBACK pinMessage " + (error?.localizedDescription ?? "no error")
        )
        if error != nil {
          self?.view.makeToast(error?.localizedDescription)
        } else {
          //                    update UI
          if index >= 0 {
            self?.tableViewReloadIndexs([IndexPath(row: index, section: 0)])
          }
        }
      }
    }
  }

  private func removePinMessage() {
    if let message = viewmodel.operationModel?.message {
      viewmodel.removePinMessage(message) { [weak self] error, pinItem, index in
        NELog.infoLog(
          ModuleName + " " + (self?.tag ?? "ChatViewController"),
          desc: "CALLBACK removePinMessage " + (error?.localizedDescription ?? "no error")
        )
        if error != nil {
          self?.view.makeToast(error?.localizedDescription)
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

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let count = viewmodel.messages.count
    print("numberOfRowsInSection count : ", count)
    return count
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = viewmodel.messages[indexPath.row]
    var reuseId = ""
    if let isSend = model.message?.isOutgoingMsg, isSend {
      if model.replyedModel?.isReplay == true {
        reuseId = "\(ChatReplyRightCell.self)"
      } else {
        switch model.type {
        case .text:
          reuseId = "\(ChatTextRightCell.self)"
        case .image:
          reuseId = "\(ChatImageRightCell.self)"
        case .audio:
          reuseId = "\(ChatAudioRightCell.self)"
        case .video:
          reuseId = "\(ChatVideoRightCell.self)"
        case .time, .tip, .notification:
          reuseId = "\(ChatTimeTableViewCell.self)"
        case .revoke:
          reuseId = "\(ChatRevokeRightCell.self)"
        case .location:
          reuseId = "\(ChatLocationRightCell.self)"
        case .file:
          reuseId = "\(ChatFileRightCell.self)"
        case .rtcCallRecord:
          reuseId = "\(ChatCallRecordRightCell.self)"
        default:
          reuseId = "\(ChatBaseRightCell.self)"
        }
      }

      let cell = tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath)
      if let c = cell as? ChatTimeTableViewCell {
        if let m = model as? MessageTipsModel {
          c.setModel(m)
        }
        return c
      } else if let c = cell as? ChatBaseRightCell {
        c.delegate = self
        if let m = model as? MessageContentModel {
          c.setModel(m)
        }
        return c
      } else {
        return ChatBaseRightCell()
      }
    } else {
      if model.replyedModel?.isReplay == true {
        reuseId = "\(ChatReplyLeftCell.self)"
      } else {
        switch model.type {
        case .text:
          reuseId = "\(ChatTextLeftCell.self)"
        case .image:
          reuseId = "\(ChatImageLeftCell.self)"
        case .audio:
          reuseId = "\(ChatAudioLeftCell.self)"
        case .video:
          reuseId = "\(ChatVideoLeftCell.self)"
        case .file:
          reuseId = "\(ChatFileLeftCell.self)"
        case .time, .tip, .notification:
          reuseId = "\(ChatTimeTableViewCell.self)"
        case .revoke:
          reuseId = "\(ChatRevokeLeftCell.self)"
        case .location:
          reuseId = "\(ChatLocationLeftCell.self)"
        case .rtcCallRecord:
          reuseId = "\(ChatCallRecordLeftCell.self)"
        default:
          reuseId = "\(ChatBaseLeftCell.self)"
        }
      }

      let cell = tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath)
      if let c = cell as? ChatTimeTableViewCell {
        if let m = model as? MessageTipsModel {
          c.setModel(m)
        }
        return c
      } else if let c = cell as? ChatBaseLeftCell {
        c.delegate = self
        if let m = model as? MessageContentModel {
          c.setModel(m)
        }
        return c
      } else {
        return ChatBaseLeftCell()
      }
    }
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    operationView?.removeFromSuperview()
    if menuView.textField.isFirstResponder {
      menuView.textField.resignFirstResponder()
    } else {
      layoutInputView(offset: 0)
    }
  }

  public func tableView(_ tableView: UITableView,
                        heightForRowAt indexPath: IndexPath) -> CGFloat {
    let m = viewmodel.messages[indexPath.row]
    return CGFloat(m.height)
  }

  public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    0
  }

  public func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
    0
  }

  // MARK: UIScrollViewDelegate

  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    operationView?.removeFromSuperview()
  }

  // MARK: CLLocationManagerDelegate

//    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
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

  public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
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

  public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {}

  public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

//    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        print(error)
//    }
}

// MARK: ChatBaseCellDelegate

extension ChatViewController: ChatBaseCellDelegate {
  public func didTapAvatarView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    didTapHeadPortrait(model: model)
  }

  public func didTapMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    if model?.type == .audio {
      if let audio = model?.message?.messageObject as? NIMAudioObject {
        startPlay(cell: cell as? ChatAudioCell, audio: audio)
      }
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

//                if let url = imageObject.url {
//                    let showController = PhotoBrowserController(urls: viewmodel.getUrls(), url: url)
//                    showController.modalPresentationStyle = .overFullScreen
//                    self.present(showController, animated: false, completion: nil)
//                }
      }

    } else if model?.type == .video,
              let object = model?.message?.messageObject as? NIMVideoObject {
      print("video click")
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

        videoModel.state = .Downalod
        if let left = cell as? ChatVideoLeftCell {
          left.setModel(videoModel)
        } else if let right = cell as? ChatVideoRightCell {
          right.setModel(videoModel)
        }

        viewmodel.downLoad(urlString, path) { progress in
          NELog.infoLog(ModuleName + " " + (weakSelf?.tag ?? "ChatViewController"), desc: "CALLBACK downLoad: \(progress)")

          videoModel.progress = progress
          if progress >= 1.0 {
            videoModel.state = .Success
          }
          videoModel.cell?.uploadProgress(progress)

          // SDK返回异常
//          let trueProgress = -progress / Float(object.fileLength)
//          videoModel.progress = trueProgress
//          if trueProgress >= 1.0 {
//            videoModel.state = .Success
//          }
//          videoModel.cell?.uploadProgress(trueProgress)
        } _: { error in
          if let err = error as NSError? {
            weakSelf?.showToast(err.localizedDescription)
          }
        }
      }
    } else if model?.type == .text {
//            location at replied message
      if model?.replyedModel != nil {
        if model?.message?.repliedMessageId != nil {
          var index = -1
          for (i, m) in viewmodel.messages.enumerated() {
            if model?.message?.repliedMessageServerId == m.message?.serverID {
              index = i
              break
            }
          }
          if index >= 0 {
            tableView.scrollToRow(
              at: IndexPath(row: index, section: 0),
              at: .middle,
              animated: true
            )
          }
        }
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
              let object = model?.message?.messageObject as? NIMFileObject {
      if let path = object.path, FileManager.default.fileExists(atPath: path) == true {
        let url = URL(fileURLWithPath: path)
        print("@@# file:\(url) has download")
        interactionController.url = url
        interactionController.delegate = self // UIDocumentInteractionControllerDelegate
        if interactionController.presentPreview(animated: true) {}
        else {
          interactionController.presentOptionsMenu(from: view.bounds, in: view, animated: true)
        }
      } else if let urlString = object.url, let path = object.path,
                let fileModel = model as? MessageFileModel {
        fileModel.state = .Downalod
        if let left = cell as? ChatFileLeftCell {
          left.setModel(fileModel)
        } else if let right = cell as? ChatFileRightCell {
          right.setModel(fileModel)
        }

        viewmodel.downLoad(urlString, path) { [weak self] progress in
          NELog.infoLog(ModuleName + " " + (self?.tag ?? "ChatViewController"), desc: "@@# CALLBACK downLoad: \(progress)")
          var newProgress = progress
          if newProgress < 0 {
            newProgress = abs(progress) / fileModel.size
          }
          fileModel.progress = newProgress
          if newProgress >= 1.0 {
            fileModel.state = .Success
          }
          fileModel.cell?.uploadProgress(newProgress)

        } _: { [weak self] error in
          if let err = error as NSError? {
            self?.showToast(err.localizedDescription)
          }
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
      print(#function + "message did tap but type unknow")
    }
  }

  public func didLongPressMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    didLongTouchMessageView(cell, model)
  }

  public func didTapResendView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
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

  public func didTapReeditButton(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    if model?.type == .revoke, model?.message?.messageType == .text, let message = model?.message {
      let time = message.timestamp
      let date = Date()
      let currentTime = date.timeIntervalSince1970
      if currentTime - time >= 60 * 2 {
        showToast(chatLocalizable("editable_time_expired"))
        tableView.reloadData()
        return
      }
      menuView.textField.text = model?.message?.text
      menuView.textField.becomeFirstResponder()
    }
  }

  public func didTapReadView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    if let msg = model?.message, msg.session?.sessionType == .team {
      let readVC = ReadViewController(message: msg)
      navigationController?.pushViewController(readVC, animated: true)
    }
  }
}
