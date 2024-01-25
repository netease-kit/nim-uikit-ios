// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonUIKit
import NECoreIMKit
import NIMSDK
import UIKit

let PinMessageDefaultType = 1000

@objcMembers
open class NEBasePinMessageViewController: ChatBaseViewController, UITableViewDataSource, UITableViewDelegate, PinMessageViewModelDelegate, PinMessageCellDelegate, UIDocumentInteractionControllerDelegate, NIMMediaManagerDelegate {
  let viewmodel = PinMessageViewModel()

  var session: NIMSession
  var cellClassDic: [String: NEBasePinMessageCell.Type] = [:]
  // pin 列表内容最大宽度
  public var pin_content_maxW = (kScreenWidth - 72)

  var playingCell: NEBasePinMessageAudioCell?
  var playingModel: MessageAudioModel?

  public init(session: NIMSession) {
    self.session = session
    super.init(nibName: nil, bundle: nil)
    NIMSDK.shared().mediaManager.add(self)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NIMSDK.shared().mediaManager.remove(self)
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

    viewmodel.delegate = self
    setupUI()
    loadData()
  }

  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    stopPlay()
  }

  func loadData() {
    weak var weakSelf = self
    viewmodel.getPinitems(session: session) { error in
      if let err = error as? NSError {
        if weakSelf?.session.sessionType == .team, err.code == 414 {
          weakSelf?.showToast(chatLocalizable("team_not_exist"))
        } else {
          weakSelf?.showToast(err.localizedDescription)
        }
      } else {
        weakSelf?.viewmodel.items.forEach { model in
          ChatMessageHelper.downloadAudioFile(message: model.message)
        }
        weakSelf?.emptyView.isHidden = (weakSelf?.viewmodel.items.count ?? 0) > 0
        weakSelf?.tableView.reloadData()
      }
    }
  }

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
    cellClassDic.forEach { (key: String, value: NEBasePinMessageCell.Type) in
      tableView.register(value, forCellReuseIdentifier: "\(key)")
    }
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       // Get the new view controller using segue.destination.
       // Pass the selected object to the new view controller.
   }
   */

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let item = viewmodel.items[indexPath.row]
    if item.message.session?.sessionType == .P2P {
      let session = item.message.session
      Router.shared.use(
        PushP2pChatVCRouter,
        parameters: ["nav": navigationController as Any, "session": session as Any,
                     "anchor": item.message],
        closure: nil
      )
    } else if item.message.session?.sessionType == .team {
      let session = item.message.session
      Router.shared.use(
        PushTeamChatVCRouter,
        parameters: ["nav": navigationController as Any, "session": session as Any,
                     "anchor": item.message],
        closure: nil
      )
    }
  }

  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = viewmodel.items[indexPath.row]
    var reuseId = "\(model.chatmodel.type.rawValue)"
    if model.chatmodel.type == .custom,
       let attach = NECustomAttachment.attachmentOfCustomMessage(message: model.chatmodel.message) {
      if attach.customType == customMultiForwardType {
        reuseId = "\(MessageType.multiForward.rawValue)"
      } else if attach.customType == customRichTextType {
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

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewmodel.items.count
  }

  open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let model = viewmodel.items[indexPath.row]
    if let attach = NECustomAttachment.attachmentOfCustomMessage(message: model.message) {
      if attach.customType == customMultiForwardType {
        return model.cellHeight(pinContentMaxW: pin_content_maxW) - 30
      }
    }
    return model.cellHeight(pinContentMaxW: pin_content_maxW)
  }

  func cancelPinActionClicked(item: PinMessageModel) {
    weak var weakSelf = self
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      weakSelf?.showToast(commonLocalizable("network_error"))
      return
    }
    weakSelf?.viewmodel.removePinMessage(item.message) { error, model in
      if let err = error {
        //          weakSelf?.showToast(err.localizedDescription)
      } else {
        if let index = weakSelf?.viewmodel.items.firstIndex(of: item) {
          NotificationCenter.default.post(name: Notification.Name(removePinMessageNoti), object: item.message)
          weakSelf?.viewmodel.items.remove(at: index)
          weakSelf?.emptyView.isHidden = (weakSelf?.viewmodel.items.count ?? 0) > 0
          weakSelf?.tableView.reloadData()
          weakSelf?.showToast(chatLocalizable("cancel_pin_success"))
        }
      }
    }
  }

  func copyActionClicked(item: PinMessageModel) {
    weak var weakSelf = self
    let text = item.message.text
    let pasteboard = UIPasteboard.general
    pasteboard.string = text
    weakSelf?.view.makeToast(chatLocalizable("copy_success"), duration: 2, position: .center)
  }

  func forwardActionClicked(item: PinMessageModel) {
    weak var weakSelf = self
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      weakSelf?.showToast(commonLocalizable("network_error"))
      return
    }
    weakSelf?.forwardMessage(item.message)
  }

  open func showAction(item: PinMessageModel) {
    var actions = [UIAlertAction]()
    weak var weakSelf = self
    let cancelPinAction = UIAlertAction(title: chatLocalizable("operation_cancel_pin"), style: .default) { _ in
      weakSelf?.cancelPinActionClicked(item: item)
    }
    actions.append(cancelPinAction)

    if item.message.messageType == .text {
      let copyAction = UIAlertAction(title: chatLocalizable("operation_copy"), style: .default) { _ in
        weakSelf?.copyActionClicked(item: item)
      }
      actions.append(copyAction)
    }

    if item.message.messageType != .audio {
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

  func forwardMessageToUser(_ message: NIMMessage) {
    weak var weakSelf = self
    Router.shared.register(ContactSelectedUsersRouter) { param in
      print("user setting accids : ", param)
      var items = [ForwardItem]()

      if let users = param["im_user"] as? [NIMUser] {
        users.forEach { user in
          let item = ForwardItem()
          item.uid = user.userId
          item.avatar = user.userInfo?.avatarUrl
          item.name = user.getShowName()
          items.append(item)
        }

        let forwardAlert = weakSelf!.getForwardAlertController()
        forwardAlert.setItems(items)
        if let session = self.viewmodel.session {
          forwardAlert.context = ChatMessageHelper.getSessionName(session: session)
        }
        weakSelf?.addChild(forwardAlert)
        weakSelf?.view.addSubview(forwardAlert.view)

        forwardAlert.sureBlock = { comment in
          if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
            weakSelf?.showToast(commonLocalizable("network_error"))
            return
          }
          weakSelf?.viewmodel.forwardUserMessage(message, users, comment) { error in
            if let err = error as? NSError {
              if err.code == noNetworkCode {
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
    Router.shared.use(ContactUserSelectRouter, parameters: param, closure: nil)
  }

  func forwardMessageToTeam(_ message: NIMMessage) {
    weak var weakSelf = self
    Router.shared.register(ContactTeamDataRouter) { param in
      if let team = param["team"] as? NIMTeam {
        let item = ForwardItem()
        item.avatar = team.avatarUrl
        item.name = team.getShowName()
        item.uid = team.teamId

        let forwardAlert = weakSelf!.getForwardAlertController()
        forwardAlert.setItems([item])
        if let session = self.viewmodel.session {
          forwardAlert.context = ChatMessageHelper.getSessionName(session: session)
        }
        forwardAlert.sureBlock = { comment in
          if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
            weakSelf?.showToast(commonLocalizable("network_error"))
            return
          }
          weakSelf?.viewmodel.forwardTeamMessage(message, team, comment) { error in
            if let err = error as? NSError {
              if err.code == noNetworkCode {
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

  open func forwardMessage(_ message: NIMMessage) {
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

  // MARK: PinMessageViewModelDelegate

  open func didNeedRefreshUI() {
    loadData()
  }

  // MARK: PinMessageCellDelegate

  open func didClickMore(_ model: PinMessageModel?) {
    if let item = model {
      showAction(item: item)
    }
  }

  open func didClickContent(_ model: PinMessageModel?, _ cell: NEBasePinMessageCell) {
    NELog.infoLog(className(), desc: #function + "didClickContent")

    if model?.message.messageType == .audio {
      startPlay(cell: cell, model: model)
    } else if model?.message.messageType == .image {
      if let imageObject = model?.message.messageObject as? NIMImageObject {
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
            urls: [imageUrl],
            url: imageUrl
          )
          showController.modalPresentationStyle = .overFullScreen
          present(showController, animated: false, completion: nil)
        }
      }
    } else if model?.message.messageType == .video,
              let object = model?.message.messageObject as? NIMVideoObject {
      stopPlay()
      let videoPlayer = VideoPlayerViewController()
      videoPlayer.modalPresentationStyle = .overFullScreen
      videoPlayer.totalTime = object.duration

      if let path = object.path, FileManager.default.fileExists(atPath: path) == true {
        let url = URL(fileURLWithPath: path)
        videoPlayer.videoUrl = url
        present(videoPlayer, animated: true, completion: nil)

      } else if let url = object.url, let remoteUrl = URL(string: url) {
        videoPlayer.videoUrl = remoteUrl
        present(videoPlayer, animated: true, completion: nil)
      }

    } else if model?.message.messageType == .text {
      showTextViewController(model)
    } else if model?.message.messageType == .location, let title = model?.message.text,
              let locationObject = model?.message.messageObject as? NIMLocationObject {
      let lat = locationObject.latitude
      let lng = locationObject.longitude
      let subTitle = locationObject.title

      let mapDetail = NEDetailMapController(type: .detail)
      mapDetail.currentPoint = CGPoint(x: lat, y: lng)
      mapDetail.locationTitle = title
      mapDetail.subTitle = subTitle
      navigationController?.pushViewController(mapDetail, animated: true)
    } else if model?.message.messageType == .file,
              let object = model?.message.messageObject as? NIMFileObject,
              let path = object.path {
      guard let fileModel = model?.pinFileModel as? PinMessageFileModel else {
        NELog.infoLog(ModuleName + " " + className(), desc: #function + "PinMessageFileModel not exit")
        return
      }

      if fileModel.state == .Downalod {
        NELog.infoLog(ModuleName + " " + className(), desc: #function + "downLoad state, click ingore")
        return
      }
      if !FileManager.default.fileExists(atPath: path) {
        if let urlString = object.url, let path = object.path {
          fileModel.state = .Downalod

          viewmodel.downLoad(urlString, path) { [weak self] progress in
            NELog.infoLog(ModuleName + " " + (self?.className() ?? ""), desc: #function + "downLoad file progress: \(progress)")
            var newProgress = progress
            if newProgress < 0 {
              newProgress = abs(progress) / fileModel.size
            }
            fileModel.progress = newProgress
            if newProgress >= 1.0 {
              fileModel.state = .Success
            }
            fileModel.cell?.uploadProgress(progress: newProgress)

          } _: { error in
          }
        }
      } else {
        let url = URL(fileURLWithPath: path)
        interactionController.url = url
        interactionController.delegate = self
        if interactionController.presentPreview(animated: true) {}
        else {
          interactionController.presentOptionsMenu(from: view.bounds, in: view, animated: true)
        }
      }
    } else if model?.message.messageType == .custom, let attach = NECustomAttachment.attachmentOfCustomMessage(message: model?.message) {
      if attach.customType == customRichTextType {
        showTextViewController(model)
      } else if attach.customType == customMultiForwardType,
                let data = NECustomAttachment.dataOfCustomMessage(message: model?.message) {
        let url = data["url"] as? String
        let md5 = data["md5"] as? String
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileName = multiForwardFileName + (model?.message.messageId ?? "")
        let filePath = documentsDirectory.appendingPathComponent("NEIMUIKit/\(fileName)").relativePath
        let multiForwardVC = getMultiForwardViewController(url, filePath, md5)
        navigationController?.pushViewController(multiForwardVC, animated: true)
      }
    }
  }

  private func startPlay(cell: NEBasePinMessageCell?, model: PinMessageModel?) {
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

  func startPlaying(audioMessage: NIMMessage?) {
    guard let message = audioMessage, let audio = message.messageObject as? NIMAudioObject else {
      return
    }
    playingCell?.startAnimation()
    if let path = audio.path, FileManager.default.fileExists(atPath: path) == true {
      NELog.infoLog(className(), desc: #function + " play path : " + path)
      if viewmodel.getHandSetEnable() == true {
        NIMSDK.shared().mediaManager.switch(.receiver)
      } else {
        NIMSDK.shared().mediaManager.switch(.speaker)
      }
      NIMSDK.shared().mediaManager.play(path)
    } else {
      NELog.infoLog(className(), desc: #function + " audio path is empty, play url : " + (audio.url ?? ""))
      ChatMessageHelper.downloadAudioFile(message: message)
      playingCell?.stopAnimation()
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
    NIMSDK.shared().mediaManager.switch(viewmodel.getHandSetEnable() ? .receiver : .speaker)
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
    print(#function)
    playingCell?.stopAnimation()
    playingModel?.isPlaying = false
  }

  open func playAudioInterruptionBegin() {
    print(#function)
    // stop play
    playingCell?.stopAnimation()
    playingModel?.isPlaying = false
  }

  open func getRegisterCellDic() -> [String: NEBasePinMessageCell.Type] {
    cellClassDic
  }

  open func showTextViewController(_ model: PinMessageModel?) {
    let title = NECustomAttachment.titleOfRichText(message: model?.message)
    let body = NECustomAttachment.bodyOfRichText(message: model?.message) ?? model?.message.text
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

  // MARK: UIDocumentInteractionControllerDelegate

  open func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
    self
  }

  open func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    controller.dismiss(animated: true)
  }
}
