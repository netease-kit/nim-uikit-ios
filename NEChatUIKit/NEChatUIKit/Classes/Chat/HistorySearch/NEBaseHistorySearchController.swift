
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import MJRefresh
import NEChatKit
import NECommonKit
import NIMSDK
import UIKit

/// 自定义 View：重写 hitTest，在触摸分发最早阶段就收起键盘
/// 确保 bubble tap gesture 能在 firstResponder 已 resign 的状态下正常识别，解决首次点击不跳转的问题
open class NEHistorySearchContainerView: UIView {
  weak var searchTextField: UITextField?

  override open func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    let hitView = super.hitTest(point, with: event)
    // 如果点击的不是 searchTextField 本身，提前 resign 收起键盘
    if let tf = searchTextField, tf.isFirstResponder, hitView !== tf {
      tf.resignFirstResponder()
    }
    return hitView
  }
}

@objcMembers
open class NEBaseHistorySearchController: NEChatBaseViewController, UITextFieldDelegate {
  var tag = "NEBaseHistoryMessageController"
  public var viewModel: TeamHistoryMessageViewModel
  public var conversationId: String?
  public var searchStr = ""
  /// 正在搜索标志，防止多次点击多次搜索
  public var isSearching = false
  var messageSearchExParams = V2NIMMessageSearchExParams()

  public var layout: UICollectionViewFlowLayout
  public var cellRegisterDic = [String: UITableViewCell.Type]()
  public var themeColor = UIColor.ne_normalTheme

  /// 快速搜索列表
  public var collectionView: UICollectionView

  lazy var tipLable: UILabel = {
    let lable = UILabel()
    lable.translatesAutoresizingMaskIntoConstraints = false
    lable.font = .systemFont(ofSize: 14)
    lable.textColor = .ne_emptyTitleColor
    lable.text = chatLocalizable("quick_search_tips")
    return lable
  }()

  /// 搜索文本框
  public lazy var searchTextField: SearchTextField = {
    let textField = SearchTextField()
    let leftImageView = UIImageView(image: coreLoader.loadImage("textField_search_icon"))
    textField.contentMode = .center
    textField.leftView = leftImageView
    textField.leftViewMode = .always
    textField.placeholder = chatLocalizable("search")
    textField.font = UIFont.systemFont(ofSize: 14)
    textField.textColor = UIColor.ne_greyText
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.layer.cornerRadius = 8
    textField.backgroundColor = UIColor(hexString: "0xF2F4F5")
    textField.clearButtonMode = .always
    textField.returnKeyType = .search
    textField.delegate = self
    textField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)

    if let clearButton = textField.value(forKey: "_clearButton") as? UIButton {
      clearButton.accessibilityIdentifier = "id.clear"
    }
    textField.accessibilityIdentifier = "id.search"
    return textField

  }()

  /// 历史消息列表
  public var tableViewTopAnchor: NSLayoutConstraint?
  public lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.scrollsToTop = false
    tableView.isHidden = true
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(
      NEBaseChatMessageCell.self,
      forCellReuseIdentifier: NEBaseChatMessageCell.className()
    )
    tableView.rowHeight = 65
    tableView.backgroundColor = .white
    tableView.sectionHeaderHeight = 30
    tableView.sectionFooterHeight = 0
    tableView.keyboardDismissMode = .onDrag

    tableView.mj_header = MJRefreshNormalHeader(
      refreshingTarget: self,
      refreshingAction: #selector(refreshData)
    )
    tableView.mj_header?.isAutomaticallyChangeAlpha = true

    tableView.mj_footer = MJRefreshAutoNormalFooter(
      refreshingTarget: self,
      refreshingAction: #selector(loadMoreData)
    )

    tableView.estimatedRowHeight = 0
    tableView.estimatedSectionHeaderHeight = 0
    tableView.estimatedSectionFooterHeight = 0

    // 防止键盘显示时，第一次点击被键盘收起事件消费，导致需要点击两次才能跳转
    tableView.delaysContentTouches = false
    tableView.canCancelContentTouches = true

    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }
    return tableView
  }()

  public init(conversationId: String) {
    self.conversationId = conversationId
    viewModel = TeamHistoryMessageViewModel(conversationId: conversationId)
    viewModel.themeColor = themeColor
    layout = UICollectionViewFlowLayout()
    layout.itemSize = CGSize(width: 84, height: 102)
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) {
    viewModel = TeamHistoryMessageViewModel()
    viewModel.themeColor = themeColor
    layout = UICollectionViewFlowLayout()
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    super.init(coder: coder)
  }

  override open func loadView() {
    // 使用自定义 View 替换默认 view，通过重写 hitTest 在触摸分发最早阶段收起键盘
    // 解决 bubble tap gesture 首次点击因键盘 resign 消费 touch 导致无法跳转的问题
    let containerView = NEHistorySearchContainerView()
    containerView.backgroundColor = .white
    view = containerView
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupSubviews()
    initialConfig()
    viewModel.delegate = self

    // 将 searchTextField 关联到自定义 containerView，使其能在 hitTest 中提前 resign
    if let containerView = view as? NEHistorySearchContainerView {
      containerView.searchTextField = searchTextField
    }
  }

  open func setupSubviews() {
    view.backgroundColor = .white
    navigationView.moreButton.isHidden = true
    view.addSubview(searchTextField)
    view.addSubview(tipLable)
    view.addSubview(collectionView)
    view.addSubview(tableView)
    view.addSubview(emptyView)

    NSLayoutConstraint.activate([
      tipLable.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
      tipLable.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 48),
    ])

    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    layout.scrollDirection = .vertical

    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.backgroundColor = .white
    collectionView.keyboardDismissMode = .onDrag

    collectionView.register(
      OperationCell.self,
      forCellWithReuseIdentifier: OperationCell.className()
    )

    NSLayoutConstraint.activate([
      collectionView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -26),
      collectionView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 26),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      collectionView.topAnchor.constraint(equalTo: tipLable.bottomAnchor, constant: 24),
    ])

    tableViewTopAnchor = tableView.topAnchor.constraint(equalTo: navigationView.bottomAnchor, constant: 50)
    tableViewTopAnchor?.isActive = true
    NSLayoutConstraint.activate([
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    tableView.register(
      NEBaseChatMessageCell.self,
      forCellReuseIdentifier: "\(NEBaseChatMessageCell.self)"
    )

    for (key, value) in cellRegisterDic {
      tableView.register(value, forCellReuseIdentifier: key)
    }

    emptyView.setText(chatLocalizable("no_search_results"))
    emptyView.backgroundColor = .white
    NSLayoutConstraint.activate([
      emptyView.rightAnchor.constraint(equalTo: collectionView.rightAnchor),
      emptyView.leftAnchor.constraint(equalTo: collectionView.leftAnchor),
      emptyView.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor),
      emptyView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor),
    ])
  }

  open func initialConfig() {
    title = chatLocalizable("historical_record")
  }

  open func refreshData() {
    loadData(nil, true)
  }

  open func loadMoreData() {
    loadData(nil, false)
  }

  open func loadData(_ params: V2NIMMessageSearchExParams? = nil, _ firstLoad: Bool = false) {
    if isSearching == true {
      return
    }

    isSearching = true
    let searchParams = params ?? messageSearchExParams
    searchParams.conversationId = conversationId

    if firstLoad, params != nil {
      view.neMakeToastActivity(.center)
    }

    viewModel.searchHistoryMessages(searchParams, firstLoad) { [weak self] error, messageCount, hasMore in
      self?.isSearching = false
      self?.tableView.mj_header?.endRefreshing()
      self?.tableView.mj_footer?.endRefreshing()

      if let err = error as? NSError {
        self?.view.neHideToastActivity()
        switch err.code {
        case protocolSendFailed:
          self?.showToast(commonLocalizable("network_error"))
        default:
          self?.showToast(err.localizedDescription)
          NEALog.errorLog(ModuleName + NEBaseHistorySearchController.className(), desc: "\(#function) failed, error: \(err.localizedDescription)")
        }
        return
      }

      if hasMore {
        self?.addBottomLoadMore()
      } else {
        self?.removeBottomLoadMore()
      }
      if firstLoad {
        self?.view.neHideToastActivity()
      }

      if searchParams.keywordList?.isEmpty == false {
        self?.searchTextField.isHidden = false
      } else {
        self?.searchTextField.isHidden = true
      }

      self?.emptyView.isHidden = self?.viewModel.messages.isEmpty == false
      self?.tableView.isHidden = self?.viewModel.messages.isEmpty == true
      self?.tableView.reloadData()
      if firstLoad {
        self?.tableView.contentOffset = .zero
      }
    }
  }

  open func addBottomLoadMore() {
    let footer = MJRefreshAutoNormalFooter(
      refreshingTarget: self,
      refreshingAction: #selector(loadMoreData)
    )
    footer.triggerAutomaticallyRefreshPercent = -20
    tableView.mj_footer = footer
  }

  open func removeBottomLoadMore() {
    tableView.mj_footer?.endRefreshingWithNoMoreData()
    tableView.mj_footer = nil

    let view = NERefreshHasNoMoreView(frame: CGRect(x: 0, y: 0, width: Int(tableView.bounds.width), height: 20))
    tableView.tableFooterView = view
  }

  /// 监听键盘搜索按钮点击
  open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
//      showToast(commonLocalizable("network_error"))
//      return false
//    }

    guard let searchText = searchTextField.text else {
      return true
    }

    if searchText.count <= 0 {
      viewModel.messages.removeAll()
      emptyView.isHidden = true
      tableView.isHidden = true
      tipLable.isHidden = false
      collectionView.isHidden = false
      collectionView.reloadData()
      return true
    }
    searchStr = searchText

    let params = V2NIMMessageSearchExParams()
    params.keywordList = [searchText]
    messageSearchExParams = params
    loadData(params, true)
    return true
  }

  /// 监听键盘内容变化
  open func searchTextChanged() {
    guard let _ = searchTextField.markedTextRange else {
      if searchTextField.text?.isEmpty == true {
        viewModel.messages.removeAll()
        emptyView.isHidden = true
        tableView.isHidden = true
        tipLable.isHidden = false
        collectionView.isHidden = false
        collectionView.reloadData()
      }
      return
    }
  }

  open func searchTeamMemberAction() {
    if let conversationId = conversationId,
       let teamId = V2NIMConversationIdUtil.conversationTargetId(conversationId) {
      let callback: NESelectTeamMemberBlock = { [weak self] datas in
        if let accountId = datas.first?.nimUser?.user?.accountId {
          self?.title = chatLocalizable("search_message_by_member")
          self?.tableViewTopAnchor?.constant = 0
          self?.tableView.isHidden = false

          let params = V2NIMMessageSearchExParams()
          params.senderAccountIds = [accountId]
          self?.messageSearchExParams = params
          self?.loadData(params, true)
        }
      }

      Router.shared.use(TeamMemberSelectViewRouter, parameters: ["nav": navigationController as Any,
                                                                 "teamId": teamId,
                                                                 "navTitle": chatLocalizable("group_memmber"),
                                                                 "memberLimit": 1,
                                                                 "showAllMembers": true,
                                                                 "selectMemberBlock": callback])
    }
  }

  open func searchImageAction() {
    let mediaSearchVC = NEBaseHistoryMediaResultController()
    navigationController?.pushViewController(mediaSearchVC, animated: true)
  }

  open func searchVideoAction() {
    let mediaSearchVC = NEBaseHistoryMediaResultController()
    mediaSearchVC.searchType = .video
    navigationController?.pushViewController(mediaSearchVC, animated: true)
  }

  open func searchDateAction() {
    let datePickerVC = NEHistoryDatePickerViewController()
    datePickerVC.delegate = self
    navigationController?.pushViewController(datePickerVC, animated: true)
  }

  open func searchFileAction() {
    let mediaSearchVC = NEBaseHistoryMediaResultController()
    mediaSearchVC.searchType = .file
    navigationController?.pushViewController(mediaSearchVC, animated: true)
  }

  func routerToMessage(_ message: V2NIMMessage?) {
    let conversationId = message?.conversationId ?? ChatRepo.conversationId
    let conversationType = V2NIMConversationIdUtil.conversationType(conversationId)

    // 合并 ChatVC 的新消息缓存（与标记列表跳转逻辑一致）
    // 因为搜索页和聊天页可能同时在监听消息，需要合并去重
    var newMsgs = [V2NIMMessage]()
    if let nav = navigationController {
      for vc in nav.viewControllers {
        if let chatVC = vc as? ChatViewController {
          // 保留 ChatVC 的所有新消息
          newMsgs = chatVC.onReceiveNewMsgs
          break
        }
      }
    }

    if conversationType == .CONVERSATION_TYPE_P2P {
      Router.shared.use(
        PushP2pChatVCRouter,
        parameters: ["nav": navigationController as Any,
                     "conversationId": conversationId as Any,
                     "anchor": message as Any,
                     "onReceiveNewMsgs": newMsgs,
                     "animated": false],
        closure: nil
      )
      // 跳转后清空 ChatVC 的缓存，避免重复计数
      if let nav = navigationController {
        for vc in nav.viewControllers {
          if let chatVC = vc as? ChatViewController {
            chatVC.onReceiveNewMsgs.removeAll()
            break
          }
        }
      }
    } else if conversationType == .CONVERSATION_TYPE_TEAM {
      Router.shared.use(
        PushTeamChatVCRouter,
        parameters: ["nav": navigationController as Any,
                     "conversationId": conversationId as Any,
                     "anchor": message as Any,
                     "onReceiveNewMsgs": newMsgs,
                     "animated": false],
        closure: nil
      )
      // 跳转后清空 ChatVC 的缓存，避免重复计数
      if let nav = navigationController {
        for vc in nav.viewControllers {
          if let chatVC = vc as? ChatViewController {
            chatVC.onReceiveNewMsgs.removeAll()
            break
          }
        }
      }
    }
  }
}

public extension NEBaseHistorySearchController {
  /// 在 bubble tap gesture 开始识别之前，主动 resign keyboard
  /// 解决键盘显示时首次点击 bubble 区域因 RTIInputSystemClient resign 异步导致 touch 中断的问题
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if searchTextField.isFirstResponder {
      searchTextField.resignFirstResponder()
    }
    return true
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    true
  }
}

extension NEBaseHistorySearchController: UICollectionViewDelegate, UICollectionViewDataSource {
  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    viewModel.operationTypes.count
  }

  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard indexPath.row < viewModel.operationTypes.count else {
      return UICollectionViewCell()
    }

    let model = viewModel.operationTypes[indexPath.row]
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OperationCell.className(), for: indexPath) as! OperationCell
    cell.model = model
    return cell
  }

  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if IMKitConfigCenter.shared.enableCloudMessageSearch {
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        showToast(commonLocalizable("network_error"))
        return
      }
    }

    let model = viewModel.operationTypes[indexPath.row]

    switch model.type {
    case .searchTeamMember:
      searchTeamMemberAction()
    case .searchImage:
      searchImageAction()
    case .searchVideo:
      searchVideoAction()
    case .searchDate:
      searchDateAction()
    case .searchFile:
      searchFileAction()
    default:
      break
    }
  }
}

extension NEBaseHistorySearchController: NEHistoryDatePickerViewControllerDelegate {
  func datePickerDidSelectDate(_ timestamp: Int64) {
    let opt = V2NIMMessageListOption()
    opt.conversationId = ChatRepo.conversationId
    opt.limit = 1
    opt.direction = .QUERY_DIRECTION_ASC
    opt.beginTime = TimeInterval(timestamp)

    // 查询后面的第一条消息
    ChatRepo.shared.getMessageList(option: opt) { [weak self] messages, erroe in
      if let firstMsg = messages?.first {
        self?.routerToMessage(firstMsg)
      } else {
        // 未查到则说明该时间之后没有消息
        self?.routerToMessage(nil)
      }
    }
  }
}

// MARK: UITableViewDelegate, UITableViewDataSource

extension NEBaseHistorySearchController: UITableViewDelegate, UITableViewDataSource {
  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.messages.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard indexPath.row < viewModel.messages.count else { return NEBaseChatMessageCell() }
    let model = viewModel.messages[indexPath.row]
    if !model.inMultiForward {
      model.inMultiForward = true
    }
    model.isPined = false
    var reuseId = ""
    let key = "\(model.type.rawValue)"
    if model.type == .custom {
      let customType = model.customType
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

    let cell = tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath)
    if let c = cell as? NEBaseChatMessageTipCell {
      if let m = model as? MessageTipsModel {
        c.setModel(m)
      }
      return c
    } else if let c = cell as? NEBaseChatMessageCell {
      if let m = model as? MessageContentModel {
        c.singleLeft = true
        c.setModel(m, false)
        c.setSelect(m, false)
        c.delegate = self
      }

      // 在搜索结果页，移除 bubble 上的 tap gesture（会因键盘 resign 被系统中断）
      // 改由 tableView(_:didSelectRowAt:) 统一处理点击跳转（已在 willSelectRowAt 中主动 resign keyboard）
      for gesture in (c.bubbleImageLeft.gestureRecognizers ?? []) + (c.bubbleImageRight.gestureRecognizers ?? []) {
        if gesture is UITapGestureRecognizer {
          gesture.isEnabled = false
        }
      }
      c.bubbleImageLeft.isUserInteractionEnabled = false
      c.bubbleImageRight.isUserInteractionEnabled = false

      return c
    } else if let c = cell as? NEChatBaseCell, let m = model as? MessageContentModel {
      c.setModel(m, false)
      return cell
    } else {
      return NEBaseChatMessageCell()
    }
  }

  open func tableView(_ tableView: UITableView,
                      heightForRowAt indexPath: IndexPath) -> CGFloat {
    guard indexPath.row < viewModel.messages.count else { return 0 }
    let model = viewModel.messages[indexPath.row]
    return model.cellHeight() - chat_content_margin
  }

  open func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    // 主动收起键盘，防止键盘收起事件消费第一次点击导致需要点击两次
    searchTextField.resignFirstResponder()
    return indexPath
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let cellModel = viewModel.messages[indexPath.row]
    if let message = cellModel.message {
      routerToMessage(message)
    }
  }
}

extension NEBaseHistorySearchController: ChatBaseCellDelegate {
  public func didTapAvatarView(_ cell: UITableViewCell, _ model: MessageContentModel?) {}

  public func didLongPressAvatar(_ cell: UITableViewCell, _ model: MessageContentModel?) {}

  public func didTapMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?, _ replyModel: (any NEChatKit.MessageModel)?) {
    guard let message = model?.message else { return }
    // 先收起键盘，再执行跳转
    searchTextField.resignFirstResponder()
    routerToMessage(message)
  }

  public func didLongPressMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?) {}

  public func didTapResendView(_ cell: UITableViewCell, _ model: MessageContentModel?) {}

  public func didTapReeditButton(_ cell: UITableViewCell, _ model: MessageContentModel?) {}

  public func didTapReadView(_ cell: UITableViewCell, _ model: MessageContentModel?) {}

  public func didTapSelectButton(_ cell: UITableViewCell, _ model: MessageContentModel?) {}
}

extension NEBaseHistorySearchController: ChatViewModelDelegate {
  public func sending(_ message: V2NIMMessage, _ index: IndexPath) {}

  public func sendSuccess(_ message: V2NIMMessage, _ index: IndexPath) {}

  public func onResendSuccess(_ fromIndex: IndexPath, _ toIndexPath: IndexPath) {}

  public func onRecvMessages(_ messages: [V2NIMMessage], _ indexs: [IndexPath]) {}

  public func onLoadMoreWithMessage(_ indexs: [IndexPath]) {}

  public func onModefiedMessage(_ index: IndexPath) {}

  public func onDeleteMessage(_ messages: [V2NIMMessage], deleteIndexs: [IndexPath], reloadIndex: [IndexPath]) {}

  public func onRevokeMessage(_ message: V2NIMMessage, atIndexs: [IndexPath]) {
    tableView.deleteData(atIndexs)
    emptyView.isHidden = !viewModel.messages.isEmpty
    tableView.isHidden = viewModel.messages.isEmpty
  }

  public func onMessageStatusChange(_ message: V2NIMMessage?, atIndexs: [IndexPath]) {}

  public func remoteUserEditing() {}

  public func remoteUserEndEditing() {}

  public func remoteUserOnlineChanged() {}

  public func tableViewReload() {
    tableView.reloadData()
  }

  public func setTopValue(name: String?, content: String?, url: String?, isVideo: Bool, hideClose: Bool) {}

  public func updateTopName(name: String?) {}
}
