
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCoreIM
import IQKeyboardManagerSwift
import NIMSDK
import MJRefresh
import NEKitCommonUI
import NEKitCommon
import NEKitCore

public class QChatViewController: NEBaseViewController, UINavigationControllerDelegate,
  QChatInputViewDelegate, QChatViewModelDelegate,UITableViewDataSource, UITableViewDelegate {
  private let tag = "QChatViewController"
  private var viewmodel: QChatViewModel?
  private var inputViewBottomConstraint: NSLayoutConstraint?

  public init(channel: ChatChannel?) {
    super.init(nibName: nil, bundle: nil)
    viewmodel = QChatViewModel(channel: channel)
    viewmodel?.delegate = self
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    commonUI()
    addObseve()
    loadData()
  }

  // MARK: lazy Method

  private lazy var brokenNetworkView: NEBrokenNetworkView = {
    let view =
      NEBrokenNetworkView(frame: CGRect(x: 0, y: kNavigationHeight + KStatusBarHeight,
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
    return tableView
  }()

  deinit {
    NELog.infoLog(className(), desc: "✅ QChatViewController release")
  }
    
    func commonUI() {
      title = viewmodel?.channel?.name
      addLeftAction(UIImage.ne_imageNamed(name: "server_menu"), #selector(enterServerVC), self)
      addRightAction(
        UIImage.ne_imageNamed(name: "channel_member"),
        #selector(enterChannelMemberVC),
        self
      )

      view.addSubview(tableView)
      NSLayoutConstraint.activate([
        tableView.topAnchor.constraint(
          equalTo: view.topAnchor,
          constant: kNavigationHeight + KStatusBarHeight
        ),
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -130),
      ])

      tableView.register(
        QChatBaseTableViewCell.self,
        forCellReuseIdentifier: "\(QChatBaseTableViewCell.self)"
      )
      tableView.register(
        QChatTextTableViewCell.self,
        forCellReuseIdentifier: "\(QChatTextTableViewCell.self)"
      )
      tableView.register(
        QChatImageTableViewCell.self,
        forCellReuseIdentifier: "\(QChatImageTableViewCell.self)"
      )
      tableView.register(
        QChatTimeTableViewCell.self,
        forCellReuseIdentifier: "\(QChatTimeTableViewCell.self)"
      )

  //        IQKeyboardManager.shared.enable = false
      IQKeyboardManager.shared.keyboardDistanceFromTextField = 60
      IQKeyboardManager.shared.enable = true
      IQKeyboardManager.shared.enableAutoToolbar = false
      let inputView = QChatInputView()
      var tip = localizable("send_to")
      if let cName = viewmodel?.channel?.name {
        tip = tip + cName
      }
      inputView.textField.placeholder = tip

      inputView.translatesAutoresizingMaskIntoConstraints = false
      inputView.delegate = self
      view.addSubview(inputView)
      if #available(iOS 11.0, *) {
        self.inputViewBottomConstraint = inputView.bottomAnchor
          .constraint(equalTo: self.view.bottomAnchor)
  //            self.inputViewBottomConstraint = inputView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
        NSLayoutConstraint.activate([
          inputView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
          inputView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
          inputView.heightAnchor.constraint(equalToConstant: 100),
        ])
      } else {
        // Fallback on earlier versions
        inputViewBottomConstraint = inputView.bottomAnchor
          .constraint(equalTo: view.bottomAnchor)
        NSLayoutConstraint.activate([
          inputView.leftAnchor.constraint(equalTo: view.leftAnchor),
          inputView.rightAnchor.constraint(equalTo: view.rightAnchor),
          inputView.heightAnchor.constraint(equalToConstant: 100),
        ])
      }
      inputViewBottomConstraint?.isActive = true

      weak var weakSelf = self
      NEChatDetectNetworkTool.shareInstance.netWorkReachability { status in
        if status == .notReachable, let networkView = weakSelf?.brokenNetworkView {
          weakSelf?.view.addSubview(networkView)
        } else {
          weakSelf?.brokenNetworkView.removeFromSuperview()
        }
      }
    }

  //    MARK: event

    @objc func enterChannelMemberVC() {
      let memberVC = QChatChannelMembersVC()
      memberVC.channel = viewmodel?.channel
      navigationController?.pushViewController(memberVC, animated: true)
    }

    @objc func enterServerVC() {
      navigationController?.popViewController(animated: true)
    }

    func loadData() {
      weak var weakSelf = self
      viewmodel?.getMessageHistory { error, messages in

        if let err = error {
          NELog.errorLog(self.tag, desc: "❌getMessageHistory error, error:\(err)")
        } else {
          if let tempArray = weakSelf?.viewmodel?.messages, tempArray.count > 0 {
            weakSelf?.tableView.reloadData()
            weakSelf?.tableView.scrollToRow(
              at: IndexPath(row: tempArray.count - 1, section: 0),
              at: .bottom,
              animated: false
            )
            if let time = messages?.first?.message?.timestamp {
              weakSelf?.viewmodel?.markMessageRead(time: time)
            }
          }
        }
      }
    }

    @objc func loadMoreData() {
      weak var weakSelf = self
      viewmodel?.getMoreMessageHistory { error, messageFrames in
        weakSelf?.tableView.reloadData()
        weakSelf?.tableView.mj_header?.endRefreshing()
      }
    }

    func addObseve() {
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(onUpdateChannel),
        name: NotificationName.updateChannel,
        object: nil
      )
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(onDeleteChannel),
        name: NotificationName.deleteChannel,
        object: nil
      )
  //        NotificationCenter.default.addObserver(self,
  //                                               selector: #selector(keyBoardWillShow(_ :)),
  //                                               name: UIResponder.keyboardWillShowNotification,
  //                                               object: nil)
  //
  //        NotificationCenter.default.addObserver(self,
  //                                               selector: #selector(keyBoardWillHide(_ :)),
  //                                               name: UIResponder.keyboardWillHideNotification,
  //                                               object: nil)
    }

    @objc func onUpdateChannel(noti: Notification) {
      // enter ChatVC
      guard let channel = noti.object as? ChatChannel else {
        return
      }
      viewmodel?.channel = channel
      title = viewmodel?.channel?.name
    }

    @objc func onDeleteChannel(noti: Notification) {
      navigationController?.popToRootViewController(animated: true)
    }

    // MARK: 键盘通知相关操作

  //    @objc func keyBoardWillShow(_ notification:Notification) {
  //        let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
  //        self.inputViewBottomConstraint?.constant = -keyboardRect.size.height
  //        UIView.animate(withDuration: 0.25, animations: {
  //            self.view.layoutIfNeeded()
  //        })
  //    }
  //
  //    @objc func keyBoardWillHide(_ notification:Notification) {
  //        self.inputViewBottomConstraint?.constant = 0
  //        UIView.animate(withDuration: 0.25, animations: {
  //            self.view.layoutIfNeeded()
  //        })
  //    }

    // MARK: QChatInputViewDelegate

    func sendText(text: String?) {
      NELog.infoLog(tag, desc: "sendText:\(text ?? "")")
      guard let content = text, content.count > 0 else {
        showToast(localizable("text_is_nil"))

        return
      }
      viewmodel?.sendTextMessage(text: content) { [weak self] error in
        if error != nil {
          self?.view.makeToast(error?.localizedDescription)
        } else {}
      }
    }

    func willSelectItem(button: UIButton, index: Int) {
      if index == 2 {
          showBottomAlert(self, false)
      } else {
        showToast(localizable("open_soon"))
      }
    }

  //    MARK: UIImagePickerControllerDelegate

    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController
                                        .InfoKey: Any]) {
      picker.dismiss(animated: true, completion: nil)
      guard let image = info[.originalImage] as? UIImage else {
        showToast(localizable("image_is_nil"))
        return
      }
      // 发送消息
      viewmodel?.sendImageMessage(image: image) { [weak self] error in
        if error != nil {
          self?.view.makeToast(error?.localizedDescription)
        }
      }
    }

  //    MARK: QChatViewModelDelegate

    public func onRecvMessages(_ messages: [NIMQChatMessage]) {
      tableView.reloadData()
      if let messageCount = viewmodel?.messages.count, messageCount > 1 {
        tableView.scrollToRow(
          at: IndexPath(row: messageCount - 1, section: 0),
          at: .bottom,
          animated: false
        )
        if let time = viewmodel?.messages.last?.message?.timestamp {
          viewmodel?.markMessageRead(time: time)
        }
      }
    }

    public func send(_ message: NIMQChatMessage, progress: Float) {}

    public func send(_ message: NIMQChatMessage, didCompleteWithError error: Error?) {
      if let e = error as NSError? {
        if e.code == 403 {
          showAlert(message: localizable("no_Permession")) {}
        }
      }
      tableView.reloadData()
      if let messageCount = viewmodel?.messages.count, messageCount > 1 {
        tableView.scrollToRow(
          at: IndexPath(row: messageCount - 1, section: 0),
          at: .bottom,
          animated: false
        )
      }
    }

    public func willSend(_ message: NIMQChatMessage) {
      tableView.reloadData()
      if let messageCount = viewmodel?.messages.count, messageCount > 1 {
        tableView.scrollToRow(
          at: IndexPath(row: messageCount - 1, section: 0),
          at: .bottom,
          animated: false
        )
      }
    }
    
    //MARK: UITableViewDataSource, UITableViewDelegate
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      viewmodel?.messages.count ?? 0
    }

    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let messageFrame = viewmodel?.messages[indexPath.row]
      var reuseIdentifier = "\(QChatBaseTableViewCell.self)"

      guard let msgFrame = messageFrame else {
        return tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
      }

      if msgFrame.showTime {
        reuseIdentifier = "\(QChatTimeTableViewCell.self)"
      } else {
        // 根据cell类型区分identify
        switch msgFrame.message?.messageType {
        case .text:
          reuseIdentifier = "\(QChatTextTableViewCell.self)"
        case .image:
          reuseIdentifier = "\(QChatImageTableViewCell.self)"
        default:
          reuseIdentifier = "\(QChatBaseTableViewCell.self)"
        }
      }

      if msgFrame.showTime {
        let cell = tableView.dequeueReusableCell(
          withIdentifier: reuseIdentifier,
          for: indexPath
        ) as! QChatTimeTableViewCell
        cell.messageFrame = messageFrame
        return cell
      } else {
        let cell = tableView.dequeueReusableCell(
          withIdentifier: reuseIdentifier,
          for: indexPath
        ) as! QChatBaseTableViewCell
        cell.messageFrame = messageFrame
        cell.delegate = self
        return cell
      }
    }

    public func tableView(_ tableView: UITableView,
                          heightForRowAt indexPath: IndexPath) -> CGFloat {
      let messageFrame = viewmodel?.messages[indexPath.row]
      return messageFrame?.cellHeight ?? 0
    }
}

// MARK: ===============   QChatBaseCellDelegate   ================

extension QChatViewController: QChatBaseCellDelegate {
  func didSelectWithCell(cell: QChatBaseTableViewCell, type: QChatMessageClickType,
                         message: NIMQChatMessage) {
    if type == .message {
      didClickMessage(messgae: message)
    } else if type == .LongPressMessage {}
  }

  func didClickHeader(_ message: NIMQChatMessage) {
    if IMKitLoginManager.instance.isMySelf(message.from) == true {
      Router.shared.use(
        MeSettingRouter,
        parameters: ["nav": navigationController as Any],
        closure: nil
      )
    } else {
      Router.shared.use(
        ContactUserInfoPageRouter,
        parameters: ["nav": navigationController as Any, "uid": message.from as Any],
        closure: nil
      )
    }
  }

  // click action
  func didClickMessage(messgae: NIMQChatMessage) {
    if messgae.messageType == .image {
      let imageObject = messgae.messageObject as! NIMImageObject
      if let imageUrl = imageObject.url {
        let showController = PhotoBrowserController(urls: [imageUrl], url: imageUrl)
        showController.modalPresentationStyle = .overFullScreen
        present(showController, animated: false, completion: nil)
      }

    } else if messgae.messageType == .audio {}
  }
}

