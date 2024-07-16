
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class MultiForwardViewController: NEChatBaseViewController, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, ChatBaseCellDelegate, UIDocumentInteractionControllerDelegate, MultiForwardViewModelDelegate {
  public var viewModel = MultiForwardViewModel()
  private var messageAttachmentUrl: String?
  private var messageAttachmentFilePath: String = ""
  private var messageAttachmentMD5: String?
  public var cellRegisterDic = [String: UITableViewCell.Type]()
  public var brokenNetworkViewHeight: CGFloat = 36
  let interactionController = UIDocumentInteractionController()

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

  public init(_ attachmentUrl: String?,
              _ attachmentFilePath: String,
              _ attachmentMD5: String?) {
    super.init(nibName: nil, bundle: nil)
    messageAttachmentFilePath = attachmentFilePath
    messageAttachmentUrl = attachmentUrl
    messageAttachmentMD5 = attachmentMD5
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
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
    viewModel.delegate = self
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

    for (key, value) in NEChatUIKitClient.instance.getRegisterCustomCell() {
      cellRegisterDic[key] = value
    }

    for (key, value) in cellRegisterDic {
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
    viewModel.loadData(messageAttachmentUrl,
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
      case protocolSendFailed, -1009:
        showToast(commonLocalizable("network_error"))
      default:
        showToast(err.localizedDescription)
      }
    }
  }

  // MARK: UIDocumentInteractionControllerDelegate

  open func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
    self
  }

  // MARK: UITableViewDataSource, UITableViewDelegate

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.messages.count
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = viewModel.messages[indexPath.row]
    model.inMultiForward = true
    model.isPined = false
    var reuseId = ""
    if model.replyedModel?.isReplay == true,
       model.isRevoked == false {
      reuseId = "\(MessageType.reply.rawValue)"
    } else {
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
    viewModel.messages[indexPath.row].cellHeight() + chat_content_margin
  }

  open func getMultiForwardViewController(_ messageAttachmentUrl: String?,
                                          _ messageAttachmentFilePath: String,
                                          _ messageAttachmentMD5: String?) -> MultiForwardViewController {
    MultiForwardViewController(messageAttachmentUrl, messageAttachmentFilePath, messageAttachmentMD5)
  }

  // MARK: ChatBaseCellDelegate

  open func didTapMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?, _ replyModel: MessageModel?) {
    if let tapClick = NEKitChatConfig.shared.ui.messageItemClick {
      tapClick(cell, model)
      return
    }

    // 已撤回消息不可点击
    if model?.isRevoked == true {
      return
    }

    didTapMessage(cell, model, nil)
  }

  open func didTapMessage(_ cell: UITableViewCell?, _ model: MessageContentModel?, _ replyIndex: Int? = nil) {
    if model?.type == .image {
      if let imageObject = model?.message?.attachment as? V2NIMMessageImageAttachment {
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
            urls: ChatMessageHelper.getUrls(messages: viewModel.messages),
            url: imageUrl
          )
          showController.modalPresentationStyle = .overFullScreen
          present(showController, animated: false, completion: nil)
        }
      }
    } else if model?.type == .video,
              let object = model?.message?.attachment as? V2NIMMessageVideoAttachment {
      let path = object.path ?? ChatMessageHelper.createFilePath(model?.message)
      if FileManager.default.fileExists(atPath: path) {
        let url = URL(fileURLWithPath: path)
        let videoPlayer = VideoPlayerViewController()
        videoPlayer.modalPresentationStyle = .overFullScreen
        videoPlayer.videoUrl = url
        videoPlayer.totalTime = Int(object.duration)
        present(videoPlayer, animated: true, completion: nil)
      } else {
        if let index = replyIndex, index >= 0,
           index < tableView.numberOfRows(inSection: 0) {
          tableView.scrollToRow(at: IndexPath(row: index, section: 0),
                                at: .middle,
                                animated: true)
        }
        downloadFile(cell, model, object.url, path)
      }
    } else if model?.type == .location {
      if let locationModel = model as? MessageLocationModel, let lat = locationModel.lat, let lng = locationModel.lng {
        var params = [String: Any]()
        params["type"] = NEMapType.detail.rawValue
        params["nav"] = navigationController
        params["lat"] = lat
        params["lng"] = lng
        params["locationTitle"] = locationModel.title
        params["subTitle"] = locationModel.subTitle
        Router.shared.use(NERouterUrl.LocationVCRouter, parameters: params)
      }
    } else if model?.type == .file,
              let object = model?.message?.attachment as? V2NIMMessageFileAttachment {
      let path = object.path ?? ChatMessageHelper.createFilePath(model?.message)
      if !FileManager.default.fileExists(atPath: path) {
        if let index = replyIndex, index >= 0,
           index < tableView.numberOfRows(inSection: 0) {
          tableView.scrollToRow(at: IndexPath(row: index, section: 0),
                                at: .middle,
                                animated: true)
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
    } else if model?.type == .custom {
      if model?.customType == customMultiForwardType,
         let data = NECustomUtils.dataOfCustomMessage(model?.message?.attachment) {
        let url = data["url"] as? String
        let md5 = data["md5"] as? String
        guard let fileDirectory = NEPathUtils.getDirectoryForDocuments(dir: imkitDir) else { return }
        let fileName = multiForwardFileName + (model?.message?.messageClientId ?? "")
        let filePath = fileDirectory + fileName
        let multiForwardVC = getMultiForwardViewController(url, filePath, md5)
        navigationController?.pushViewController(multiForwardVC, animated: true)
      }
    } else {
      print(#function + "message did tap, type:\(String(describing: model?.type.rawValue))")
    }

    /// 下载附件（文件、视频消息）
    /// - Parameters:
    ///   - cell: 当前单元格
    ///   - model: 消息模型
    ///   - url: 远端下载链接
    ///   - path: 本地保存路径
    func downloadFile(_ cell: UITableViewCell?, _ model: MessageContentModel?, _ url: String?, _ path: String) {
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

      fileModel.state = .Downalod
      if let fileCell = cell as? NEBaseChatMessageCell {
        fileCell.setModel(fileModel, false)
      }

      viewModel.downLoad(urlString, path) { progress in
        NEALog.infoLog(ModuleName + " " + ChatViewController.className(), desc: #function + "downLoad file progress: \(progress)")
        fileModel.progress = progress
        fileModel.cell?.uploadProgress(progress)

      } _: { [weak self] localPath, error in
        self?.showErrorToast(error)
        if localPath != nil {
          fileModel.state = .Success
        }
      }
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
