
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
open class ChatViewController: NEChatBaseViewController, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UIDocumentPickerDelegate, UIDocumentInteractionControllerDelegate, NIMMediaManagerDelegate, CLLocationManagerDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, ChatInputViewDelegate, ChatInputMultilineDelegate, ChatViewModelDelegate, MessageOperationViewDelegate, NETranslateViewDelegate, SelectLanguageDelegate {
  private let kCallKitDismissNoti = "kCallKitDismissNoti"
  private let kCallKitShowNoti = "kCallKitShowNoti"
  public var titleContent = ""
  var audioPlayer: AVAudioPlayer? // 仅用于语音消息的播放

  public var viewModel: ChatViewModel = .init()
  let interactionController = UIDocumentInteractionController()
  private lazy var manager = CLLocationManager()
  private var playingCell: ChatAudioCellProtocol?
  private var playingModel: MessageAudioModel?
  private var anchorCell: NEBaseChatMessageCell? // 锚点跳转时的 cell（视频、文件）
  private var anchorModel: MessageVideoModel? // 锚点跳转时的 model（视频、文件）
  private var timer: Timer?
  private var isFile: Bool? // 是否以文件形式发送
  public var isCurrentPage = true
  public var isMute = false // 是否禁言
  private var isMutilSelect = false // 是否多选模式
  private var isLoadingData = false // 是否正在加载数据
  private var hasFirstLoadData = false // 是否完成第一次加载数据
  private var uploadHasNoMore = false // 上拉无更多数据
  private var networkBroken = false // 网络断开标志

  public var operationCellFilter: [OperationType]? // 消息长按菜单全局过滤列表
  public var cellRegisterDic = [String: UITableViewCell.Type]()
  private var needMarkReadMsgs = [V2NIMMessage]()
  private var atUsers = [NSRange]()

  lazy var replyView: ReplyView = {
    let view = ReplyView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.closeButton.addTarget(self, action: #selector(closeReply), for: .touchUpInside)
    return view
  }()

  public var normalOffset: CGFloat = 0
  public var bottomExanpndHeight: CGFloat = 204 // 底部展开高度
  public var normalInputHeight: CGFloat = 100
  public var brokenNetworkViewHeight: CGFloat = 36
  public var currentKeyboardHeight: CGFloat = 0

  // 顶部扩展视图距 view 顶部的间距
  public var bodyTopViewTopConstant: CGFloat = 0 {
    didSet {
      bodyTopViewTopAnchor?.constant = bodyTopViewTopConstant
    }
  }

  // 顶部扩展视图的高度
  public lazy var bodyTopViewHeight: CGFloat = 0 {
    didSet {
      bodyTopViewHeightAnchor?.constant = bodyTopViewHeight
      bodyTopView.isHidden = bodyTopViewHeight <= 0
    }
  }

  // 底部扩展视图的高度
  public lazy var bodyBottomViewHeight: CGFloat = 0 {
    didSet {
      bodyBottomViewHeightAnchor?.constant = bodyBottomViewHeight
      bodyBottomView.isHidden = bodyBottomViewHeight <= 0
    }
  }

  // 底部内容视图（包含输入框）的高度
  public lazy var bottomViewHeight: CGFloat = 404 {
    didSet {
      bottomViewHeightAnchor?.constant = bottomViewHeight
    }
  }

  // 顶部扩展视图顶部布局约束
  public var bodyTopViewTopAnchor: NSLayoutConstraint?

  // 顶部扩展视图高度布局约束
  public var bodyTopViewHeightAnchor: NSLayoutConstraint?

  // 底部扩展视图高度布局约束
  public var bodyBottomViewHeightAnchor: NSLayoutConstraint?

  // 内容视图顶部布局约束
  public var contentViewTopAnchor: NSLayoutConstraint?

  // 底部扩展视图顶部布局约束
  public var bottomViewTopAnchor: NSLayoutConstraint?

  // 底部扩展视图高度布局约束
  public var bottomViewHeightAnchor: NSLayoutConstraint?

  // 翻译视图高度布局约束
  public var translateLanguageViewHeightAnchor: NSLayoutConstraint?

  // 顶部扩展视图
  public lazy var bodyTopView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.clear
    return view
  }()

  // 中部视图（包含断网横幅和内容视图）
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

  // 断网横幅
  public lazy var brokenNetworkView: NEBrokenNetworkView = {
    let view = NEBrokenNetworkView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    return view
  }()

  // 内容视图
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

  // 底部扩展视图
  public lazy var bodyBottomView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.clear
    return view
  }()

  // 底部内容视图（包含输入框等）
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

  /// 消息置顶视图
  public lazy var topMessageView: TopMessageView = {
    let topMessageView = TopMessageView()
    topMessageView.translatesAutoresizingMaskIntoConstraints = false
    topMessageView.delegate = self
    return topMessageView
  }()

  /// 翻译框
  public lazy var translateLanguageView: NEAITranslateView = {
    let translateView = NEAITranslateView()
    translateView.translatesAutoresizingMaskIntoConstraints = false
    translateView.delegate = self
    return translateView
  }()

  /// 长按操作菜单
  public lazy var operationView: MessageOperationView = {
    let operationView = MessageOperationView(frame: .zero)
    operationView.isHidden = true
    operationView.delegate = self
    view.addSubview(operationView)
    return operationView
  }()

  public init(conversationId: String) {
    super.init(nibName: nil, bundle: nil)

    NEKeyboardManager.shared.enable = false
    NEKeyboardManager.shared.enableAutoToolbar = false
    addListener()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  /// 添加监听
  open func addListener() {
    NIMSDK.shared().mediaManager.add(self)
    IMKitClient.instance.addLoginListener(self)
  }

  /// 移除监听
  open func removeListener() {
    NIMSDK.shared().mediaManager.remove(self)
    IMKitClient.instance.removeLoginListener(self)
    viewModel.delegate = nil
  }

  deinit {
    NEALog.infoLog(className(), desc: "deinit")
    viewModel.clearUnreadCount()
    removeListener()
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    NEKeyboardManager.shared.enable = false
    NEKeyboardManager.shared.shouldResignOnTouchOutside = false
    isCurrentPage = true
    markNeedReadMsg()

    if NEKitChatConfig.shared.ui.messageProperties.showTitleBar {
      bodyTopViewTopConstant = topConstant
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
    navigationController?.interactivePopGestureRecognizer?.delegate = self
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

    weakSelf?.viewModel.translationAIUser = NEAIUserManager.shared.getAITranslateUser()
  }

  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.interactivePopGestureRecognizer?.delegate = nil
    NEKeyboardManager.shared.enable = true
    NEKeyboardManager.shared.shouldResignOnTouchOutside = true
    isCurrentPage = false
    removeOperationView()
    if audioPlayer?.isPlaying == true {
      audioPlayer?.stop()
    }

    chatInputView.textView.resignFirstResponder()
    chatInputView.titleField.resignFirstResponder()
  }

  override open func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    stopPlay()
  }

  override open func didMove(toParent parent: UIViewController?) {
    super.didMove(toParent: parent)
    if parent == nil {
      let param = ["sessionId": viewModel.conversationId]
      Router.shared.use("ClearAtMessageRemind", parameters: param, closure: nil)

      NETeamUserManager.shared.removeAllTeamInfo()
    }
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
    if IMKitConfigCenter.shared.enableAIUser == true {
      view.addSubview(translateLanguageView)
      translateLanguageView.chatInputText = chatInputView.textView
    }

    bodyTopViewHeightAnchor = bodyTopView.heightAnchor.constraint(equalToConstant: bodyTopViewHeight)
    bodyTopViewHeightAnchor?.isActive = true
    bodyTopViewTopAnchor = bodyTopView.topAnchor.constraint(equalTo: view.topAnchor, constant: bodyTopViewTopConstant)
    bodyTopViewTopAnchor?.isActive = true
    NSLayoutConstraint.activate([
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

    if IMKitConfigCenter.shared.enableAIUser {
      translateLanguageViewHeightAnchor = translateLanguageView.heightAnchor.constraint(equalToConstant: 0)
      NSLayoutConstraint.activate([
        translateLanguageView.leftAnchor.constraint(equalTo: view.leftAnchor),
        translateLanguageView.rightAnchor.constraint(equalTo: view.rightAnchor),
        translateLanguageView.bottomAnchor.constraint(equalTo: bodyBottomView.topAnchor),
        translateLanguageViewHeightAnchor!,
      ])

      NSLayoutConstraint.activate([
        bodyView.topAnchor.constraint(equalTo: bodyTopView.bottomAnchor),
        bodyView.leftAnchor.constraint(equalTo: view.leftAnchor),
        bodyView.rightAnchor.constraint(equalTo: view.rightAnchor),
        bodyView.bottomAnchor.constraint(equalTo: translateLanguageView.topAnchor),
      ])
    } else {
      NSLayoutConstraint.activate([
        bodyView.topAnchor.constraint(equalTo: bodyTopView.bottomAnchor),
        bodyView.leftAnchor.constraint(equalTo: view.leftAnchor),
        bodyView.rightAnchor.constraint(equalTo: view.rightAnchor),
        bodyView.bottomAnchor.constraint(equalTo: bodyBottomView.topAnchor),
      ])
    }

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

  // MARK: - 子类可重写方法

  public func onTeamMemberChange(team: V2NIMTeam) {}

  override open func backEvent() {
    super.backEvent()
    removeListener()
  }

  // load data的时候会调用
  open func getSessionInfo(sessionId: String, _ completion: @escaping () -> Void) {
    if NEFriendUserCache.shared.getFriendInfo(IMKitClient.instance.account()) == nil {
      ContactRepo.shared.getUserListFromCloud(accountIds: [IMKitClient.instance.account()]) { users, error in
        completion()
      }
    } else {
      completion()
    }
  }

  /// 点击头像回调
  /// - Parameter model: cell模型
  open func didTapHeadPortrait(model: MessageContentModel?) {
    if !ChatMessageHelper.isAISender(model?.message),
       let isOut = model?.message?.isSelf, isOut {
      Router.shared.use(
        MeSettingRouter,
        parameters: ["nav": navigationController as Any],
        closure: nil
      )
      return
    }
    if let uid = ChatMessageHelper.getSenderId(model?.message) {
      Router.shared.use(
        ContactUserInfoPageRouter,
        parameters: ["nav": navigationController as Any, "uid": uid],
        closure: nil
      )
    }
  }

  open func setOperationItems(items: inout [OperationItem], model: MessageContentModel?) {}

  func removeOperationView(_ cellEndEditing: Bool = true) {
    if operationView.isHidden == false {
      operationView.isHidden = true
    }

    // 取消划词选中
    if cellEndEditing {
      viewModel.operationModel?.cell?.contentView.endEditing(true)
    }
  }

  /// 好友（用户）信息变更回调
  /// - Parameter accountId: 用户 id
  open func onUserOrFriendInfoChanged(_ accountId: String) {
    let sessionId = viewModel.sessionId

    if accountId == sessionId {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: DispatchWorkItem(block: { [weak self] in
        let showName = NETeamUserManager.shared.getShowName(sessionId)
        self?.titleContent = showName
        self?.title = showName
      }))
    }
    viewModel.updateMessageInfo(accountId)
  }

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

    // get operations
    guard var items = viewModel.avalibleOperationsForMessage(model) else {
      return
    }

    // 插件导入
    var pluginItems: [OperationItem] = []
    if let text = model?.selectText() {
      // 划词
      if NEAIUserManager.shared.getAISearchUser() == nil {
        // 未配置划词数字人
        NEALog.infoLog(ModuleName + " " + ChatViewController.className(), desc: "AI Search User is nil")
      } else if IMKitConfigCenter.shared.enableAIUser == false {
        // 未开启全局数字人开关
        NEALog.infoLog(ModuleName + " " + ChatViewController.className(), desc: "IMKitConfigCenter enableAIUser is false")
      } else {
        pluginItems.append(contentsOf: IMKitPluginManager.shared.getPlugins(NEAISearchPlugin, text))
      }
    }

    // 划词（非全选）只展示【复制】、【AI划词搜】
    if let model = model as? MessageTextModel {
      if let selectRange = model.selectRange,
         selectRange.length > 0 {
        if model.attributeStr == nil, let model = model as? MessageRichTextModel {
          if selectRange.length != model.titleAttributeStr?.string.utf16.count {
            items = items.filter { item in
              item.type == .copy
            }
          }
        } else if selectRange.length != model.attributeStr?.string.utf16.count {
          items = items.filter { item in
            item.type == .copy
          }
        }
      } else {
        removeOperationView()
        return
      }
    }

    items.append(contentsOf: pluginItems)

    // 全局过滤
    if let filter = operationCellFilter {
      items = items.filter { item in
        if let type = item.type {
          return !filter.contains(type)
        }
        return true
      }
    }

    // 配置项自定义 items
    if let chatPopMenu = NEKitChatConfig.shared.ui.chatPopMenu {
      chatPopMenu(&items, model)
    }

    // 供用户自定义 items
    setOperationItems(items: &items, model: model)

    guard let index = tableView.indexPath(for: cell) else {
      tableViewReload()
      return
    }

    removeOperationView()
    if viewModel.operationModel != model {
      viewModel.operationModel?.cell?.resetSelectRange()
      viewModel.operationModel = model
      viewModel.operationModel?.cell?.selectAllRange()
    }

    // 计算宽高
    let w = items.count <= 5 ? 60.0 * Double(items.count) + 16.0 : 60.0 * 5 + 16.0
    let h = items.count <= 5 ? 56.0 + 16.0 : 56.0 * 2 + 16.0

    let rectInTableView = tableView.rectForRow(at: index)
    let rectInView = tableView.convert(rectInTableView, to: view)
    let topOffset = NEConstant.navigationAndStatusHeight

    var operationY = 0.0
    if topOffset + h + bodyTopViewHeight > rectInView.origin.y {
      operationY = rectInView.origin.y + rectInView.size.height - chat_timeCellH
    } else {
      // 位于消息上方
      operationY = rectInView.origin.y - h
      if model?.timeContent != nil {
        operationY += chat_timeCellH
      }
    }

    var frameX = 56.0
    if let msg = model?.message,
       msg.isSelf {
      frameX = kScreenWidth - w - frameX
    }

    var frame = CGRect(x: frameX, y: operationY, width: w, height: h)
    if frame.origin.y + h < tableView.frame.origin.y {
      frame.origin.y = tableView.frame.origin.y
    } else if frame.origin.y + h > view.frame.size.height {
      frame.origin.y = tableView.frame.origin.y + tableView.frame.size.height - h
    }

    operationView.frame = frame
    operationView.items = items
    operationView.isHidden = false
  }

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

  // MARK: - objc 方法

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

    if operationView.isHidden == false {
      removeOperationView()
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

  // MARK: - private 方法

  func loadData() {
    weak var weakSelf = self

    // 多端登录清空未读数
    viewModel.clearUnreadCount()

    isLoadingData = true
    viewModel.loadData { error, historyEnd, newEnd, index in
      NEALog.infoLog(
        ModuleName + " " + ChatViewController.className(),
        desc: #function + "CALLBACK loadData " + (error?.localizedDescription ?? "no error")
      )

      weakSelf?.isLoadingData = false
      if let ms = weakSelf?.viewModel.messages, ms.count > 0 {
        weakSelf?.tableViewReload()
        if weakSelf?.viewModel.isHistoryChat == true,
           let num = weakSelf?.tableView.numberOfRows(inSection: 0),
           index < num, index >= 0 {
          let indexPath = IndexPath(row: index, section: 0)
          weakSelf?.tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
          weakSelf?.anchorCell = weakSelf?.tableView.cellForRow(at: indexPath) as? NEBaseChatMessageCell
          weakSelf?.anchorModel = weakSelf?.viewModel.messages[index] as? MessageVideoModel
          if newEnd > 0 {
            weakSelf?.addBottomLoadMore()
          }
        } else {
          weakSelf?.removeBottomLoadMore()
          if let last = weakSelf?.tableView.numberOfRows(inSection: 0) {
            let indexPath = IndexPath(row: last - 1, section: 0)
            weakSelf?.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
          }
          weakSelf?.removeBottomLoadMore()
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

    NotificationCenter.default.addObserver(self, selector: #selector(didTapHeader), name: NENotificationName.didTapHeader, object: nil)

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
    footer.triggerAutomaticallyRefreshPercent = -20
    tableView.mj_footer = footer
  }

  open func removeBottomLoadMore() {
    tableView.mj_footer?.endRefreshingWithNoMoreData()
    tableView.mj_footer = nil
    viewModel.isHistoryChat = false // 转为普通聊天页面
  }

  func markNeedReadMsg() {
    if isCurrentPage, needMarkReadMsgs.count > 0 {
      viewModel.markRead(messages: needMarkReadMsgs) { [weak self] error in
        NEALog.infoLog(
          ModuleName + " " + ChatViewController.className(),
          desc: #function + "CALLBACK markRead " + (error?.localizedDescription ?? "no error")
        )

        self?.viewModel.clearUnreadCount()
        if error == nil {
          self?.needMarkReadMsgs = [V2NIMMessage]()
        }
      }
    }
  }

  func appEnterBackground() {
    isCurrentPage = false
  }

  func appEnterForegournd() {
    isCurrentPage = true
    markNeedReadMsg()
  }

  //    MARK: - 键盘通知相关操作

  open func keyBoardWillShow(_ notification: Notification) {
    if !chatInputView.textView.isFirstResponder,
       !chatInputView.titleField.isFirstResponder {
      return
    }

    removeOperationView()

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
    if !chatInputView.textView.isFirstResponder,
       !chatInputView.titleField.isFirstResponder {
      return
    }

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

    if viewModel.isHistoryChat {
      dataReload()
      return
    }

    let row = tableView.numberOfRows(inSection: 0)
    if row > 0, row == viewModel.messages.count {
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

  //    MARK: - ChatInputViewDelegate

  public func didTranslateResult(_ content: String) {
    translateLanguageView.setTranslateContent(content)
  }

  open func sendText(text: String?, attribute: NSAttributedString?) {
    if let title = chatInputView.titleField.text, title.trimmingCharacters(in: .whitespaces).isEmpty == false {
      // 换行消息
      NEALog.infoLog(className(), desc: #function + "换行消息: \(title)")
      var dataDic = [String: Any]()
      dataDic["title"] = title
      if let t = text?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty {
        dataDic["body"] = text
      }

      var attachDic = [String: Any]()
      attachDic["type"] = customRichTextType
      attachDic["data"] = dataDic

      let rawAttachment = getJSONStringFromDictionary(attachDic)
      let customMessage = MessageUtils.customMessage(text: text ?? "", rawAttachment: rawAttachment)
      if let remoteExt = chatInputView.getAtRemoteExtension(attribute) {
        customMessage.serverExtension = getJSONStringFromDictionary(remoteExt)
      }
      var firstAIUserAccid = chatInputView.nickAccidList.first(where: { NEAIUserManager.shared.isAIUser($0) })
      if NEAIUserManager.shared.isAIUser(viewModel.sessionId) {
        firstAIUserAccid = viewModel.sessionId
      }
      chatInputView.clearAtCache()
      translateLanguageView.changeToIdleState(true)
      if viewModel.isReplying, let msg = viewModel.operationModel?.message {
        viewModel.replyMessageWithoutThread(message: customMessage,
                                            replyMessage: msg,
                                            aiUserAccid: firstAIUserAccid) { [weak self] message, error in
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
        viewModel.sendRichTextMessage(message: customMessage,
                                      title: title,
                                      body: text,
                                      aiUserAccid: firstAIUserAccid) { [weak self] message, error in
          NEALog.infoLog(
            ModuleName + " " + ChatViewController.className(),
            desc: #function + "CALLBACK sendRichTextMessage " + (error?.localizedDescription ?? "no error")
          )

          if error != nil {
            self?.showErrorToast(error)
          }

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
    translateLanguageView.changeToIdleState(true)
    let remoteExt = chatInputView.getAtRemoteExtension(attribute)
    var firstAIUserAccid = chatInputView.nickAccidList.first(where: { NEAIUserManager.shared.isAIUser($0) })
    if NEAIUserManager.shared.isAIUser(viewModel.sessionId) {
      firstAIUserAccid = viewModel.sessionId
    }
    chatInputView.clearAtCache()

    if viewModel.isReplying, let msg = viewModel.operationModel?.message {
      viewModel.replyMessageWithoutThread(message: MessageUtils.textMessage(text: content, remoteExt: remoteExt),
                                          replyMessage: msg,
                                          aiUserAccid: firstAIUserAccid) { [weak self] message, error in
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
      viewModel.sendTextMessage(text: content,
                                remoteExt: remoteExt,
                                aiUserAccid: firstAIUserAccid) { [weak self] message, error in
        NEALog.infoLog(
          ModuleName + " " + ChatViewController.className(),
          desc: #function + "CALLBACK sendTextMessage " + (error?.localizedDescription ?? "no error")
        )

        if error != nil {
          self?.showErrorToast(error)
        }

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
    } else if cell.cellData?.type == .translate {
      showTranslateView()
    } else if cell.cellData?.type == .photo {
      openPhoto()
    }
  }

  open func openPhoto() {}

  open func showTakePicture() {
    showBottomVideoAction(self, false)
  }

  open func showFileAction() {
    showBottomFileAction(self)
  }

  open func showRtcCallAction() {
    let videoCallAction = UIAlertAction(title: chatLocalizable("video_call"), style: .default) { [weak self] _ in
      self?.useToCallViewRouter(2)
    }

    let audioCallAction = UIAlertAction(title: chatLocalizable("audio_call"), style: .default) { [weak self] _ in
      self?.useToCallViewRouter(1)
    }

    let cancelAction = UIAlertAction(title: chatLocalizable("cancel"), style: .cancel) { _ in
    }

    showActionSheet([videoCallAction, audioCallAction, cancelAction])
  }

  /// 显示翻译UI
  open func showTranslateView() {
    if translateLanguageViewHeightAnchor?.constant == 0 {
      translateLanguageViewHeightAnchor?.constant = 70
//          DispatchQueue.main.asyncAfter(deadline: .now() + 0.25,
//                                        execute: DispatchWorkItem(block: { [weak self] in
//                                          self?.scrollTableViewToBottom()
//                                        }))
    }
  }

  /// 跳转音视频呼叫页面
  /// - Parameter type: 呼叫类型，1 - 音频；2 - 视频
  func useToCallViewRouter(_ type: Int) {
    // 校验配置项
    if !IMKitConfigCenter.shared.enableOnlyFriendCall,
       !NEFriendUserCache.shared.isFriend(viewModel.sessionId) {
      viewModel.insertTipMessage(chatLocalizable("disable_stranger_call"))
      return
    }

    var param = [String: Any]()
    param["remoteUserAccid"] = viewModel.sessionId
    param["currentUserAccid"] = IMKitClient.instance.account()
    param["remoteShowName"] = titleContent
    param["type"] = NSNumber(integerLiteral: type)

    if let user = ChatMessageHelper.getUserFromCache(viewModel.sessionId) {
      param["remoteAvatar"] = user.user?.avatar
    }

    Router.shared.use(CallViewRouter, parameters: param)
  }

  func didToSearchLocationView() {
    var params = [String: Any]()
    params["type"] = NEMapType.search.rawValue
    params["nav"] = navigationController
    Router.shared.use(NERouterUrl.LocationVCRouter, parameters: params)
  }

  open func textChanged(text: String) -> Bool {
    if text == "@" {
      // 校验配置项
      if !IMKitConfigCenter.shared.enableAtMessage {
        return true
      }

      // 做p2p类型判断
      if V2NIMConversationIdUtil.conversationType(viewModel.conversationId) == .CONVERSATION_TYPE_P2P {
        // 非数字人会话可以 @ 数字人
        if IMKitConfigCenter.shared.enableAIUser,
           !NEAIUserManager.shared.isAIUser(viewModel.sessionId) {
          DispatchQueue.main.async {
            self.showUserSelectVC(showTeamMembers: false)
          }
        }
      } else {
        DispatchQueue.main.async {
          self.showUserSelectVC(showTeamMembers: true)
        }
      }
      return true

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

  public func textViewDidChange() {
    translateLanguageView.changeToIdleState()
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
    removeOperationView()

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
          if self?.audioPlayer?.isPlaying == true {
            self?.audioPlayer?.stop()
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
        viewModel.sendVideoMessage(url: videoUrl,
                                   name: imageName,
                                   width: imageWidth,
                                   height: imageHeight,
                                   duration: videoDuration) { [weak self] message, error, progress in
          NEALog.infoLog(
            ModuleName + " " + ChatViewController.className(),
            desc: #function + "CALLBACK sendVideoMessage " + (error?.localizedDescription ?? "no error")
          )
          weakSelf?.showErrorToast(error)

          if progress > 0, progress <= 100 {
            self?.setModelProgress(message, progress)
          }
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
        if let data = pngImage, let path = NEPathUtils.getDirectoryForDocuments(dir: "\(imkitDir)image/") {
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
          viewModel.sendFileMessage(filePath: imageUrl.relativePath,
                                    displayName: imageName) { [weak self] message, error, progress in
            NEALog.infoLog(
              ModuleName + " " + ChatViewController.className(),
              desc: #function + "CALLBACK sendFileMessage" + (error?.localizedDescription ?? "no error")
            )
            self?.showErrorToast(error)

            if progress > 0, progress <= 100 {
              self?.setModelProgress(message, progress)
            }
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

  //    MARK: - UIImagePickerControllerDelegate

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

  //    MARK: - UIDocumentPickerDelegate

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
            viewModel.sendFileMessage(filePath: desPath,
                                      displayName: displayName) { [weak self] message, error, progress in
              NEALog.infoLog(
                ModuleName + " " + ChatViewController.className(),
                desc: #function + "CALLBACK sendFileMessage " + (error?.localizedDescription ?? "no error")
              )
              self?.showErrorToast(error)

              if progress > 0, progress <= 100 {
                self?.setModelProgress(message, progress)
              }
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

  // MARK: - UIDocumentInteractionControllerDelegate

  open func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
    self
  }

  open func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    controller.dismiss(animated: true)
  }

  //    MARK: - ChatviewModelDelegate

  /// 本端即将发送消息状态回调，此时消息还未发送，可对消息进行修改或者拦截发送
  /// 来源： 发送消息， 插入消息
  /// - Parameter message: 消息
  /// - Parameter completion: 是否继续发送消息
  public func readySendMessage(_ message: V2NIMMessage, _ completion: @escaping (Bool) -> Void) {
    if let block = NEKitChatConfig.shared.ui.onSendMessage {
      completion(block(message, self))
    } else {
      completion(true)
    }
  }

  /// 收到消息
  /// - Parameter messages: 消息列表
  open func onRecvMessages(_ messages: [V2NIMMessage], _ indexs: [IndexPath]) {
    removeOperationView()
    insertRows(indexs)

    // 如果当前页面是活跃状态，发送已读回执
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
  open func sending(_ message: V2NIMMessage, _ index: IndexPath) {
    insertRows([index])
  }

  /// 消息发送成功
  /// - Parameter message: 消息
  public func sendSuccess(_ message: V2NIMMessage, _ index: IndexPath) {
    tableViewReloadIndexs([index])

    // 提示【大模型请求响应中...】
    if message.aiConfig != nil, message.aiConfig?.aiStatus == .MESSAGE_AI_STATUS_AT {
      showToast(chatLocalizable("ai_request_ing"))
    }
  }

  public func onLoadMoreWithMessage(_ indexs: [IndexPath]) {
    tableViewReloadIndexs(indexs)
  }

  open func onDeleteMessage(_ messages: [V2NIMMessage], deleteIndexs: [IndexPath], reloadIndex: [IndexPath]) {
    if deleteIndexs.isEmpty {
      return
    }

    removeOperationView()
    tableViewReloadIndexs(reloadIndex) { [weak self] in
      for index in reloadIndex {
        if let numberOfRows = self?.tableView.numberOfRows(inSection: 0), index.row == numberOfRows - 1 {
          self?.scrollTableViewToBottom()
        }
      }
    }

    for message in messages {
      viewModel.messages.removeAll { $0.message?.messageClientId == message.messageClientId }

      // 刷新回复弹窗
      if message.messageClientId == viewModel.operationModel?.message?.messageClientId {
        replyView.textLabel.attributedText = nil
        replyView.textLabel.text = chatLocalizable("message_not_found")
        replyView.layoutIfNeeded()
      }
    }
    tableViewDeleteIndexs(deleteIndexs)

    // 如果消息为空(加载的消息全部被删除)，则拉取更多数据
    if viewModel.messages.isEmpty {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: DispatchWorkItem(block: { [weak self] in
        self?.loadMoreData()
      }))
    }
  }

  open func onResendSuccess(_ fromIndex: IndexPath, _ toIndexPath: IndexPath) {
    tableView.moveRow(at: fromIndex, to: toIndexPath)
    tableView.reloadRows(at: [toIndexPath], with: .automatic)
    tableView.scrollToRow(at: toIndexPath, at: .bottom, animated: true)
  }

  open func onRevokeMessage(_ message: V2NIMMessage, atIndexs: [IndexPath]) {
    if atIndexs.isEmpty {
      return
    }
    viewModel.selectedMessages.removeAll(where: { $0.messageClientId == message.messageClientId })
    removeOperationView()
    NEALog.infoLog(className(), desc: "on revoke message at indexs \(atIndexs)")
    tableViewReloadIndexs(atIndexs) { [weak self] in
      for index in atIndexs {
        if let numberOfRows = self?.tableView.numberOfRows(inSection: 0), index.row == numberOfRows - 1 {
          self?.scrollTableViewToBottom()
        }
      }
    }

    // 刷新回复弹窗
    if message.messageClientId == viewModel.operationModel?.message?.messageClientId {
      replyView.textLabel.attributedText = nil
      replyView.textLabel.text = chatLocalizable("message_not_found")
      replyView.layoutIfNeeded()
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
    if isLoadingData {
      return
    }

    tableView.deleteData(indexs)
  }

  open func tableViewReloadIndexs(_ indexs: [IndexPath], _ completion: (() -> Void)? = nil) {
    if isLoadingData {
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

  open func dataReload() {
    if viewModel.isHistoryChat {
      viewModel.anchor = nil
      loadData()
    }
  }

  /// 设置置顶消息展示文案，如果传入nil则移除置顶视图
  /// - Parameter name: 置顶消息发送者昵称
  /// - Parameter content: 置顶消息内容文案
  /// - Parameter url: 置顶消息 图片缩略图/视频首帧 地址
  /// - Parameter isVideo: 置顶消息是否是视频消息
  /// - Parameter hideClose: 是否隐藏移除置顶按钮
  public func setTopValue(name: String?, content: String?, url: String?, isVideo: Bool, hideClose: Bool) {
    if let content = content {
      contentView.addSubview(topMessageView)
      NSLayoutConstraint.activate([
        topMessageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: chat_content_margin),
        topMessageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: chat_content_margin),
        topMessageView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -chat_content_margin),
        topMessageView.heightAnchor.constraint(equalToConstant: 40),
      ])
      topMessageView.setTopContent(name: name, content: content, url: url, isVideo: isVideo, hideClose: hideClose)
    } else {
      topMessageView.removeFromSuperview()
    }
  }

  /// 更新置顶消息中的发送者昵称
  /// - Parameter name: 发送者昵称
  public func updateTopName(name: String?) {
    topMessageView.updateTopName(name: name)
  }

  /// 多选消息数量发生改变
  /// - Parameter count: 选中的消息数量
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

  // MARK: - audio play

  func startPlaying(audioMessage: V2NIMMessage?, isSend: Bool) {
    guard let message = audioMessage, let audio = message.attachment as? V2NIMMessageAudioAttachment else {
      return
    }

    playingCell?.startAnimation(byRight: isSend)

    let path = audio.path ?? ChatMessageHelper.createFilePath(message)
    if FileManager.default.fileExists(atPath: path) {
      NEALog.infoLog(className(), desc: #function + " play path : " + path)

      // 创建一个URL对象，指向音频文件
      let audioURL = URL(fileURLWithPath: path)

      do {
        // 设置听筒/扬声器
        let cate: AVAudioSession.Category = viewModel.getHandSetEnable() ? AVAudioSession.Category.playAndRecord : AVAudioSession.Category.playback
        try AVAudioSession.sharedInstance().setCategory(cate, options: .duckOthers)
        try AVAudioSession.sharedInstance().setActive(true)

        // 检查URL是否有效并尝试加载音频
        audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
        audioPlayer?.delegate = self

        // 开始播放
        audioPlayer?.play()
      } catch {
        // 处理加载音频文件失败的情况
        playingCell?.stopAnimation(byRight: isSend)
        print("Error loading audio: \(error.localizedDescription)")
      }
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
      if audioPlayer?.isPlaying == true {
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
    if audioPlayer?.isPlaying == true {
      audioPlayer?.stop()
    }

    playingCell?.stopAnimation(byRight: playingModel?.message?.isSelf ?? true)
    playingModel?.isPlaying = false
  }

  //    MARK: - NIMMediaManagerDelegate

  //  record
  open func recordAudio(_ filePath: String?, didBeganWithError error: Error?) {
    print("[record] sdk Began error:\(error?.localizedDescription ?? "")")
    stopPlay()
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

  //    MARK: - Private Method

  private func recordDuration(filePath: String) -> Float64 {
    let avAsset = AVURLAsset(url: URL(fileURLWithPath: filePath))
    return CMTimeGetSeconds(avAsset.duration)
  }

  private func insertRows(_ indexs: [IndexPath]) {
    if !hasFirstLoadData {
      return
    }

    let oldRows = tableView.numberOfRows(inSection: 0)
    if oldRows == 0 {
      tableView.reloadData()
      return
    }
    if oldRows == viewModel.messages.count {
      tableView.reloadData()
      return
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
      let atString = NSAttributedString(string: addText, attributes: [NSAttributedString.Key.foregroundColor: UIColor.ne_normalTheme, NSAttributedString.Key.font: font])
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

        chatInputView.nickAccidList.append(accid.count > 0 ? accid : "ait_all")
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

      chatInputView.nickAccidList.append(accid.count > 0 ? accid : "ait_all")
      chatInputView.nickAccidDic[addText] = accid.count > 0 ? accid : "ait_all"

      chatInputView.textView.attributedText = mutaString
      chatInputView.textView.selectedRange = NSMakeRange(selectRange.location + addText.count + atRangeOffset, 0)
    }
  }

  /// 获取@列表视图控制器 - 基类
  func getUserSelectVC(showTeamMembers: Bool) -> NEBaseSelectUserViewController {
    NEBaseSelectUserViewController(conversationId: viewModel.conversationId, showSelf: false, showTeamMembers: showTeamMembers)
  }

  private func showUserSelectVC(showTeamMembers: Bool) {
    let selectVC = getUserSelectVC(showTeamMembers: showTeamMembers)
    selectVC.modalPresentationStyle = .formSheet
    selectVC.selectedBlock = { [weak self] index, model in
      var addText = ""
      var accid = ""

      if model == nil, showTeamMembers {
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

  //    MARK: - MessageOperationViewDelegate

  open func didSelectedItem(item: OperationItem) {
    removeOperationView()

    // 配置项拦截
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
    case .top:
      topMessage()
    case .untop:
      untopMessage()
    case .collection:
      toCollectMessage()
    default:
      if let onClick = item.onClick {
        onClick(self)
      }

      customOperation()
    }
  }

  open func customOperation() {}

  open func copyMessage() {
    if let model = viewModel.operationModel as? MessageTextModel {
      // 划词
      if let text = model.selectText() {
        UIPasteboard.general.string = text
        showToast(commonLocalizable("copy_success"))
        return
      }

      if let text = model.message?.text, !text.isEmpty {
        UIPasteboard.general.string = text
        showToast(commonLocalizable("copy_success"))
      } else if let body = model.attributeStr?.string, !body.isEmpty {
        UIPasteboard.general.string = body
        showToast(commonLocalizable("copy_success"))
      } else if let model = viewModel.operationModel as? MessageRichTextModel {
        if let title = model.titleAttributeStr?.string, !title.isEmpty {
          UIPasteboard.general.string = title
          showToast(commonLocalizable("copy_success"))
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
      if IMKitConfigCenter.shared.enableAIUser {
        NSLayoutConstraint.activate([
          replyView.leadingAnchor.constraint(equalTo: translateLanguageView.leadingAnchor),
          replyView.trailingAnchor.constraint(equalTo: translateLanguageView.trailingAnchor),
          replyView.bottomAnchor.constraint(equalTo: translateLanguageView.topAnchor),
          replyView.heightAnchor.constraint(equalToConstant: 36),
        ])
      } else {
        NSLayoutConstraint.activate([
          replyView.leadingAnchor.constraint(equalTo: chatInputView.leadingAnchor),
          replyView.trailingAnchor.constraint(equalTo: chatInputView.trailingAnchor),
          replyView.bottomAnchor.constraint(equalTo: chatInputView.topAnchor),
          replyView.heightAnchor.constraint(equalToConstant: 36),
        ])
      }
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
        if let uid = ChatMessageHelper.getSenderId(message) {
          var showName = NETeamUserManager.shared.getShowName(uid, false)
          if V2NIMConversationIdUtil.conversationType(viewModel.conversationId) != .CONVERSATION_TYPE_P2P,
             !IMKitClient.instance.isMe(uid) {
            addToAtUsers(addText: "@" + showName + "", isReply: true, accid: uid)
          }
          showName = NETeamUserManager.shared.getShowName(uid)
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

  /// 撤回消息
  open func recallMessage() {
    weak var weakSelf = self
    showAlert(message: chatLocalizable("message_revoke_confirm")) {
      // 校验网络
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        weakSelf?.showToast(commonLocalizable("network_error"))
        return
      }

      if let message = weakSelf?.viewModel.operationModel?.message {
        if weakSelf?.viewModel.operationModel?.type == .text {
          weakSelf?.viewModel.operationModel?.isReedit = true
        }

        if weakSelf?.viewModel.operationModel?.type == .custom,
           weakSelf?.viewModel.operationModel?.customType == customRichTextType {
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

  /// 获取转发确认弹窗
  open func getForwardAlertController() -> NEBaseForwardAlertViewController {
    NEBaseForwardAlertViewController()
  }

  /// 添加转发确认弹窗
  /// - Parameters:
  ///   - items: 转发对象
  ///   - type: 转发类型（合并转发/逐条转发/转发）
  ///   - sureBlock: 确认按钮点击回调
  func addForwardAlertController(items: [ForwardItem],
                                 type: String,
                                 _ sureBlock: ((String?) -> Void)? = nil) {
    let forwardAlert = getForwardAlertController()
    forwardAlert.setItems(items)
    forwardAlert.forwardType = type
    forwardAlert.sureBlock = sureBlock
    forwardAlert.sessionName = ChatMessageHelper.getSessionName(conversationId: viewModel.conversationId)

    addChild(forwardAlert)
    view.addSubview(forwardAlert.view)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: DispatchWorkItem(block: {
      UIApplication.shared.keyWindow?.endEditing(true)
    }))
  }

  /// 长按转发消息
  open func forwardMessage() {
    if let message = viewModel.operationModel?.message {
      viewModel.selectedMessages = [message]
      didClickSingleForwardButton()
    }
  }

  /// 标记消息
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

  /// 取消标记消息
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

  /// 置顶消息
  open func topMessage() {
    // 校验网络
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    viewModel.topMessage { [weak self] error in
      NEALog.infoLog(
        ModuleName + " " + ChatViewController.className(),
        desc: #function + "CALLBACK topMessage " + (error?.localizedDescription ?? "no error")
      )
      if let err = error as? NSError {
        if err.code == protocolSendFailed {
          self?.view.makeToast(commonLocalizable("network_error"), position: .center)
        } else if err.code == noPermissionOperationCode {
          self?.view.makeToast(chatLocalizable("no_permission_tip"), position: .center)
        } else {
          self?.view.makeToast(error?.localizedDescription, position: .center)
        }
      }
    }
  }

  /// 收藏消息
  open func toCollectMessage() {
    // 校验网络
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    guard let operationModel = viewModel.operationModel else {
      return
    }

    viewModel.collectMessage(operationModel, title ?? "") { [weak self] error in
      if error != nil {
        if error?.code == collectionLimitCode {
          self?.showToast(chatLocalizable("collection_limit"))
        } else {
          self?.showToast(chatLocalizable("failed_operation"))
        }
      } else {
        self?.showToast(chatLocalizable("collection_success"))
      }
    }
  }

  /// 移除置顶消息
  open func untopMessage() {
    // 校验网络
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    viewModel.untopMessage { [weak self] error in
      NEALog.infoLog(
        ModuleName + " " + ChatViewController.className(),
        desc: #function + "CALLBACK untopMessage " + (error?.localizedDescription ?? "no error")
      )
      if let err = error as? NSError {
        if err.code == protocolSendFailed {
          self?.view.makeToast(commonLocalizable("network_error"), position: .center)
        } else if err.code == noPermissionOperationCode {
          self?.view.makeToast(chatLocalizable("no_permission_tip"), position: .center)
        } else if err.code == failedOperation {
          self?.view.makeToast(chatLocalizable("failed_operation"), position: .center)
        } else {
          self?.view.makeToast(error?.localizedDescription, position: .center)
        }
      }
    }
  }

  /// 多选消息
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

  /// 取消多选
  func cancelMutilSelect() {
    isMutilSelect = false
    viewModel.selectedMessages.removeAll()
    for model in viewModel.messages {
      model.isSelected = false
    }
    setMoreButton()
    setInputView(edit: true)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25,
                                  execute: DispatchWorkItem(block: { [weak self] in
                                    self?.scrollTableViewToBottom()
                                  }))
    tableView.reloadData()
  }

  /// 设置输入框样式
  /// - Parameter edit: 是否显示输入框
  func setInputView(edit: Bool) {
    chatInputView.isHidden = !edit
    mutilSelectBottomView.isHidden = edit
    bottomViewTopAnchor?.constant = edit ? -normalInputHeight : -100
  }

  // MARK: - UITableViewDataSource, UITableViewDelegate

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
      if model.customType == customRichTextType {
        reuseId = "\(MessageType.richText.rawValue)"
      } else {
        reuseId = "\(MessageType.reply.rawValue)"
      }
    } else {
      let key = "\(model.type.rawValue)"
      if model.type == .custom {
        if model.customType == customMultiForwardType {
          reuseId = "\(MessageType.multiForward.rawValue)"
        } else if model.customType == customRichTextType {
          reuseId = "\(MessageType.richText.rawValue)"
        } else if NEChatUIKitClient.instance.getRegisterCustomCell()["\(model.customType)"] != nil {
          reuseId = "\(model.customType)"
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

    var isSend = model.message?.isSelf ?? false
    // 数字人回复的消息
    if ChatMessageHelper.isAISender(model.message) {
      isSend = false
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
        if audioPlayer?.isPlaying == true {
          playingCell = audioCell
          m.isPlaying = true
        }
      }

      // 视频、文件下载状态
      if let m = model as? MessageVideoModel, m.message?.messageConfig == anchorModel?.message?.messageConfig {
        if anchorModel?.state == .Downalod {
          anchorCell = c
        }
      }

      if let m = model as? MessageContentModel {
        c.setModel(m, isSend)
        c.setSelect(m, isMutilSelect)
      }

      return c
    } else if let c = cell as? NEChatBaseCell, let m = model as? MessageContentModel {
      c.setModel(m, isSend)
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

    removeOperationView()
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
    if indexPath.row <= leaveCount, !isLoadingData, !uploadHasNoMore {
      // 上拉预加载更多
      if !isLoadingData {
        isLoadingData = true
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
              weakSelf?.isLoadingData = false
            }
          }
        }
      }
    }
  }

  // MARK: - UIScrollViewDelegate

  open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    removeOperationView(false)
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

  /// 获取文本详情页视图控制器
  func getTextViewController(title: String?, body: NSAttributedString?) -> TextViewController {
    let textViewController = TextViewController(title: title, body: body)
    textViewController.view.backgroundColor = .white
    return textViewController
  }

  // MARK: - OVERRIDE

  open func getMenuView() -> NEBaseChatInputView {
    NEBaseChatInputView()
  }

  open func setMutilSelectBottomView() {
    mutilSelectBottomView.backgroundColor = .ne_backgroundColor
  }

  /// 获取合并转发详情页视图控制器
  open func getMultiForwardViewController(_ messageAttachmentUrl: String?,
                                          _ messageAttachmentFilePath: String,
                                          _ messageAttachmentMD5: String?) -> MultiForwardViewController {
    MultiForwardViewController(messageAttachmentUrl, messageAttachmentFilePath, messageAttachmentMD5)
  }

  /// 输入框【更多】按钮点击事件，子类重写
  @discardableResult
  open func expandMoreAction() -> [NEMoreItemModel] {
    var items = NEChatUIKitClient.instance.getMoreActionData(sessionType: V2NIMConversationIdUtil.conversationType(viewModel.conversationId))
    if NEChatKitClient.instance.delegate == nil {
      items = items.filter { item in
        if item.type == .location {
          return false
        }
        return true
      }
    }

    if NEAIUserManager.shared.isAIUser(viewModel.sessionId) {
      items = items.filter { item in
        if item.type == .rtc {
          return false
        }
        return true
      }
    }

    if NEAIUserManager.shared.getAITranslateUser()?.accountId?.count ?? 0 <= 0 {
      items.removeAll { model in
        model.type == .translate
      }
    }

    return items
  }

  open func showTextViewController(_ model: MessageContentModel?) {
    guard let model = model as? MessageTextModel else { return }

    let title = NECustomUtils.titleOfRichText(model.message?.attachment)
    let body = model.attributeStr

    if !(title?.isEmpty == false), !(body?.string.isEmpty == false) {
      return
    }

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
    switch model?.type {
    case .audio:
      didTapAudioMessage(cell, model)
    case .image:
      didTapImageMessage(model, replyIndex)
    case .video:
      didTapVideoMessage(cell, model, replyIndex)
    case .file:
      didTapFileMessage(cell, model, replyIndex)
    case .location:
      didTapLocationMessage(model)
    case .rtcCallRecord:
      didTapCallMessage(model)
    case .custom:
      didTapCustomMessage(model, replyIndex)
    default:
      if (replyIndex ?? -1) > -1, model?.type == .text || model?.type == .reply {
        showTextViewController(model)
      } else {
        print(#function + "message did tap, type:\(String(describing: model?.type.rawValue))")
      }
    }
  }

  /// 单击语音消息
  /// - Parameters:
  ///   - cell: 消息所在单元格
  ///   - model: 消息模型
  ///   - replyIndex: 被回复消息的下标
  func didTapAudioMessage(_ cell: UITableViewCell?, _ model: MessageContentModel?) {
    guard let audioObject = model?.message?.attachment as? V2NIMMessageAudioAttachment else {
      return
    }

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
  }

  /// 单击图片消息
  /// - Parameters:
  ///   - model: 消息模型
  ///   - replyIndex: 被回复消息的下标
  func didTapImageMessage(_ model: MessageContentModel?, _ replyIndex: Int? = nil) {
    guard let imageObject = model?.message?.attachment as? V2NIMMessageImageAttachment else {
      return
    }

    var imageUrl = ""
    if let url = imageObject.url {
      imageUrl = url
    } else {
      if let path = imageObject.path, FileManager.default.fileExists(atPath: path) {
        imageUrl = path
      }
    }

    if !imageUrl.isEmpty {
      var showImages = ChatMessageHelper.getUrls(messages: viewModel.messages)

      // 如果回复的图片消息未加载，则置于所有加载的图片的最前面
      if !showImages.contains(imageUrl) {
        showImages.insert(imageUrl, at: 0)
      }

      let showController = PhotoBrowserController(urls: showImages, url: imageUrl)
      showController.modalPresentationStyle = .overFullScreen
      present(showController, animated: false, completion: nil)
    }
  }

  /// 单击视频消息
  /// - Parameters:
  ///   - cell: 消息所在单元格
  ///   - model: 消息模型
  ///   - replyIndex: 被回复消息的下标
  func didTapVideoMessage(_ cell: UITableViewCell?, _ model: MessageContentModel?, _ replyIndex: Int? = nil) {
    guard let object = model?.message?.attachment as? V2NIMMessageVideoAttachment else {
      return
    }

    let path = object.path ?? ChatMessageHelper.createFilePath(model?.message)
    if FileManager.default.fileExists(atPath: path) {
      // 停止播放语音
      stopPlay()

      // 设置听筒/扬声器
      let cate: AVAudioSession.Category = viewModel.getHandSetEnable() ? AVAudioSession.Category.playAndRecord : AVAudioSession.Category.playback
      try? AVAudioSession.sharedInstance().setCategory(cate, options: .duckOthers)

      let url = URL(fileURLWithPath: path)
      let videoPlayer = VideoPlayerViewController()
      videoPlayer.modalPresentationStyle = .overFullScreen
      videoPlayer.videoUrl = url
      videoPlayer.totalTime = Int(object.duration)
      present(videoPlayer, animated: true, completion: nil)
    } else {
      if let index = replyIndex {
        let indexPath = IndexPath(row: index, section: 0)
        if tableView.cellForRow(at: indexPath) != nil {
          // 消息已加载，直接跳转
          tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        } else {
          // 消息未加载，重新加载
          viewModel.anchor = model?.message
          loadData()
        }
      }

      downloadFile(cell, model, object.url, path)
    }
  }

  /// 单击文件消息
  /// - Parameters:
  ///   - cell: 消息所在单元格
  ///   - model: 消息模型
  ///   - replyIndex: 被回复消息的下标
  func didTapFileMessage(_ cell: UITableViewCell?, _ model: MessageContentModel?, _ replyIndex: Int? = nil) {
    guard let object = model?.message?.attachment as? V2NIMMessageFileAttachment else {
      return
    }

    let path = object.path ?? ChatMessageHelper.createFilePath(model?.message)
    if !FileManager.default.fileExists(atPath: path) {
      if let index = replyIndex {
        let indexPath = IndexPath(row: index, section: 0)
        if tableView.cellForRow(at: indexPath) != nil {
          // 消息已加载，直接跳转
          tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        } else {
          // 消息未加载，重新加载
          viewModel.anchor = model?.message
          loadData()
        }
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
  }

  /// 单击音视频消息
  /// - Parameter model: 消息模型
  func didTapCallMessage(_ model: MessageContentModel?) {
    guard let attachment = model?.message?.attachment as? V2NIMMessageCallAttachment else {
      return
    }

    useToCallViewRouter(attachment.type)
  }

  /// 单击地理位置消息
  /// - Parameters:
  ///   - model: 消息模型
  func didTapLocationMessage(_ model: MessageContentModel?) {
    if let locationModel = model as? MessageLocationModel,
       let lat = locationModel.lat,
       let lng = locationModel.lng {
      var params = [String: Any]()
      params["type"] = NEMapType.detail.rawValue
      params["nav"] = navigationController
      params["lat"] = lat
      params["lng"] = lng
      params["locationTitle"] = locationModel.title
      params["subTitle"] = locationModel.subTitle
      Router.shared.use(NERouterUrl.LocationVCRouter, parameters: params)
    }
  }

  /// 单击自定义消息
  /// - Parameters:
  ///   - cell: 消息所在单元格
  ///   - model: 消息模型
  ///   - replyIndex: 被回复消息的下标
  func didTapCustomMessage(_ model: MessageContentModel?, _ replyIndex: Int? = nil) {
    guard let customType = model?.customType else {
      return
    }

    if customType == customRichTextType {
      if replyIndex != nil {
        showTextViewController(model)
      }
    } else if customType == customMultiForwardType,
              let data = NECustomUtils.dataOfCustomMessage(model?.message?.attachment) {
      let url = data["url"] as? String
      let md5 = data["md5"] as? String
      guard let fileDirectory = NEPathUtils.getDirectoryForDocuments(dir: "\(imkitDir)file/") else { return }
      let fileName = multiForwardFileName + (model?.message?.messageClientId ?? "")
      let filePath = fileDirectory + fileName
      let multiForwardVC = getMultiForwardViewController(url, filePath, md5)
      navigationController?.pushViewController(multiForwardVC, animated: true)
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
    guard let urlString = url, var fileModel = model as? MessageVideoModel else {
      NEALog.infoLog(ModuleName + " " + className(), desc: #function + "MessageFileModel not exit")
      return
    }

    var fileCell = cell as? NEBaseChatMessageCell

    // 判断状态，如果是下载中不能进行预览
    if fileModel.state == .Downalod {
      NEALog.infoLog(ModuleName + " " + className(), desc: #function + "downLoad state, click ingore")
      return
    }

    var isSend = fileModel.message?.isSelf ?? false
    // 数字人回复的消息
    if ChatMessageHelper.isAISender(fileModel.message) {
      isSend = false
    }

    fileCell?.setModel(fileModel, isSend)

    viewModel.downLoad(urlString, path) { [weak self] progress in
      NEALog.infoLog(ModuleName + " " + ChatViewController.className(), desc: #function + "downLoad file progress: \(progress)")
      if cell == nil {
        fileCell = self?.anchorCell
        fileModel = self?.anchorModel ?? fileModel
      }

      fileModel.state = .Downalod
      fileModel.progress = progress
      fileCell?.uploadProgress(progress)

    } _: { [weak self] localPath, error in
      self?.showErrorToast(error)
      if localPath != nil {
        fileModel.state = .Success
      }
    }
  }

  /// 设置（视频、文件）消息模型（上传、下载）进度
  /// - Parameters:
  ///   - message: 消息
  ///   - progress:（上传、下载）进度
  func setModelProgress(_ message: V2NIMMessage?, _ progress: UInt) {
    for (i, model) in viewModel.messages.enumerated() {
      if model.message?.messageClientId == message?.messageClientId,
         let model = model as? MessageVideoModel {
        if let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as? NEBaseChatMessageCell {
          model.cell = cell
        }
        model.setModelProgress(progress)
      }
    }
  }

  /// 弹出语言选择
  open func showLanguageContentController(_ controller: NEBaseSelectLanguageViewController) {
    controller.modalPresentationStyle = .custom
    controller.transitioningDelegate = self
    controller.delegate = self
    present(controller, animated: true, completion: nil)
  }

  // MARK: - NEBaseTranslateLanguageView Delegate

  public func didUseTranslate(_ content: String) {
    chatInputView.textView.text = content
  }

  /// 开始翻译回调
  public func didStartClick() {
    if let contentString = chatInputView.getRealSendText(chatInputView.textView.attributedText) {
      viewModel.translateLanguage(contentString, targetLanguage: translateLanguageView.currentLanguage) { [weak self] error in
        if error != nil {
          if let code = error?.code {
            let content = ChatMessageHelper.getAIErrorMsage(code)
            if let content = content, !content.isEmpty {
              self?.showToast(content)
            } else if let errMsg = error?.localizedDescription {
              self?.showToast(errMsg)
            }
          }
          self?.translateLanguageView.changeToIdleState()
        }
      }
    }
  }

  public func didChangeViewHeight(_ translateView: NEAITranslateView, _ changeHeight: CGFloat) {
    translateLanguageViewHeightAnchor?.constant = changeHeight
  }

  public func didSwitchLanguageClick(_ currentLanguage: String?) {
    print("translateLanguageViewDidClickSwitchLanguage ", currentLanguage as Any)
  }

  public func didCloseClick(_ view: NEAITranslateView) {
    translateLanguageViewHeightAnchor?.constant = 0
  }

  // MARK: - Select Language Delegate

  public func didSelectLanguage(_ language: String?, _ controller: UIViewController?) {
    if let currentLanguage = language {
      translateLanguageView.currentLanguage = currentLanguage
    }
  }
}

// MARK: - TopMessageViewDelegate

extension ChatViewController: TopMessageViewDelegate {
  /// 点击置顶消息视图中的关闭按钮
  public func didClickCloseButton() {
    // 校验网络
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    viewModel.untopMessage { [weak self] error in
      if let err = error {
        self?.showErrorToast(err)
      } else {
        self?.topMessageView.removeFromSuperview()
      }
    }
  }

  /// 点击置顶消息视图
  public func didTapTopMessageView() {
    // 校验网络
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    var index = -1
    for (i, m) in viewModel.messages.enumerated() {
      if viewModel.topMessage?.messageClientId == m.message?.messageClientId {
        index = i
        break
      }
    }

    if index >= 0, index < tableView.numberOfRows(inSection: 0) {
      // 消息已加载，直接跳转
      tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
    } else {
      // 消息未加载，重新加载
      viewModel.anchor = viewModel.topMessage
      loadData()
    }
  }
}

extension ChatViewController: UIViewControllerTransitioningDelegate {
  public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
    CustomPresentationController(presentedViewController: presented, presenting: presenting)
  }
}

// MARK: - NEMutilSelectBottomViewDelegate

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
      if let data = NECustomUtils.dataOfCustomMessage(msg.attachment) {
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
          forwardMessages(isMultiForward: true, depth: depth)
        }
      }
    } else {
      if !viewModel.selectedMessages.isEmpty {
        forwardMessages(isMultiForward: true, depth: depth)
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
          forwardMessages()
        }
      }
    } else {
      if !viewModel.selectedMessages.isEmpty {
        forwardMessages()
      }
    }
  }

  /// 转发消息
  /// - Parameters:
  ///   - isMultiForward: 是否是合并转发
  ///   - depth: 合并转发层数
  open func forwardMessages(isMultiForward: Bool = false,
                            depth: Int = 0) {
    weak var weakSelf = self
    Router.shared.register(ForwardMultiSelectedRouter) { param in
      var items = [ForwardItem]()

      if let conversations = param["conversations"] as? [[String: Any]] {
        var conversationIds = [String]()

        for conversation in conversations {
          if let conversationId = conversation["conversationId"] as? String {
            conversationIds.append(conversationId)

            let item = ForwardItem()
            item.conversationId = conversationId
            item.name = conversation["name"] as? String
            item.avatar = conversation["avatar"] as? String
            items.append(item)
          }
        }

        let type = isMultiForward ? chatLocalizable("select_multi") :
          (weakSelf?.isMutilSelect == true ? chatLocalizable("select_per_item") : chatLocalizable("operation_forward"))
        weakSelf?.addForwardAlertController(items: items, type: type) { comment in
          if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
            weakSelf?.showToast(commonLocalizable("network_error"))
            return
          }

          weakSelf?.viewModel.forwardMessages(conversationIds, isMultiForward, depth, comment) { error in
            // 转发失败不展示错误信息
            weakSelf?.cancelMutilSelect()
          }
        }
      }
    }

    Router.shared.use(ForwardMultiSelectRouter,
                      parameters: ["nav": navigationController as Any, "selctorMode": 0],
                      closure: nil)
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

    if let m = model {
      if let senderId = ChatMessageHelper.getSenderId(m.message) {
        accid = senderId
        let name = NETeamUserManager.shared.getShowName(senderId, false)
        addText += name
        addText = "@" + addText + ""

        addToAtUsers(addText: addText, accid: accid, true)
      }
    }
  }

  /// 点击消息发送者头像
  /// 拉取最新用户信息后刷新消息发送者信息
  /// - Parameter noti: 通知对象
  func didTapHeader(_ noti: Notification) {
    if let user = noti.object as? NEUserWithFriend,
       let accid = user.user?.accountId {
      if NEFriendUserCache.shared.isFriend(accid) {
        NEFriendUserCache.shared.updateFriendInfo(user)
      } else if NETeamUserManager.shared.getUserInfo(accid) != nil {
        NETeamUserManager.shared.updateUserInfo(userWithFriend: user)
      } else if NEP2PChatUserCache.shared.getUserInfo(accid) != nil {
        NEP2PChatUserCache.shared.updateUserInfo(user)
      }

      onUserOrFriendInfoChanged(accid)
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
        ChatDeduplicationHelper.instance.removeBlackTipSendedId(messageId: msg.messageClientId)
        viewModel.sendMessage(message: msg) { _, error, pro in
          if let err = error {
            print("resend message error: \(err.localizedDescription)")
          }
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
        guard model?.customType == customRichTextType else {
          return
        }
      }
      let data = NECustomUtils.dataOfCustomMessage(model?.message?.attachment)

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
                    chatInputView.nickAccidList.append(key)
                    chatInputView.nickAccidDic[text] = key
                  }

                  if (attributeStr?.length ?? 0) > model.end {
                    attributeStr?.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.ne_normalTheme, range: NSMakeRange(model.start, model.end - model.start))
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

  /// 文本消息划词选中失去焦点
  /// - Parameters:
  ///   - cell: 所处位置的 cell
  ///   - model: 消息模型
  public func didTextViewLoseFocus(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    if viewModel.operationModel == model {
      removeOperationView()
    }
  }

  open func getReadView(_ message: V2NIMMessage, _ teamId: String) -> NEBaseReadViewController {
    ReadViewController(message: message, teamId: teamId)
  }

  open func loadDataFinish() {
    hasFirstLoadData = true
  }

  // MARK: - call kit noti

  open func didShowCallView() {
    stopPlay()
  }

  open func didDismissCallView() {}

  // MARK: - mutile line delegate

  open func expandButtonDidClick() {
    chatInputView.textView.resignFirstResponder()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25,
                                  execute: DispatchWorkItem(block: { [weak self] in
                                    self?.scrollTableViewToBottom()
                                  }))
    removeOperationView()
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

  /// 显示被离开群弹框
  open func showLeaveTeamAlert() {
    if IMKitConfigCenter.shared.enabledismissTeamDeleteConversation == false {
      return
    }
    showSingleAlert(message: chatLocalizable("team_has_been_quit")) { [weak self] in
      self?.navigationController?.popViewController(animated: true)
    }
  }

  /// 显示群被解散弹框
  open func showDismissTeamAlert() {
    if IMKitConfigCenter.shared.enabledismissTeamDeleteConversation == false {
      return
    }

    showSingleAlert(message: chatLocalizable("team_has_been_removed")) { [weak self] in
      self?.navigationController?.popViewController(animated: true)
    }
  }

  /// 移除弹框
  open func dismissAlert() {
    if let alert = navigationController?.presentedViewController,
       alert is UIAlertController {
      navigationController?.dismiss(animated: true)
    }
  }
}

// MARK: - AVAudioPlayerDelegate

extension ChatViewController: AVAudioPlayerDelegate {
  /// 声音播放完成回调
  public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    stopPlay()
  }

  /// 声音解码失败回调
  public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
    stopPlay()
  }
}

// MARK: - NEIMKitClientListener

extension ChatViewController: NEIMKitClientListener {
  /// 数据同步回调
  /// - Parameters:
  ///   - type: 同步的数据类型
  ///   - state: 同步状态
  ///   - error: 错误信息
  public func onDataSync(_ type: V2NIMDataSyncType, state: V2NIMDataSyncState, error: V2NIMError?) {
    if type == .DATA_SYNC_TYPE_MAIN, state == .DATA_SYNC_STATE_COMPLETED {
      getSessionInfo(sessionId: viewModel.sessionId) {
        print("getSessionInfo again")
      }
    }
  }

  /// 登录连接状态回调
  /// - Parameter status: 连接状态
  public func onConnectStatus(_ status: V2NIMConnectStatus) {
    if status == .CONNECT_STATUS_WAITING {
      networkBroken = true
      for model in viewModel.messages {
        model.isPined = false
      }
    }

    if status == .CONNECT_STATUS_CONNECTED, networkBroken {
      networkBroken = false
      DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: DispatchWorkItem(block: { [weak self] in
        // 断网重连后不会重发标记回调，需要手动拉取
        if let models = self?.viewModel.messages {
          let messages = models.compactMap(\.message)
          self?.viewModel.loadMoreWithMessage(messages)
        }
      }))
    }
  }
}
