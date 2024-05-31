//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import MJRefresh
import NEChatKit
import NIMSDK
import UIKit

@objc
open class NEBaseCollectionMessageController: NEChatBaseViewController, UITableViewDelegate, UITableViewDataSource, CollectionMessageCellDelegate, UIDocumentInteractionControllerDelegate {
  var audioPlayer: AVAudioPlayer? // 仅用于语音消息的播放

  /// 收藏列表
  public lazy var contentTable: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.showsVerticalScrollIndicator = false
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = .clear
//    tableView.mj_footer = MJRefreshBackNormalFooter(
//        refreshingTarget: self,
//        refreshingAction: #selector(loadMoreData)
//      )
    tableView.keyboardDismissMode = .onDrag
    return tableView
  }()

  /// 收藏列表空占位
  public lazy var collectionEmptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(
      imageName: "user_empty",
      content: chatLocalizable("no_collection_message"),
      frame: .zero
    )
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isUserInteractionEnabled = false
    view.isHidden = true
    return view
  }()

  let viewModel = CollectionMessageViewModel()

  /// 样式注册表
  var cellClassDic: [String: NEBaseCollectionMessageCell.Type] = [:]
  /// 收藏列表内容最大宽度
  public var collection_content_maxW = (kScreenWidth - 72)
  /// 正在播放的cell
  var playingCell: NEBaseCollectionMessageAudioCell?
  /// 正在播放数据模型
  var playingModel: MessageAudioModel?

  let interactionController = UIDocumentInteractionController()

  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    stopPlay()
  }

  override open func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    setupUI()
    loadMoreData()
  }

  /// 加载数据
  open func loadMoreData() {
    viewModel.loadData { [weak self] error, finished in
      if let err = error {
        self?.showToast(err.localizedDescription)
        self?.contentTable.mj_footer?.endRefreshing()
      } else {
        if self?.viewModel.collectionDatas.count ?? 0 <= 0 {
          self?.collectionEmptyView.isHidden = false
        }
        self?.contentTable.reloadData()
        if finished == false {
          self?.contentTable.mj_footer?.endRefreshing()
        } else {
          self?.contentTable.mj_footer?.endRefreshingWithNoMoreData()
          DispatchQueue.main.async {
            self?.contentTable.mj_footer = nil
          }
        }
      }
    }
  }

  /// 在子类中实现注册
  open func getRegisterDic() -> [String: NEBaseCollectionMessageCell.Type] {
    cellClassDic
  }

  /// UI初始化
  open func setupUI() {
    title = chatLocalizable("operation_collection")
    navigationView.navTitle.text = chatLocalizable("operation_collection")
    navigationView.moreButton.isHidden = true
    view.addSubview(contentTable)
    NSLayoutConstraint.activate([
      contentTable.topAnchor.constraint(equalTo: view.topAnchor, constant: NEConstant.navigationAndStatusHeight),
      contentTable.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentTable.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentTable.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    view.addSubview(collectionEmptyView)
    NSLayoutConstraint.activate([
      collectionEmptyView.topAnchor.constraint(equalTo: contentTable.topAnchor),
      collectionEmptyView.leftAnchor.constraint(equalTo: contentTable.leftAnchor),
      collectionEmptyView.rightAnchor.constraint(equalTo: contentTable.rightAnchor),
      collectionEmptyView.bottomAnchor.constraint(equalTo: contentTable.bottomAnchor),
    ])
    cellClassDic = getRegisterDic()
    contentTable.register(NEBaseCollectionMessageCell.self, forCellReuseIdentifier: "\(NEBaseCollectionMessageCell.self)")
    for (key, value) in cellClassDic {
      contentTable.register(value, forCellReuseIdentifier: "\(key)")
    }
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.collectionDatas.count
  }

  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.row >= viewModel.collectionDatas.count {
      return UITableViewCell()
    }

    let model = viewModel.collectionDatas[indexPath.row]
    var reuseId = "\(model.chatmodel.type.rawValue)"
    if model.chatmodel.type == .custom {
      let customType = model.chatmodel.customType
      if customType == customMultiForwardType {
        reuseId = "\(MessageType.multiForward.rawValue)"
      } else if customType == customRichTextType {
        reuseId = "\(MessageType.richText.rawValue)"
      } else {
        reuseId = "\(NEBaseCollectionMessageTextCell.self)"
      }
    } else if cellClassDic[reuseId] == nil {
      reuseId = "\(NEBaseCollectionMessageTextCell.self)"
    }
    let cell = tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath) as! NEBaseCollectionMessageCell
    cell.delegate = self
    cell.configureData(model)
    return cell
  }

  /// 列表行高
  /// - parameter tableView: 列表视图对象
  /// - parameter indexPath: 索引
  /// - returns: 行高
  open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.row >= viewModel.collectionDatas.count {
      return 0
    }

    let model = viewModel.collectionDatas[indexPath.row]
    if model.chatmodel.type == .custom {
      if model.chatmodel.customType == customMultiForwardType {
        return model.cellHeight(contenttMaxW: collection_content_maxW) - 30
      }
    }
    return model.cellHeight(contenttMaxW: collection_content_maxW)
  }

  /// 取消收藏消息
  /// - Parameter model: 收藏消息对象
  open func removeCollectionActionClicked(_ model: CollectionMessageModel) {
    weak var weakSelf = self
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      weakSelf?.showToast(commonLocalizable("network_error"))
      return
    }
    guard let collection = model.collection else {
      return
    }
    weakSelf?.viewModel.removeCollection(collection) { error in
      if error != nil {
        weakSelf?.showToast(chatLocalizable("failed_operation"))
      } else {
        weakSelf?.viewModel.collectionDatas.removeAll(where: { model in
          if model.collection?.collectionId == collection.collectionId {
            return true
          }
          return false
        })
        if weakSelf?.viewModel.collectionDatas.count ?? 0 <= 0 {
          weakSelf?.collectionEmptyView.isHidden = false
        }
        weakSelf?.contentTable.reloadData()
      }
    }
  }

  /// 拷贝文本消息
  /// - Parameter model: 收藏对象
  func copyCollectionActionClicked(_ model: CollectionMessageModel) {
    guard let text = model.message?.text else {
      return
    }

    let pasteboard = UIPasteboard.general
    pasteboard.string = text
    showToast(commonLocalizable("copy_success"))
  }

  /// 转发
  /// - Parameter message: 消息
  open func forwardCollectionMessage(_ message: V2NIMMessage, _ senderName: String) {
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
        weakSelf?.showForwardAlertController(items: items, type: type, conversationId: message.conversationId, senderName: senderName) { comment in
          if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
            weakSelf?.showToast(commonLocalizable("network_error"))
            return
          }

          weakSelf?.viewModel.forwardCollectionMessages(message, conversationIds, comment) { result, error, pro in
            // 转发失败不展示错误信息
          }
        }
      }
    }

    Router.shared.use(ForwardMultiSelectRouter,
                      parameters: ["nav": navigationController as Any, "selctorMode": 0],
                      closure: nil)
  }

  /// 显示转发确认弹窗
  /// - Parameters:
  ///   - items: 转发对象
  ///   - type: 转发类型（合并转发/逐条转发/转发）
  ///   - sureBlock: 确认按钮点击回调
  func showForwardAlertController(items: [ForwardItem],
                                  type: String,
                                  conversationId: String?,
                                  senderName: String?,
                                  _ sureBlock: ((String?) -> Void)? = nil) {
    let forwardAlert = getCollectionForwardAlertController()
    forwardAlert.setItems(items)
    forwardAlert.forwardType = type
    forwardAlert.sureBlock = sureBlock
    if let name = senderName {
      forwardAlert.senderName = name
    }

    addChild(forwardAlert)
    view.addSubview(forwardAlert.view)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: DispatchWorkItem(block: {
      UIApplication.shared.keyWindow?.endEditing(true)
    }))
  }

  /// 转发消息
  /// - Parameter model: 收藏对象
  func forwardCollectionActionClicked(_ model: CollectionMessageModel) {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }
    if let message = model.message {
      forwardCollectionMessage(message, model.senderName ?? "")
    }
  }

  /// 弹出底操作悬浮框
  /// - Parameter model: 收藏对象
  open func showActions(_ model: CollectionMessageModel) {
    guard let message = model.message else {
      return
    }
    var actions = [UIAlertAction]()
    weak var weakSelf = self
    let deleteCollectionAction = UIAlertAction(title: chatLocalizable("operation_delete_collection"), style: .default) { _ in
      weakSelf?.removeCollectionActionClicked(model)
    }
    actions.append(deleteCollectionAction)

    if message.messageType == .MESSAGE_TYPE_TEXT {
      let copyAction = UIAlertAction(title: chatLocalizable("operation_copy"), style: .default) { _ in
        weakSelf?.copyCollectionActionClicked(model)
      }
      actions.append(copyAction)
    }

    if message.messageType != .MESSAGE_TYPE_AUDIO {
      let forwardAction = UIAlertAction(title: chatLocalizable("operation_forward"), style: .default) { _ in
        weakSelf?.forwardCollectionActionClicked(model)
      }
      actions.append(forwardAction)
    }

    let cancelAction = UIAlertAction(title: chatLocalizable("cancel"), style: .cancel) { _ in }
    actions.append(cancelAction)

    showActionSheet(actions)
  }

  open func didClickMore(_ model: CollectionMessageModel?) {
    if let m = model {
      showActions(m)
    }
  }

  /// 跳转视图显示控件
  /// - Parameter model: 收藏对象
  open func showImageView(_ model: CollectionMessageModel?) {
    if let object = model?.message?.attachment as? V2NIMMessageImageAttachment {
      var imageUrlString = ""

      if let url = object.url {
        imageUrlString = url

      } else {
        if let path = object.path, FileManager.default.fileExists(atPath: path) {
          imageUrlString = path
        }
      }

      if imageUrlString.count > 0 {
        let showController = PhotoBrowserController(urls: [imageUrlString], url: imageUrlString)
        showController.modalPresentationStyle = .overFullScreen
        present(showController, animated: false, completion: nil)
      }
    }
  }

  /// 跳转视频播放器
  /// - Parameter model: 收藏对象
  public func showVideoView(_ model: CollectionMessageModel?) {
    if let object = model?.message?.attachment as? V2NIMMessageVideoAttachment {
      stopPlay()
      let player = VideoPlayerViewController()
      player.totalTime = Int(object.duration)
      player.modalPresentationStyle = .overFullScreen

      let path = object.path ?? ChatMessageHelper.createFilePath(model?.message)
      if FileManager.default.fileExists(atPath: path) == true {
        let url = URL(fileURLWithPath: path)
        player.videoUrl = url
        present(player, animated: true, completion: nil)
      } else if let url = object.url, let remoteUrl = URL(string: url) {
        player.videoUrl = remoteUrl
        present(player, animated: true, completion: nil)
      }
    }
  }

  /// 跳转地图详情页
  /// - Parameter model: 收藏对象
  public func showMapDetail(_ model: CollectionMessageModel?) {
    if let title = model?.message?.text, let locationObject = model?.message?.attachment as? V2NIMMessageLocationAttachment {
      let lng = locationObject.longitude

      let subTitle = locationObject.address

      let lat = locationObject.latitude

      var params = [String: Any]()
      // 路由参数
      params["nav"] = navigationController

      params["type"] = NEMapType.detail.rawValue

      params["locationTitle"] = title

      params["subTitle"] = subTitle

      params["lat"] = lat

      params["lng"] = lng

      // 调用路由
      Router.shared.use(NERouterUrl.LocationVCRouter, parameters: params)
    }
  }

  /// 跳转文件查看器
  /// - Parameter model: 收藏对象
  public func showFileDetail(_ model: CollectionMessageModel?) {
    if let object = model?.message?.attachment as? V2NIMMessageFileAttachment {
      // 判断是否是文件对象
      guard let fileModel = model?.fileModel as? CollectionFileModel else {
        NEALog.infoLog(ModuleName + " " + className(), desc: #function + "PinMessageFileModel not exit")
        return
      }
      // 判断状态，如果是下载中不能进行预览
      if fileModel.state == .Downalod {
        NEALog.infoLog(ModuleName + " " + className(), desc: #function + "downLoad state, click ingore")
        return
      }

      let path = object.path ?? ChatMessageHelper.createFilePath(model?.message)
      if !FileManager.default.fileExists(atPath: path) {
        // 本地文件不存在开始下载
        if let urlString = object.url {
          downloadFile(fileModel, urlString, path)
        }
      } else {
        // 有则直接加载
        let url = URL(fileURLWithPath: path)
        interactionController.url = url
        interactionController.delegate = self

        if interactionController.presentPreview(animated: true) {}
        else {
          interactionController.presentOptionsMenu(from: view.bounds, in: view, animated: true)
        }
      }
    }
  }

  /// 下载文件
  ///  - Parameter fileModel: 文件对象
  ///  - Parameter urlString: 下载地址
  ///  - Parameter path: 保存路径
  open func downloadFile(_ fileModel: CollectionFileModel, _ urlString: String, _ path: String) {
    fileModel.state = .Downalod

    // 开始下载
    viewModel.downloadFile(urlString, path) { [weak self] progress in

      NEALog.infoLog(ModuleName + " " + (self?.className() ?? ""), desc: #function + "downLoad file progress: \(progress)")

      // 根据进度设置状态
      fileModel.progress = progress

      // 更新ui进度
      fileModel.cell?.uploadProgress(progress)
    } _: { [weak self] localPath, error in
      if let err = error {
        switch err.code {
        case protocolSendFailed:
          self?.showToast(commonLocalizable("network_error"))
        default:
          print(err.localizedDescription)
        }
      } else if localPath != nil {
        fileModel.state = .Success
      }
    }
  }

  /// 跳转文本显示器
  /// - Parameter model: 收藏对象
  open func showTextView(_ model: CollectionMessageModel?) {
    guard let message = model?.message, let customType = model?.chatmodel.customType else {
      return
    }

    if customType == customRichTextType {
      showTextViewController(model)

    } else if customType == customMultiForwardType,
              let data = NECustomAttachment.dataOfCustomMessage(message.attachment) {
      let url = data["url"] as? String
      let md5 = data["md5"] as? String

      guard let fileDirectory = NEPathUtils.getDirectoryForDocuments(dir: imkitDir) else { return }
      let fileName = multiForwardFileName + (message.messageClientId ?? "")
      let filePath = fileDirectory + fileName
      let multiForwardVC = getMultiForwardViewController(url, filePath, md5)
      navigationController?.pushViewController(multiForwardVC, animated: true)
    }
  }

  /// 点击内容
  /// - Parameter model: 收藏对象
  /// - Parameter cell: 内容视图显示控件
  open func didClickContent(_ model: CollectionMessageModel?, _ cell: NEBaseCollectionMessageCell) {
    NEALog.infoLog(className(), desc: #function + "didClickContent")

    guard let message = model?.message else {
      return
    }

    if message.messageType == .MESSAGE_TYPE_AUDIO {
      didPlay(cell: cell, model: model)

    } else if message.messageType == .MESSAGE_TYPE_IMAGE {
      showImageView(model)

    } else if message.messageType == .MESSAGE_TYPE_VIDEO {
      showVideoView(model)

    } else if message.messageType == .MESSAGE_TYPE_TEXT {
      showTextViewController(model)

    } else if message.messageType == .MESSAGE_TYPE_LOCATION {
      showMapDetail(model)

    } else if message.messageType == .MESSAGE_TYPE_FILE {
      showFileDetail(model)

    } else if message.messageType == .MESSAGE_TYPE_CUSTOM {
      showTextView(model)
    }
  }

  /// 开始播放
  /// - Parameter cell: 收藏列表视图对象
  /// - Parameter model: 收藏对象
  private func didPlay(cell: NEBaseCollectionMessageCell?, model: CollectionMessageModel?) {
    guard let message = model?.message, let audio = message.attachment as? V2NIMMessageAudioAttachment else {
      return
    }

    let path = audio.path ?? ChatMessageHelper.createFilePath(message)
    if !FileManager.default.fileExists(atPath: path) {
      if let urlString = audio.url {
        viewModel.downloadFile(urlString, path, nil) { [weak self] _, error in
          if error == nil {
            NEALog.infoLog(ModuleName + " " + ChatViewController.className(), desc: #function + "CALLBACK downLoad")
            self?.startPlay(cell: cell, model: model)
          } else {
            self?.showToast(error!.localizedDescription)
          }
        }
      }
    } else {
      startPlay(cell: cell, model: model)
    }
  }

  func startPlay(cell: NEBaseCollectionMessageCell?, model: CollectionMessageModel?) {
    guard let audioModel = model?.chatmodel as? MessageAudioModel else {
      return
    }

    if playingModel == audioModel {
      if audioPlayer?.isPlaying == true {
        stopPlay()
      } else {
        startPlaying(audioMessage: model?.message)
      }
    } else {
      stopPlay()
      if let pCell = cell as? NEBaseCollectionMessageAudioCell {
        playingCell = pCell
      }
      if let audioModel = model?.chatmodel as? MessageAudioModel {
        playingModel = audioModel
      }
      startPlaying(audioMessage: model?.message)
    }
  }

  /// 开始播放
  /// - Parameter audioMessage: 音频消息对象
  func startPlaying(audioMessage: V2NIMMessage?) {
    guard let message = audioMessage, let audio = message.attachment as? V2NIMMessageAudioAttachment else {
      return
    }

    playingCell?.startPlayAnimation()

    let path = audio.path ?? ChatMessageHelper.createFilePath(message)
    if FileManager.default.fileExists(atPath: path) {
      NEALog.infoLog(className(), desc: #function + " play path : " + path)

      // 创建一个URL对象，指向音频文件
      let audioURL = URL(fileURLWithPath: path)

      do {
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
        playingCell?.stopPlayAnimation()
        print("Error loading audio: \(error.localizedDescription)")
      }
    } else {
      NEALog.infoLog(className(), desc: #function + " audio path is empty, play url : " + (audio.url ?? ""))
      playingCell?.stopPlayAnimation()
    }
  }

  func stopPlay() {
    if audioPlayer?.isPlaying == true {
      audioPlayer?.stop()
    }

    playingCell?.stopPlayAnimation()
    playingModel?.isPlaying = false

    do {
      // 将当前的音频会话设置为非活动状态
      try AVAudioSession.sharedInstance().setActive(false)
    } catch {
      // 处理设置失败的情况
      print("Error setActive: \(error.localizedDescription)")
    }
  }

  open func showTextViewController(_ model: CollectionMessageModel?) {
    guard let model = model?.chatmodel as? MessageTextModel else { return }

    let title = NECustomAttachment.titleOfRichText(model.message?.attachment)
    let body = model.attributeStr
    let textView = getTextViewController(title: title, body: body)
    textView.modalPresentationStyle = .fullScreen
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: DispatchWorkItem(block: { [weak self] in
      self?.navigationController?.present(textView, animated: false)
    }))
  }

  func getTextViewController(title: String?, body: NSAttributedString?) -> TextViewController {
    let textViewController = TextViewController(title: title, body: body)
    textViewController.view.backgroundColor = .white
    return textViewController
  }

  open func getMultiForwardViewController(_ messageAttachmentUrl: String?,
                                          _ messageAttachmentFilePath: String,
                                          _ messageAttachmentMD5: String?) -> MultiForwardViewController {
    MultiForwardViewController(messageAttachmentUrl, messageAttachmentFilePath, messageAttachmentMD5)
  }

  open func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
    self
  }

  open func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    controller.dismiss(animated: true)
  }

  open func getCollectionForwardAlertController() -> NEBaseForwardAlertViewController {
    NEBaseForwardAlertViewController()
  }
}

// MARK: - AVAudioPlayerDelegate

extension NEBaseCollectionMessageController: AVAudioPlayerDelegate {
  /// 声音播放完成回调
  public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    stopPlay()
  }

  /// 声音解码失败回调
  public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
    stopPlay()
  }
}
