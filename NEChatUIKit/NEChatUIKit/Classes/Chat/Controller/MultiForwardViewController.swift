
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class MultiForwardViewController: ChatBaseViewController, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, ChatBaseCellDelegate, UIDocumentInteractionControllerDelegate, MultiForwardViewModelDelegate {
  public var viewmodel = MultiForwardViewModel()
  private var messageAttachmentUrl: String?
  private var messageAttachmentFilePath: String = ""
  private var messageAttachmentMD5: String?
  public var cellRegisterDic = [String: UITableViewCell.Type]()
  public var brokenNetworkViewHeight: CGFloat = 36
  let interactionController = UIDocumentInteractionController()

  public init(_ attachmentUrl: String?,
              _ attachmentFilePath: String,
              _ attachmentMD5: String?) {
    super.init(nibName: nil, bundle: nil)
    messageAttachmentFilePath = attachmentFilePath
    messageAttachmentUrl = attachmentUrl
    messageAttachmentMD5 = attachmentMD5
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    NEChatDetectNetworkTool.shareInstance.netWorkReachability { [weak self] status in
      if status == .notReachable {
        self?.brokenNetworkView.isHidden = false
      } else {
        self?.brokenNetworkView.isHidden = true
      }
    }
  }

  override func backEvent() {
    super.backEvent()
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    viewmodel.delegate = self
    commonUI()
    loadData()
  }

  open func commonUI() {
    title = chatLocalizable("chat_history")
    navigationView.backgroundColor = .white
    navigationView.titleBarBottomLine.isHidden = false
    navigationView.moreButton.isHidden = true
    navigationView.addBackButtonTarget(target: self, selector: #selector(backEvent))

    tableView.register(
      NEBaseChatMessageCell.self,
      forCellReuseIdentifier: "\(NEBaseChatMessageCell.self)"
    )

    NEChatUIKitClient.instance.getRegisterCustomCell().forEach { (key: String, value: UITableViewCell.Type) in
      cellRegisterDic[key] = value
    }

    cellRegisterDic.forEach { (key: String, value: UITableViewCell.Type) in
      tableView.register(value, forCellReuseIdentifier: key)
    }

    view.addSubview(tableView)
    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      ])
    } else {
      NSLayoutConstraint.activate([
        tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -34),
      ])
    }

    view.addSubview(brokenNetworkView)
    NSLayoutConstraint.activate([
      brokenNetworkView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      brokenNetworkView.leftAnchor.constraint(equalTo: view.leftAnchor),
      brokenNetworkView.rightAnchor.constraint(equalTo: view.rightAnchor),
      brokenNetworkView.heightAnchor.constraint(equalToConstant: brokenNetworkViewHeight),
    ])
  }

  func loadData() {
    view.makeToastActivity(.center)
    viewmodel.loadData(messageAttachmentUrl,
                       messageAttachmentFilePath,
                       messageAttachmentMD5) { [weak self] error in
      self?.view.hideToastActivity()
      if let err = error as? NSError {
        if err.code == 0 {
          self?.showToast(err.domain)
        } else {
          self?.showToast(chatLocalizable("multiForward_open_failed"))
        }
        self?.navigationController?.popViewController(animated: true)
      } else {
        self?.tableView.reloadData()
      }
    }
  }

  private func showErrorToast(_ error: Error?) {
    if let err = error as? NSError {
      switch err.code {
      case noNetworkCode, -1009:
        showToast(commonLocalizable("network_error"))
      default:
        showToast(err.localizedDescription)
      }
    }
  }

  // MARK: lazy Method

  public lazy var brokenNetworkView: NEBrokenNetworkView = {
    let view = NEBrokenNetworkView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
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
    tableView.keyboardDismissMode = .onDrag
    return tableView
  }()

  // MARK: UIDocumentInteractionControllerDelegate

  open func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
    self
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
    model.inMultiForward = true
    model.isPined = false
    var reuseId = ""
    if model.replyedModel?.isReplay == true,
       model.isRevoked == false {
      reuseId = "\(MessageType.reply.rawValue)"
    } else {
      let key = "\(model.type.rawValue)"
      if model.type == .custom {
        if let attch = NECustomAttachment.attachmentOfCustomMessage(message: model.message) {
          if attch.customType == customMultiForwardType {
            reuseId = "\(MessageType.multiForward.rawValue)"
          } else if attch.customType == customRichTextType {
            reuseId = "\(MessageType.richText.rawValue)"
          } else if NEChatUIKitClient.instance.getRegisterCustomCell()["\(attch.customType)"] != nil {
            reuseId = "\(attch.customType)"
          } else {
            reuseId = "\(NEBaseChatMessageCell.self)"
          }
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
        c.setModel(m)
      }
      return c
    } else if let c = cell as? NEBaseChatMessageCell {
      if let m = model as? MessageContentModel {
        c.setModel(m, false)
        c.setSelect(m, false)
        c.delegate = self
      }

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
    viewmodel.messages[indexPath.row].cellHeight() + chat_content_margin
  }

  open func getMultiForwardViewController(_ messageAttachmentUrl: String?,
                                          _ messageAttachmentFilePath: String,
                                          _ messageAttachmentMD5: String?) -> MultiForwardViewController {
    MultiForwardViewController(messageAttachmentUrl, messageAttachmentFilePath, messageAttachmentMD5)
  }

  // MARK: ChatBaseCellDelegate

  open func didTapMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    if let tapClick = NEKitChatConfig.shared.ui.messageItemClick {
      tapClick(cell, model)
      return
    }

    // 已撤回消息不可点击
    if model?.isRevoked == true {
      return
    }

    didTapMessage(cell, model)
  }

  open func didTapMessage(_ cell: UITableViewCell?, _ model: MessageContentModel?, _ replyIndex: Int? = nil) {
    if model?.type == .image {
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
          videoCell.setModel(videoModel, false)
        }

        viewmodel.downLoad(urlString, path) { progress in
          NELog.infoLog(ModuleName + " " + (weakSelf?.className() ?? ""), desc: #function + "CALLBACK downLoad: \(progress)")

          videoModel.progress = progress
          if progress >= 1.0 {
            videoModel.state = .Success
          }
          videoModel.cell?.uploadProgress(byRight: false, progress)
        } _: { error in
          weakSelf?.showErrorToast(error)
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
            fileCell.setModel(fileModel, false)
          }

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
            fileModel.cell?.uploadProgress(byRight: false, newProgress)

          } _: { [weak self] error in
            self?.showErrorToast(error)
          }
        }
      } else {
        let url = URL(fileURLWithPath: path)
        interactionController.url = url
        interactionController.delegate = self // UIDocumentInteractionControllerDelegate
        if interactionController.presentPreview(animated: true) {} else {
          interactionController.presentOptionsMenu(from: view.bounds, in: view, animated: true)
        }
      }
    } else if model?.type == .custom, let attach = NECustomAttachment.attachmentOfCustomMessage(message: model?.message) {
      if attach.customType == customMultiForwardType,
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

  // MARK: ChatBaseCellDelegate ignore protocol

  public func didTapAvatarView(_ cell: UITableViewCell, _ model: MessageContentModel?) {}

  public func didLongPressAvatar(_ cell: UITableViewCell, _ model: MessageContentModel?) {}

  public func didLongPressMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?) {}

  public func didTapResendView(_ cell: UITableViewCell, _ model: MessageContentModel?) {}

  public func didTapReeditButton(_ cell: UITableViewCell, _ model: MessageContentModel?) {}

  public func didTapReadView(_ cell: UITableViewCell, _ model: MessageContentModel?) {}

  public func didTapSelectButton(_ cell: UITableViewCell, _ model: MessageContentModel?) {}
}
