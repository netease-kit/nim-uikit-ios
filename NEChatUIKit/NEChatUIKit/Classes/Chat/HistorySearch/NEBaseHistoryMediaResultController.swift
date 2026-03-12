
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import MJRefresh
import NEChatKit
import NIMSDK
import SDWebImage
import UIKit

@objcMembers
open class NEBaseHistoryMediaResultController: NEChatBaseViewController {
  public var collectionView: UICollectionView!
  public var tableView: UITableView!
  public var rowItemCount: CGFloat = 4
  public var viewModel = TeamHistoryMessageViewModel()
  public var searchType: MessageType = .image
  public var isLoadingMore = false

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    loadData()
    viewModel.delegate = self
  }

  open func setupUI() {
    view.backgroundColor = .white
    navigationView.moreButton.isHidden = true

    switch searchType {
    case .image:
      title = commonLocalizable("images")
      emptyView.setText(chatLocalizable("no_search_result_image"))
      setupCollectionView()
    case .video:
      title = commonLocalizable("videos")
      emptyView.setText(chatLocalizable("no_search_result_video"))
      setupCollectionView()
    default:
      title = chatLocalizable("chat_file")
      emptyView.setText(chatLocalizable("no_search_result_file"))
      setupTableView()
    }

    view.addSubview(emptyView)
    emptyView.backgroundColor = .white
    NSLayoutConstraint.activate([
      emptyView.rightAnchor.constraint(equalTo: view.rightAnchor),
      emptyView.leftAnchor.constraint(equalTo: view.leftAnchor),
      emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      emptyView.topAnchor.constraint(equalTo: navigationView.bottomAnchor),
    ])
  }

  public func setupTableView() {
    tableView = UITableView(frame: .zero, style: .grouped)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .white
    tableView.delegate = self
    tableView.dataSource = self
    tableView.separatorStyle = .none

    tableView.mj_header = MJRefreshNormalHeader(
      refreshingTarget: self,
      refreshingAction: #selector(refreshData)
    )
    tableView.mj_header?.isAutomaticallyChangeAlpha = true

    // 注册Cell
    tableView.register(NEHistorySearchFileCell.self,
                       forCellReuseIdentifier: NEHistorySearchFileCell.className())
    tableView.register(NEHistorySearchMediaTableSectionHeader.self,
                       forHeaderFooterViewReuseIdentifier: NEHistorySearchMediaTableSectionHeader.className())

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: navigationView.bottomAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  open func addTableViewFootter() {
    let footer = MJRefreshAutoNormalFooter(
      refreshingTarget: self,
      refreshingAction: #selector(loadMoreData)
    )
    footer.triggerAutomaticallyRefreshPercent = -20
    tableView.mj_footer = footer
  }

  open func removeTableViewBottomLoadMore() {
    tableView.mj_footer?.endRefreshingWithNoMoreData()
    tableView.mj_footer = nil

    if !viewModel.mediaMessageModels.isEmpty {
      let view = NERefreshHasNoMoreView(frame: CGRect(x: 0, y: 0, width: Int(tableView.bounds.width), height: 20))
      tableView.tableFooterView = view
    }
  }

  public func setupCollectionView() {
    let layout = UICollectionViewFlowLayout()
    layout.sectionInset = .zero
    layout.minimumInteritemSpacing = 2
    layout.minimumLineSpacing = 2

    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.backgroundColor = .systemBackground
    collectionView.delegate = self
    collectionView.dataSource = self
    let mjHeader = MJRefreshNormalHeader(refreshingTarget: self,
                                         refreshingAction: #selector(loadMoreData))
    mjHeader.setTitle(chatLocalizable("search_load_more_messages"), for: .idle)
    mjHeader.setTitle(chatLocalizable("search_load_immediately_upon_release"), for: .pulling)
    mjHeader.setTitle(chatLocalizable("search_loading_more_messages"), for: .refreshing)
    mjHeader.lastUpdatedTimeLabel?.isHidden = true
    mjHeader.ignoredScrollViewContentInsetTop = 0
    mjHeader.isAutomaticallyChangeAlpha = true
    collectionView.mj_header = mjHeader

    // 注册Cell和Header
    collectionView.register(NEHistorySearchMediaCollectionSectionHeader.self,
                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                            withReuseIdentifier: NEHistorySearchMediaCollectionSectionHeader.className())

    switch searchType {
    case .image:
      collectionView.register(NEHistorySearchImageCell.self, forCellWithReuseIdentifier: "\(searchType.rawValue)")
    case .video:
      collectionView.register(NEHistorySearchVideoCell.self, forCellWithReuseIdentifier: "\(searchType.rawValue)")
    default:
      collectionView.register(NEHistorySearchImageCell.self, forCellWithReuseIdentifier: "\(searchType.rawValue)")
      collectionView.register(NEHistorySearchVideoCell.self, forCellWithReuseIdentifier: "\(searchType.rawValue)")
    }

    view.addSubview(collectionView)

    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: navigationView.bottomAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  open func removeCollectionBottomLoadMore() {
    collectionView.mj_header?.endRefreshing()
    collectionView.mj_header = nil

    if !viewModel.mediaMessageModels.isEmpty {
      let headerView = NERefreshHasNoMoreView(frame: CGRect(x: 0, y: -20, width: Int(collectionView.bounds.width), height: 20))
      collectionView.addSubview(headerView)
      collectionView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
    }
  }

  public func loadData(_ firstLoad: Bool = true) {
    if isLoadingMore {
      return
    }
    isLoadingMore = true

    let lastSection = viewModel.mediaMessageModels.count - 1
    var lastItem = 0
    if lastSection >= 0 {
      lastItem = viewModel.mediaMessageModels[0].messageModels.count - 1
    }

    viewModel.searchHistryMediaMessages(firstLoad, searchType) { [weak self] error, messageCount, hasMore in
      guard let self = self else { return }
      self.isLoadingMore = false
      self.tableView?.mj_header?.endRefreshing()
      self.tableView?.mj_footer?.endRefreshing()
      self.collectionView?.mj_header?.endRefreshing()

      if let err = error as? NSError {
        switch err.code {
        case protocolSendFailed:
          self.showToast(commonLocalizable("network_error"))
        default:
          self.showToast(err.localizedDescription)
          NEALog.errorLog(ModuleName + NEBaseHistorySearchController.className(), desc: "\(#function) failed, error: \(err.localizedDescription)")
        }
        return
      }

      if searchType == .file {
        if !hasMore {
          self.removeTableViewBottomLoadMore()
        } else {
          self.addTableViewFootter()
        }
        self.tableView?.reloadData()
      } else {
        if !hasMore {
          self.removeCollectionBottomLoadMore()
        }
        self.collectionView.reloadData()
      }

      self.emptyView.isHidden = !self.viewModel.mediaMessageModels.isEmpty

      // 首次加载完成后滚动到底部
      if searchType != .file,
         !self.viewModel.mediaMessageModels.isEmpty {
        if firstLoad {
          DispatchQueue.main.async {
            self.scrollToLastItem(animated: false)
          }
        } else {
          let sectionCount = viewModel.mediaMessageModels.count - 1
          let item = viewModel.mediaMessageModels[sectionCount - lastSection].messageModels.count - 1 - lastItem
          self.collectionView.scrollToItem(at: IndexPath(item: item, section: sectionCount - lastSection), at: .bottom, animated: false)
        }
      }
    }
  }

  open func refreshData() {
    loadData(true)
  }

  open func loadMoreData() {
    loadData(false)
  }

  public func scrollToLastItem(animated: Bool = false) {
    guard !viewModel.mediaMessageModels.isEmpty else { return }

    let lastSection = viewModel.mediaMessageModels.count - 1
    let lastItem = viewModel.mediaMessageModels[lastSection].messageModels.count - 1

    if searchType == .file {
      let indexPath = IndexPath(row: lastItem, section: lastSection)
      tableView?.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    } else {
      let indexPath = IndexPath(item: lastItem, section: lastSection)
      guard collectionView.numberOfSections > lastSection,
            collectionView.numberOfItems(inSection: lastSection) > lastItem else {
        return
      }
      collectionView.scrollToItem(at: indexPath, at: .bottom, animated: animated)
    }
  }

  /// 转发消息
  /// - Parameters:
  ///   - message: 转发的消息
  open func forwardMessage(_ message: V2NIMMessage) {
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

        let type = chatLocalizable("operation_forward")
        weakSelf?.addForwardAlertController(items: items, type: type) { comment in
          if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
            weakSelf?.showToast(commonLocalizable("network_error"))
            return
          }

          weakSelf?.viewModel.forwardMessage([message], conversationIds, comment) { error in
            // 转发失败不展示错误信息
          }
        }
      }
    }

    Router.shared.use(ForwardMultiSelectRouter,
                      parameters: ["nav": navigationController as Any, "selctorMode": 0],
                      closure: nil)
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

    let content = ChatMessageHelper.getSessionName(conversationId: ChatRepo.conversationId)
    forwardAlert.sessionName = content

    addChild(forwardAlert)
    view.addSubview(forwardAlert.view)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: DispatchWorkItem(block: {
      UIApplication.shared.keyWindow?.endEditing(true)
    }))
  }

  /// 获取转发确认弹窗
  open func getForwardAlertController() -> NEBaseForwardAlertViewController {
    NEBaseForwardAlertViewController()
  }

  /// 收藏消息
  open func toCollectMessage(_ model: MessageContentModel) {
    // 校验网络
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    let titleContent = ChatMessageHelper.getSessionName(conversationId: ChatRepo.conversationId)
    viewModel.collectMessage(model, titleContent) { [weak self] error in
      if error != nil {
        if error?.code == collectionLimitCode {
          self?.showToast(chatLocalizable("collection_limit"))
        } else {
          self?.showToast(commonLocalizable("failed_operation"))
        }
      } else {
        self?.showToast(chatLocalizable("collection_success"))
      }
    }
  }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension NEBaseHistoryMediaResultController: UITableViewDataSource, UITableViewDelegate {
  public func numberOfSections(in tableView: UITableView) -> Int {
    viewModel.mediaMessageModels.count
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.mediaMessageModels[section].messageModels.count
  }

  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: NEHistorySearchFileCell.className(), for: indexPath) as! NEHistorySearchFileCell

    guard indexPath.section < viewModel.mediaMessageModels.count,
          indexPath.row < viewModel.mediaMessageModels[indexPath.section].messageModels.count else {
      return cell
    }

    let model = viewModel.mediaMessageModels[indexPath.section].messageModels[indexPath.row]
    if let fileModel = model as? MessageFileModel {
      cell.configure(with: fileModel)
      cell.delegate = self
    }

    return cell
  }

  public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard section < viewModel.mediaMessageModels.count else { return nil }

    let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: NEHistorySearchMediaTableSectionHeader.className()) as! NEHistorySearchMediaTableSectionHeader
    header.configure(with: viewModel.mediaMessageModels[section].time)
    return header
  }

  public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    124
  }

  public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    40
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)

    let model = viewModel.mediaMessageModels[indexPath.section].messageModels[indexPath.row]
    didTapFileMessage(model, indexPath)
  }

  open func didTapFileMessage(_ model: MessageImageModel, _ indexPath: IndexPath) {
    guard let message = model.message,
          let attachment = message.attachment as? V2NIMMessageFileAttachment else {
      return
    }

    let path = attachment.path ?? ChatMessageHelper.createFilePath(message)

    if FileManager.default.fileExists(atPath: path) {
      // 文件已下载，打开预览
      openFilePreview(filePath: path, fileName: attachment.name)
    } else {
      // 文件未下载，开始下载
      if tableView?.cellForRow(at: indexPath) is NEHistorySearchFileCell {
        downloadFile(model, attachment.url, path)
      }
    }
  }

  public func openFilePreview(filePath: String, fileName: String) {
    let url = URL(fileURLWithPath: filePath)
    let documentController = UIDocumentInteractionController(url: url)
    documentController.name = fileName
    documentController.delegate = self
    if documentController.presentPreview(animated: true) {}
    else {
      documentController.presentOptionsMenu(from: view.bounds, in: view, animated: true)
    }
  }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegate

extension NEBaseHistoryMediaResultController: UICollectionViewDataSource, UICollectionViewDelegate {
  public func numberOfSections(in collectionView: UICollectionView) -> Int {
    viewModel.mediaMessageModels.count
  }

  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    viewModel.mediaMessageModels[section].messageModels.count
  }

  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(searchType.rawValue)", for: indexPath) as! NEHistorySearchImageCell
    guard indexPath.section < viewModel.mediaMessageModels.count,
          indexPath.row < viewModel.mediaMessageModels[indexPath.section].messageModels.count else {
      return cell
    }

    let model = viewModel.mediaMessageModels[indexPath.section].messageModels[indexPath.row]
    cell.configure(with: model)

    // 添加长按手势
    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
    cell.addGestureRecognizer(longPressGesture)

    return cell
  }

  public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    if kind == UICollectionView.elementKindSectionHeader {
      let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NEHistorySearchMediaCollectionSectionHeader.className(), for: indexPath) as! NEHistorySearchMediaCollectionSectionHeader
      if indexPath.section < viewModel.mediaMessageModels.count {
        header.configure(with: viewModel.mediaMessageModels[indexPath.section].time)
      }
      return header
    }
    // 返回已注册的 header，避免崩溃
    return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NEHistorySearchMediaCollectionSectionHeader.className(), for: indexPath)
  }

  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let model = viewModel.mediaMessageModels[indexPath.section].messageModels[indexPath.item]

    // 添加点击动画
    guard let cell = collectionView.cellForItem(at: indexPath) else {
      return
    }
    UIView.animate(withDuration: 0.1, animations: {
      cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
    }) { _ in
      UIView.animate(withDuration: 0.1) {
        cell.transform = CGAffineTransform.identity
      }
    }

    switch searchType {
    case .image:
      didTapImageMessage(model, indexPath)
    case .video:
      didTapVideoMessage(model, indexPath)
    default:
      return
    }
  }

  open func didTapImageMessage(_ model: MessageImageModel, _ indexPath: IndexPath) {
    guard let message = model.message,
          let attachment = message.attachment as? V2NIMMessageFileAttachment,
          let url = attachment.url else { return }

    var showImages = [String]()
    var currentNumber = 0
    for (section, messageSection) in viewModel.mediaMessageModels.enumerated() {
      if section == indexPath.section {
        currentNumber += indexPath.item
      } else if section < indexPath.section {
        currentNumber += messageSection.messageModels.count
      }

      var (_, sectionImages) = ChatMessageHelper.getUrls(nil, messageSection.messageModels)
      showImages.append(contentsOf: sectionImages)
    }

    let showController = PhotoBrowserController(urls: showImages, url: url, currentNumber)
    showController.modalPresentationStyle = .overFullScreen
    present(showController, animated: false, completion: nil)
  }

  open func didTapVideoMessage(_ model: MessageImageModel,
                               _ indexPath: IndexPath) {
    guard let message = model.message,
          let object = message.attachment as? V2NIMMessageVideoAttachment else {
      return
    }

    let path = object.path ?? ChatMessageHelper.createFilePath(message)
    if FileManager.default.fileExists(atPath: path) {
      // 设置扬声器
      NEAudioSessionManager.shared.switchToSpeaker()
      NEAudioSessionManager.shared.stopProximityMonitoring()

      let url = URL(fileURLWithPath: path)
      let videoPlayer = VideoPlayerViewController()
      videoPlayer.modalPresentationStyle = .overFullScreen
      videoPlayer.videoUrl = url
      videoPlayer.totalTime = Int(object.duration)
      present(videoPlayer, animated: true, completion: nil)
    } else {
      downloadFile(model, object.url, path)
    }
  }

  /// 下载附件（文件、视频消息）
  /// - Parameters:
  ///   - cell: 当前单元格
  ///   - model: 消息模型
  ///   - url: 远端下载链接
  ///   - path: 本地保存路径
  open func downloadFile(_ model: MessageImageModel,
                         _ url: String?,
                         _ path: String) {
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

    viewModel.downLoad(urlString, path) { progress in
      NEALog.infoLog(ModuleName + " " + ChatViewController.className(), desc: #function + "downLoad file progress: \(progress)")

      fileModel.state = .Downalod
      fileModel.progress = progress
      fileModel.setModelProgress(progress)

    } _: { localPath, error in
      if localPath != nil {
        fileModel.state = .Success
      }
    }
  }

  @objc public func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
    guard gesture.state == .began else { return }

    let point = gesture.location(in: collectionView)
    if let indexPath = collectionView.indexPathForItem(at: point) {
      let model = viewModel.mediaMessageModels[indexPath.section].messageModels[indexPath.item]
      guard let message = model.message else { return }

      showAction(message)
    }
  }

  open func showAction(_ message: V2NIMMessage) {}

  open func routerToMessage(_ message: V2NIMMessage?) {
    let conversationId = message?.conversationId ?? ChatRepo.conversationId
    let conversationType = V2NIMConversationIdUtil.conversationType(conversationId)

    // 合并 ChatVC 的新消息缓存（与搜索记录跳转和标记列表跳转逻辑一致）
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

// MARK: - UICollectionViewDelegateFlowLayout

extension NEBaseHistoryMediaResultController: UICollectionViewDelegateFlowLayout {
  public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let padding: CGFloat = 2 * (rowItemCount - 1) // 3个间距
    let availableWidth = collectionView.frame.width - padding
    let itemWidth = availableWidth / rowItemCount // 每行4个
    return CGSize(width: itemWidth, height: itemWidth)
  }

  public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    CGSize(width: collectionView.frame.width, height: 40)
  }
}

// MARK: - UIDocumentInteractionControllerDelegate

extension NEBaseHistoryMediaResultController: UIDocumentInteractionControllerDelegate {
  open func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
    self
  }

  open func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    controller.dismiss(animated: true)
  }
}

extension NEBaseHistoryMediaResultController: NEHistorySearchFileCellDelegate {
  public func didClickMoreAction(_ cell: NEHistorySearchFileCell, _ model: MessageFileModel?) {}
}

extension NEBaseHistoryMediaResultController: ChatBaseCellDelegate {
  public func didTapAvatarView(_ cell: UITableViewCell, _ model: MessageContentModel?) {}

  public func didLongPressAvatar(_ cell: UITableViewCell, _ model: MessageContentModel?) {}

  public func didTapMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?, _ replyModel: (any NEChatKit.MessageModel)?) {}

  public func didLongPressMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?) {}

  public func didTapResendView(_ cell: UITableViewCell, _ model: MessageContentModel?) {}

  public func didTapReeditButton(_ cell: UITableViewCell, _ model: MessageContentModel?) {}

  public func didTapReadView(_ cell: UITableViewCell, _ model: MessageContentModel?) {}

  public func didTapSelectButton(_ cell: UITableViewCell, _ model: MessageContentModel?) {}
}

extension NEBaseHistoryMediaResultController: ChatViewModelDelegate {
  public func sending(_ message: V2NIMMessage, _ index: IndexPath) {}

  public func sendSuccess(_ message: V2NIMMessage, _ index: IndexPath) {}

  public func onResendSuccess(_ fromIndex: IndexPath, _ toIndexPath: IndexPath) {}

  public func onRecvMessages(_ messages: [V2NIMMessage], _ indexs: [IndexPath]) {}

  public func onLoadMoreWithMessage(_ indexs: [IndexPath]) {}

  public func onModefiedMessage(_ index: IndexPath) {}

  public func onDeleteMessage(_ messages: [V2NIMMessage], deleteIndexs: [IndexPath], reloadIndex: [IndexPath]) {}

  public func onRevokeMessage(_ message: V2NIMMessage, atIndexs: [IndexPath]) {
    if searchType == .file {
      for index in atIndexs {
        if viewModel.mediaMessageModels[index.section].messageModels.isEmpty {
          viewModel.mediaMessageModels.remove(at: index.section)
          tableView.deleteSections(IndexSet(integer: index.section), with: .automatic)
        } else {
          tableView.deleteData([IndexPath(item: index.item, section: index.section)])
        }
      }
      tableView.isHidden = viewModel.mediaMessageModels.isEmpty
    } else {
      for index in atIndexs {
        if viewModel.mediaMessageModels[index.section].messageModels.isEmpty {
          viewModel.mediaMessageModels.remove(at: index.section)
          collectionView.deleteSections(IndexSet(integer: index.section))
        } else {
          collectionView.deleteItems(at: [IndexPath(item: index.item, section: index.section)])
        }
      }
      collectionView.isHidden = viewModel.mediaMessageModels.isEmpty
    }

    emptyView.isHidden = !viewModel.mediaMessageModels.isEmpty
  }

  public func onMessageStatusChange(_ message: V2NIMMessage?, atIndexs: [IndexPath]) {}

  public func remoteUserEditing() {}

  public func remoteUserEndEditing() {}

  public func remoteUserOnlineChanged() {}

  public func tableViewReload() {}

  public func setTopValue(name: String?, content: String?, url: String?, isVideo: Bool, hideClose: Bool) {}

  public func updateTopName(name: String?) {}
}
