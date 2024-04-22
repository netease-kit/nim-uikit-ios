// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonUIKit
import NECoreIM2Kit
import NIMSDK
import UIKit

let PinMessageDefaultType = 1000

@objcMembers
open class NEBasePinMessageViewController: ChatBaseViewController, UITableViewDataSource, UITableViewDelegate, PinMessageViewModelDelegate, PinMessageCellDelegate, UIDocumentInteractionControllerDelegate, NIMMediaManagerDelegate, NEIMKitClientListener {
  let viewModel = PinMessageViewModel()

  /// 会话id
  var conversationId: String?
  /// 样式注册表
  var cellClassDic: [String: NEBasePinMessageCell.Type] = [:]
  /// pin 列表内容最大宽度
  public var pin_content_maxW = (kScreenWidth - 72)
  /// 正在播放的cell
  var playingCell: NEBasePinMessageAudioCell?
  var playingModel: MessageAudioModel?

  // 网络断开标志
  var networkBroken = false

  // 数据拉取标志
  var isLoadingData = false

  /// 初始化
  /// - Parameter conversationId: 会话id
  public init(conversationId: String) {
    self.conversationId = conversationId
    super.init(nibName: nil, bundle: nil)
    NIMSDK.shared().mediaManager.add(self)
    IMKitClient.instance.addLoginListener(self)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  deinit {
    NIMSDK.shared().mediaManager.remove(self)
    IMKitClient.instance.removeLoginListener(self)
  }

  private lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.showsVerticalScrollIndicator = false
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = .clear
    tableView.keyboardDismissMode = .onDrag
    return tableView
  }()

  public lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(
      imageName: "user_empty",
      content: chatLocalizable("no_pin_message"),
      frame: .zero
    )
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    return view
  }()

  let interactionController = UIDocumentInteractionController()

  override open func viewDidLoad() {
    super.viewDidLoad()

    viewModel.delegate = self
    setupUI()
    loadData()
  }

  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    stopPlay()
  }

  func loadData() {
    weak var weakSelf = self
    guard let cid = conversationId else {
      return
    }

    isLoadingData = true
    viewModel.getPinitems(conversationId: cid) { error in
      weakSelf?.isLoadingData = false
      if let err = error as? NSError {
        if V2NIMConversationIdUtil.conversationType(weakSelf?.conversationId ?? "") == .CONVERSATION_TYPE_TEAM, err.code == teamNotExistCode {
          weakSelf?.showToast(chatLocalizable("team_not_exist"))
        } else if err.code == protocolTimeout {
          weakSelf?.showToast(commonLocalizable("network_error"))
        } else {
          weakSelf?.showToast(err.localizedDescription)
        }
      } else {
        weakSelf?.emptyView.isHidden = (weakSelf?.viewModel.items.count ?? 0) > 0
        weakSelf?.tableView.reloadData()
      }
    }
  }

  /// UI 初始化
  func setupUI() {
    title = chatLocalizable("operation_pin")
    navigationView.navTitle.text = chatLocalizable("operation_pin")
    navigationView.moreButton.isHidden = true
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: NEConstant.navigationAndStatusHeight),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.topAnchor.constraint(equalTo: tableView.topAnchor),
      emptyView.leftAnchor.constraint(equalTo: tableView.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: tableView.rightAnchor),
      emptyView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
    ])
    cellClassDic = getRegisterCellDic()
    tableView.register(NEBasePinMessageTextCell.self, forCellReuseIdentifier: "\(NEBasePinMessageTextCell.self)")
    for (key, value) in cellClassDic {
      tableView.register(value, forCellReuseIdentifier: "\(key)")
    }
  }

  /// 列表点击回调
  /// - Parameter tableView: 列表视图对象
  /// - Parameter indexPath: 点击的索引
  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.row >= viewModel.items.count {
      return
    }

    let item = viewModel.items[indexPath.row]
    if item.message.conversationType == .CONVERSATION_TYPE_P2P {
      let conversationId = item.message.conversationId
      Router.shared.use(
        PushP2pChatVCRouter,
        parameters: ["nav": navigationController as Any,
                     "conversationId": conversationId as Any,
                     "anchor": item.message],
        closure: nil
      )
    } else if item.message.conversationType == .CONVERSATION_TYPE_TEAM {
      let conversationId = item.message.conversationId
      Router.shared.use(
        PushTeamChatVCRouter,
        parameters: ["nav": navigationController as Any,
                     "conversationId": conversationId as Any,
                     "anchor": item.message],
        closure: nil
      )
    }
  }

  /// 列表数据绑定
  /// - parameter tableView: 列表视图对象
  /// - parameter indexPath: 索引
  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.row >= viewModel.items.count {
      return UITableViewCell()
    }

    let model = viewModel.items[indexPath.row]
    var reuseId = "\(model.chatmodel.type.rawValue)"
    if model.chatmodel.type == .custom,
       let customType = NECustomAttachment.typeOfCustomMessage(model.chatmodel.message?.attachment) {
      if customType == customMultiForwardType {
        reuseId = "\(MessageType.multiForward.rawValue)"
      } else if customType == customRichTextType {
        reuseId = "\(MessageType.richText.rawValue)"
      } else {
        reuseId = "\(NEBasePinMessageTextCell.self)"
      }
    } else if cellClassDic[reuseId] == nil {
      reuseId = "\(NEBasePinMessageTextCell.self)"
    }
    let cell = tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath) as! NEBasePinMessageCell
    cell.delegate = self
    cell.configure(model)
    return cell
  }

  /// 列表行数
  /// - parameter tableView: 列表视图对象
  /// - parameter section: 索引
  /// - returns: 行数
  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.items.count
  }

  /// 列表行高
  /// - parameter tableView: 列表视图对象
  /// - parameter indexPath: 索引
  /// - returns: 行高
  open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.row >= viewModel.items.count {
      return 0
    }

    let model = viewModel.items[indexPath.row]
    if let customType = NECustomAttachment.typeOfCustomMessage(model.message.attachment) {
      if customType == customMultiForwardType {
        return model.cellHeight(pinContentMaxW: pin_content_maxW) - 30
      }
    }
    return model.cellHeight(pinContentMaxW: pin_content_maxW)
  }

  /// 取消pin消息
  /// - Parameter item: pin消息对象
  open func cancelPinActionClicked(item: NEPinMessageModel) {
    weak var weakSelf = self
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      weakSelf?.showToast(commonLocalizable("network_error"))
      return
    }
    weakSelf?.viewModel.removePinMessage(item.message) { error in
      if let err = error {
        print(err.localizedDescription)
      } else {
        weakSelf?.emptyView.isHidden = (weakSelf?.viewModel.items.count ?? 0) > 0
        weakSelf?.showToast(chatLocalizable("cancel_pin_success"))
      }
    }
  }

  /// 拷贝文本消息
  /// - Parameter item: pin消息对象
  func copyActionClicked(item: NEPinMessageModel) {
    weak var weakSelf = self
    let text = item.message.text
    let pasteboard = UIPasteboard.general
    pasteboard.string = text
    weakSelf?.view.makeToast(chatLocalizable("copy_success"), duration: 2, position: .center)
  }

  /// 转发消息
  /// - Parameter item: pin消息对象
  func forwardActionClicked(item: NEPinMessageModel) {
    weak var weakSelf = self
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      weakSelf?.showToast(commonLocalizable("network_error"))
      return
    }
    weakSelf?.forwardMessage(item.message)
  }

  /// 弹出底操作悬浮框
  /// - Parameter item: pin消息对象
  open func showAction(item: NEPinMessageModel) {
    var actions = [UIAlertAction]()
    weak var weakSelf = self
    let cancelPinAction = UIAlertAction(title: chatLocalizable("operation_cancel_pin"), style: .default) { _ in
      weakSelf?.cancelPinActionClicked(item: item)
    }
    actions.append(cancelPinAction)

    if item.message.messageType == .MESSAGE_TYPE_TEXT {
      let copyAction = UIAlertAction(title: chatLocalizable("operation_copy"), style: .default) { _ in
        weakSelf?.copyActionClicked(item: item)
      }
      actions.append(copyAction)
    }

    if item.message.messageType != .MESSAGE_TYPE_AUDIO {
      let forwardAction = UIAlertAction(title: chatLocalizable("operation_forward"), style: .default) { _ in
        weakSelf?.forwardActionClicked(item: item)
      }
      actions.append(forwardAction)
    }

    let cancelAction = UIAlertAction(title: chatLocalizable("cancel"), style: .cancel) { _ in }
    actions.append(cancelAction)

    showActionSheet(actions)
  }

  open func getForwardAlertController() -> NEBaseForwardAlertViewController {
    NEBaseForwardAlertViewController()
  }

  /// 转发消息到单聊
  /// - Parameter message： 转发消息体
  func forwardMessageToUser(_ message: V2NIMMessage) {
    weak var weakSelf = self
    Router.shared.register(ContactSelectedUsersRouter) { param in
      print("user setting accids : ", param)
      var items = [ForwardItem]()

      if let users = param["im_user"] as? [V2NIMUser] {
        for user in users {
          let item = ForwardItem()
          item.uid = user.accountId
          item.avatar = user.avatar
          item.name = user.name
          items.append(item)
        }

        let forwardAlert = weakSelf!.getForwardAlertController()
        forwardAlert.setItems(items)
        if let session = weakSelf?.viewModel.conversationId {
          let content = ChatMessageHelper.getSessionName(conversationId: session)
          forwardAlert.context = content
        }
        weakSelf?.addChild(forwardAlert)
        weakSelf?.view.addSubview(forwardAlert.view)

        forwardAlert.sureBlock = { comment in
          if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
            weakSelf?.showToast(commonLocalizable("network_error"))
            return
          }
          weakSelf?.viewModel.forwardUserMessage(message, users, comment) { result, error, progress in
            if let err = error as? NSError {
              if err.code == protocolSendFailed {
                weakSelf?.showToast(commonLocalizable("network_error"))
              } else {
                weakSelf?.showToast(err.localizedDescription)
              }
            }
          }
        }
      }
    }
    var param = [String: Any]()
    param["nav"] = weakSelf?.navigationController as Any
    param["limit"] = 6

    // 标记列表-转发-人员选择页面不包含自己
    var filters = Set<String>()
    filters.insert(IMKitClient.instance.account())
    param["filters"] = filters

    Router.shared.use(ContactUserSelectRouter, parameters: param, closure: nil)
  }

  /// 转发消息到群聊
  /// - Parameter message： 消息对象
  func forwardMessageToTeam(_ message: V2NIMMessage) {
    weak var weakSelf = self
    Router.shared.register(ContactTeamDataRouter) { param in
      if let team = param["team"] as? V2NIMTeam {
        let item = ForwardItem()
        item.avatar = team.avatar
        item.name = team.getShowName()
        item.uid = team.teamId

        let forwardAlert = weakSelf!.getForwardAlertController()
        forwardAlert.setItems([item])
        if let conversationId = weakSelf?.viewModel.conversationId {
          let content = ChatMessageHelper.getSessionName(conversationId: conversationId)
          forwardAlert.context = content
        }
        forwardAlert.sureBlock = { comment in
          if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
            weakSelf?.showToast(commonLocalizable("network_error"))
            return
          }
          weakSelf?.viewModel.forwardTeamMessage(message, team, comment) { result, error, progress in
            if let err = error as? NSError {
              if err.code == protocolSendFailed {
                weakSelf?.showToast(commonLocalizable("network_error"))
              } else {
                weakSelf?.showToast(err.localizedDescription)
              }
            }
          }
        }
        weakSelf?.addChild(forwardAlert)
        weakSelf?.view.addSubview(forwardAlert.view)
      }
    }

    Router.shared.use(
      ContactTeamListRouter,
      parameters: ["nav": weakSelf?.navigationController as Any,
                   "isClickCallBack": true],
      closure: nil
    )
  }

  open func forwardMessage(_ message: V2NIMMessage) {
    if IMKitClient.instance.getConfigCenter().teamEnable {
      weak var weakSelf = self
      let userAction = UIAlertAction(title: chatLocalizable("contact_user"),
                                     style: .default) { action in
        weakSelf?.forwardMessageToUser(message)
      }

      let teamAction = UIAlertAction(title: chatLocalizable("team"), style: .default) { action in
        weakSelf?.forwardMessageToTeam(message)
      }

      let cancelAction = UIAlertAction(title: chatLocalizable("cancel"),
                                       style: .cancel) { action in
      }

      showActionSheet([teamAction, userAction, cancelAction])
    } else {
      forwardMessageToUser(message)
    }
  }

  open func tableViewReload(needLoad: Bool) {
    if needLoad {
      loadData()
    }
    tableView.reloadData()
  }

  /// 刷新数据
  /// - Parameter model: 标记数据模型
  public func refreshModel(_ model: NEPinMessageModel) {
    var index = -1
    for (i, item) in viewModel.items.enumerated() {
      if item == model {
        viewModel.items[i] = model
        index = i
        break
      }
    }

    if index < 0 || index >= tableView.numberOfRows(inSection: 0) {
      return
    }
    tableViewReload([IndexPath(row: index, section: 0)])
  }

  public func tableViewReload(_ indexs: [IndexPath]) {
    tableView.reloadData(indexs)
  }

  public func tableViewDelete(_ indexs: [IndexPath]) {
    if isLoadingData {
      return
    }

    let indexs = indexs.filter { $0.row >= 0 && $0.row < viewModel.items.count }

    if !indexs.isEmpty {
      tableView.deleteData(indexs)
      emptyView.isHidden = viewModel.items.count > 0
    }
  }

  open func didClickMore(_ model: NEPinMessageModel?) {
    if let item = model {
      showAction(item: item)
    }
  }

  /// 跳转视图显示控件
  /// - Parameter model: 标记对象
  open func toImageView(_ model: NEPinMessageModel?) {
    if let object = model?.message.attachment as? V2NIMMessageImageAttachment {
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
  /// - Parameter model: 标记对象
  public func toVideoView(_ model: NEPinMessageModel?) {
    if let object = model?.message.attachment as? V2NIMMessageVideoAttachment {
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
  /// - Parameter model: 标记对象
  public func toMapDetail(_ model: NEPinMessageModel?) {
    if let title = model?.message.text, let locationObject = model?.message.attachment as? V2NIMMessageLocationAttachment {
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
  /// - Parameter model: 标记对象
  public func toFileDetail(_ model: NEPinMessageModel?) {
    if let object = model?.message.attachment as? V2NIMMessageFileAttachment {
      // 判断是否是文件对象
      guard let fileModel = model?.pinFileModel as? PinMessageFileModel else {
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
  open func downloadFile(_ fileModel: PinMessageFileModel, _ urlString: String, _ path: String) {
    fileModel.state = .Downalod

    // 开始下载
    viewModel.downLoad(urlString, path) { [weak self] progress in

      NEALog.infoLog(ModuleName + " " + (self?.className() ?? ""), desc: #function + "downLoad file progress: \(progress)")

      // 根据进度设置状态
      fileModel.progress = progress

      if progress >= 100 {
        fileModel.state = .Success
      }
      // 更新ui进度
      fileModel.cell?.uploadProgress(progress: progress)
    } _: { _, error in
      NEALog.infoLog(self.className(), desc: "download error \(error?.localizedDescription ?? "")")
    }
  }

  /// 跳转文本显示器
  /// - Parameter model: 标记对象
  open func toTextViewShow(_ model: NEPinMessageModel?) {
    if let customType = NECustomAttachment.typeOfCustomMessage(model?.message.attachment) {
      if customType == customRichTextType {
        showTextViewController(model)

      } else if customType == customMultiForwardType,
                let data = NECustomAttachment.dataOfCustomMessage(model?.message.attachment) {
        let url = data["url"] as? String
        let md5 = data["md5"] as? String

        guard var fileDirectory = NEPathUtils.getDirectoryForDocuments(dir: "NEIMUIKit/") else { return }
        let fileName = multiForwardFileName + (model?.message.messageClientId ?? "")
        let filePath = fileDirectory + fileName
        let multiForwardVC = getMultiForwardViewController(url, filePath, md5)
        navigationController?.pushViewController(multiForwardVC, animated: true)
      }
    }
  }

  /// 点击内容
  /// - Parameter model: 标记对象
  /// - Parameter cell: 内容视图显示控件
  open func didClickContent(_ model: NEPinMessageModel?, _ cell: NEBasePinMessageCell) {
    NEALog.infoLog(className(), desc: #function + "didClickContent")

    if model?.message.messageType == .MESSAGE_TYPE_AUDIO {
      startPlay(cell: cell, model: model)

    } else if model?.message.messageType == .MESSAGE_TYPE_IMAGE {
      toImageView(model)

    } else if model?.message.messageType == .MESSAGE_TYPE_VIDEO {
      toVideoView(model)

    } else if model?.message.messageType == .MESSAGE_TYPE_TEXT {
      showTextViewController(model)

    } else if model?.message.messageType == .MESSAGE_TYPE_LOCATION {
      toMapDetail(model)

    } else if model?.message.messageType == .MESSAGE_TYPE_FILE {
      toFileDetail(model)

    } else if model?.message.messageType == .MESSAGE_TYPE_CUSTOM {
      toTextViewShow(model)
    }
  }

  /// 开始播放
  /// - Parameter cell: 标记列表视图对象
  /// - Parameter model: 标记对象
  private func startPlay(cell: NEBasePinMessageCell?, model: NEPinMessageModel?) {
    guard let audioModel = model?.chatmodel as? MessageAudioModel else {
      return
    }

    if playingModel == audioModel {
      if NIMSDK.shared().mediaManager.isPlaying() {
        stopPlay()
      } else {
        startPlaying(audioMessage: model?.message)
      }
    } else {
      stopPlay()
      if let pCell = cell as? NEBasePinMessageAudioCell {
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
    playingCell?.startAnimation()

    let path = audio.path ?? ChatMessageHelper.createFilePath(message)
    if !FileManager.default.fileExists(atPath: path) {
      if let urlString = audio.url {
        viewModel.downLoad(urlString, path, nil) { [weak self] _, error in
          if error == nil {
            NEALog.infoLog(ModuleName + " " + ChatViewController.className(), desc: #function + "CALLBACK downLoad")
            NIMSDK.shared().mediaManager.play(path)
          } else {
            self?.showToast(error!.localizedDescription)
          }
        }
      }
    } else {
      NIMSDK.shared().mediaManager.play(path)
    }
  }

  func stopPlay() {
    if NIMSDK.shared().mediaManager.isPlaying() {
      playingCell?.stopAnimation()
      playingModel?.isPlaying = false
      NIMSDK.shared().mediaManager.stopPlay()
    }
  }

  //    play
  open func playAudio(_ filePath: String, didBeganWithError error: Error?) {
    print(#function + "\(error?.localizedDescription ?? "")")
    NIMSDK.shared().mediaManager.switch(viewModel.getHandSetEnable() ? .receiver : .speaker)
    if let e = error {
      if e.localizedDescription.count > 0 {
        view.makeToast(e.localizedDescription)
      }
      playingCell?.stopAnimation()
      playingModel?.isPlaying = false
    }
  }

  open func playAudio(_ filePath: String, didCompletedWithError error: Error?) {
    print(#function + "\(error?.localizedDescription ?? "")")
    if error?.localizedDescription.count ?? 0 > 0 {
      view.makeToast(error?.localizedDescription ?? "")
    }
    // stop
    playingCell?.stopAnimation()
    playingModel?.isPlaying = false
  }

  open func stopPlayAudio(_ filePath: String, didCompletedWithError error: Error?) {
    print(#function + "\(error?.localizedDescription ?? "")")

    playingCell?.stopAnimation()
    playingModel?.isPlaying = false
  }

  open func playAudio(_ filePath: String, progress value: Float) {}

  open func playAudioInterruptionEnd() {
    playingCell?.stopAnimation()
    playingModel?.isPlaying = false
  }

  open func playAudioInterruptionBegin() {
    // stop play
    playingCell?.stopAnimation()
    playingModel?.isPlaying = false
  }

  open func getRegisterCellDic() -> [String: NEBasePinMessageCell.Type] {
    cellClassDic
  }

  open func showTextViewController(_ model: NEPinMessageModel?) {
    let title = NECustomAttachment.titleOfRichText(model?.message.attachment)
    let body = NECustomAttachment.bodyOfRichText(model?.message.attachment) ?? model?.message.text
    let textView = getTextViewController(title: title, body: body)
    textView.modalPresentationStyle = .fullScreen
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: DispatchWorkItem(block: { [weak self] in
      self?.navigationController?.present(textView, animated: false)
    }))
  }

  func getTextViewController(title: String?, body: String?) -> TextViewController {
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

  // MARK: - NEIMKitClientListener

  public func onConnectStatus(_ status: V2NIMConnectStatus) {
    if status == .CONNECT_STATUS_WAITING {
      networkBroken = true
    }

    if status == .CONNECT_STATUS_CONNECTED, networkBroken {
      networkBroken = false
      DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: DispatchWorkItem(block: { [weak self] in
        // 断网重连后不会重发标记回调，需要手动拉取
        self?.loadData()
      }))
    }
  }
}
