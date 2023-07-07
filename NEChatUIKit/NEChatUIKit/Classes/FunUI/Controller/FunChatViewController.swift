//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK
import NECommonKit

@objcMembers
open class FunChatViewController: ChatViewController, FunChatInputViewDelegate, NIMUserManagerDelegate, FunChatRecordViewDelegate {
  public weak var recordView: FunRecordAudioView?
  public var currentKeyboardHeight: CGFloat = 0

  override public init(session: NIMSession) {
    super.init(session: session)
    registerCellDic = [
      "\(MessageType.text.rawValue)": FunChatMessageTextCell.self,
      "\(MessageType.rtcCallRecord.rawValue)": FunChatMessageCallCell.self,
      "\(MessageType.audio.rawValue)": FunChatMessageAudioCell.self,
      "\(MessageType.image.rawValue)": FunChatMessageImageCell.self,
      "\(MessageType.revoke.rawValue)": FunChatMessageRevokeCell.self,
      "\(MessageType.video.rawValue)": FunChatMessageVideoCell.self,
      "\(MessageType.file.rawValue)": FunChatMessageFileCell.self,
      "\(MessageType.reply.rawValue)": FunChatMessageReplyCell.self,
      "\(MessageType.location.rawValue)": FunChatMessageLocationCell.self,
      "\(MessageType.time.rawValue)": FunChatMessageTipCell.self,
    ]

    normalInputHeight = 90
    networkToolHeight = 48
    customNavigationView.bottomLine.backgroundColor = .funChatNavigationBottomLineColor
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .funChatBackgroundColor // 换肤颜色提取
    view.bringSubviewToFront(menuView)
    brokenNetworkView.errorIcon.isHidden = false
    brokenNetworkView.backgroundColor = .funChatNetworkBrokenBackgroundColor
    brokenNetworkView.content.textColor = .funChatNetworkBrokenTitleColor
    getFunInputView()?.funDelegate = self
  }

  override open func didLongTouchMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    super.didLongTouchMessageView(cell, model)
    operationView?.layer.cornerRadius = 8
  }

  override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let m = viewmodel.messages[indexPath.row]
    if m.type == .custom {
      if let object = m.message?.messageObject as? NIMCustomObject, let custom = object.attachment as? NECustomAttachmentProtocol {
        return custom.cellHeight
      }
    }

    if let contentModel = m as? MessageContentModel {
      if contentModel.type == .revoke {
        return 28
      }
    }

    return m.cellHeight()
  }

  override open func getMenuView() -> NEBaseChatInputView {
    let input = FunChatInputView()
    let gesture = UILongPressGestureRecognizer(target: self, action: #selector(holdToSpeak(gesture:)))
    input.holdToSpeakView.addGestureRecognizer(gesture)
    return input
  }

  override open func getForwardAlertController() -> NEBaseForwardAlertViewController {
    FunForwardAlertViewController()
  }

  override func getUserSelectVC() -> NEBaseSelectUserViewController {
    FunSelectUserViewController(sessionId: viewmodel.session.sessionId, showSelf: false)
  }

  override func getTextViewController(text: String) -> TextViewController {
    let textViewController = super.getTextViewController(text: text)
    textViewController.view.backgroundColor = .funChatBackgroundColor
    return textViewController
  }

  open func recordModeChangeDidClick() {
    normalOffset = 0
    layoutInputView(offset: 0)
    UIApplication.shared.keyWindow?.endEditing(true)
  }

  open func didHideReplyMode() {
    viewmodel.isReplying = false
    if currentKeyboardHeight > 0 {
      normalOffset = 30
    } else {
      normalOffset = 0
    }
    layoutInputView(offset: currentKeyboardHeight)
  }

  public func didShowReplyMode() {
    viewmodel.isReplying = true
    menuView.textView.becomeFirstResponder()
  }

  override open func expandMoreAction() {
    var items = NEChatUIKitClient.instance.getMoreActionData(sessionType: viewmodel.session.sessionType)
    let photo = NEMoreItemModel()
    photo.image = UIImage.ne_imageNamed(name: "fun_chat_photo")
    photo.title = chatLocalizable("chat_photo")
    photo.type = .photo
    photo.customDelegate = self
    photo.action = #selector(openPhoto)
    items.insert(photo, at: 0)
    menuView.chatAddMoreView.configData(data: items)
  }

  func openPhoto() {
    NELog.infoLog(className(), desc: "open photo")
    willSelectItem(button: menuView.currentButton, index: showPhotoTag)
  }

  override open func showRtcCallAction() {
    var param = [String: AnyObject]()
    param["remoteUserAccid"] = viewmodel.session.sessionId as AnyObject
    param["currentUserAccid"] = NIMSDK.shared().loginManager.currentAccount() as AnyObject
    param["remoteShowName"] = titleContent as AnyObject
    if let user = viewmodel.repo.getUserInfo(userId: viewmodel.session.sessionId), let avatar = user.userInfo?.avatarUrl {
      param["remoteAvatar"] = avatar as AnyObject
    }

    let videoCallAction = NECustomAlertAction(title: chatLocalizable("video_call")) {
      param["type"] = NSNumber(integerLiteral: 2) as AnyObject
      Router.shared.use(CallViewRouter, parameters: param)
    }
    let audioCallAction = NECustomAlertAction(title: chatLocalizable("audio_call")) {
      param["type"] = NSNumber(integerLiteral: 1) as AnyObject
      Router.shared.use(CallViewRouter, parameters: param)
    }
    showCustomActionSheet([videoCallAction, audioCallAction])
  }

  override open func forwardMessage() {
    if let message = viewmodel.operationModel?.message {
      weak var weakSelf = self
      let userAction = NECustomAlertAction(title: chatLocalizable("contact_user")) {
        weakSelf?.forwardMessageToUser(message: message)
      }

      let teamAction = NECustomAlertAction(title: chatLocalizable("team")) {
        weakSelf?.forwardMessageToTeam(message: message)
      }

      showCustomActionSheet([teamAction, userAction])
    }
  }

  /// 设置按钮点击事件
  override open func toSetting() {
    if let block = NEKitChatConfig.shared.ui.titleBarRightClick {
      block()
      return
    }
    if viewmodel.session.sessionType == .team {
      Router.shared.use(
        TeamSettingViewRouter,
        parameters: ["nav": navigationController as Any,
                     "teamid": viewmodel.session.sessionId],
        closure: nil
      )
    } else if viewmodel.session.sessionType == .P2P {
      let userSetting = FunUserSettingViewController()
      userSetting.userId = viewmodel.session.sessionId
      navigationController?.pushViewController(userSetting, animated: true)
    }
  }

  override open func keyBoardWillShow(_ notification: Notification) {
    if viewmodel.isReplying {
      normalOffset = -10
    } else {
      normalOffset = 30
    }
    let keyboardRect = (notification
      .userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
    currentKeyboardHeight = keyboardRect.height
    super.keyBoardWillShow(notification)
  }

  override open func keyBoardWillHide(_ notification: Notification) {
    if viewmodel.isReplying {
      normalOffset = -30
    } else {
      normalOffset = 0
    }
    currentKeyboardHeight = 0
    super.keyBoardWillHide(notification)
  }

  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    // Get the new view controller using segue.destination.
    // Pass the selected object to the new view controller.
  }

  open func holdToSpeak(gesture: UILongPressGestureRecognizer) {
    switch gesture.state {
    case .possible:

      break
    case .began:
      print("start show record audio view")
      if NEAuthManager.hasAudioAuthoriztion() {
        showRecordView()
      } else {
        weak var weakSelf = self
        NEAuthManager.requestAudioAuthorization { granted in
          if granted == false {
            DispatchQueue.main.async {
              weakSelf?.showSingleAlert(message: commonLocalizable("jump_microphone_setting")) {}
            }
          }
        }
      }
    case .changed:
      let location = gesture.location(in: view)
      if location.y < UIScreen.main.bounds.height - FunRecordAudioView.getGestureHeight() {
        recordView?.changeToCancelStyle()
      } else {
        recordView?.changeToNormalStyle()
      }
    case .ended:
      removeRecordView()
    case .cancelled:
      removeRecordView()
    case .failed:
      removeRecordView()
      break
    @unknown default:
      break
    }
  }

  override open func showTakePicture() {
    showCustomBottomVideoAction(self, false)
  }

  override open func showFileAction() {
    showCustomBottomFileAction(self)
  }

  open func showRecordView() {
    if recordView == nil {
      let recordAudio = FunRecordAudioView()
      recordAudio.delegate = self
      recordAudio.frame = UIScreen.main.bounds
      recordView = recordAudio
      UIApplication.shared.keyWindow?.addSubview(recordAudio)
    }
    startRecord()
  }

  open func removeRecordView() {
    if let record = recordView {
      if record.isRecordNormalStyle() {
        endRecord(insideView: true)
      } else {
        endRecord(insideView: false)
      }
    }
    recordView?.removeFromSuperview()
    recordView = nil
  }

  public func didEndRecord(view: FunRecordAudioView) {
    endRecord(insideView: true)
    view.removeFromSuperview()
    if let hodlToSpeakView = getFunInputView()?.holdToSpeakView {
      hodlToSpeakView.resignFirstResponder()
    }
  }

  func getFunInputView() -> FunChatInputView? {
    if let funInput = menuView as? FunChatInputView {
      return funInput
    }
    return nil
  }

  override open func closeReply(button: UIButton?) {
    viewmodel.isReplying = false
    getFunInputView()?.hideReplyMode()
    getFunInputView()?.replyLabel.attributedText = nil
  }

  override open func showReplyMessageView(isReEdit: Bool = false) {
    viewmodel.isReplying = true
    getFunInputView()?.showReplyMode()
    if var message = viewmodel.operationModel?.message {
      if isReEdit {
        if let replyMessage = viewmodel.getReplyMessageWithoutThread(message: message) as? MessageContentModel, let msg = replyMessage.message {
          msg.text = message.text
          message = msg
          viewmodel.operationModel = replyMessage
        }
      }
      var text = chatLocalizable("msg_reply")
      if let uid = message.from {
        var showName = viewmodel.getShowName(userId: uid, teamId: viewmodel.session.sessionId, false)
        if viewmodel.session.sessionType != .P2P,
           !IMKitClient.instance.isMySelf(uid) {
          addToAtUsers(addText: "@" + showName + "", isReply: true, accid: uid)
        }
        let user = viewmodel.getUserInfo(userId: uid)
        if let alias = user?.alias {
          showName = alias
        }
        text += " " + showName
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
        text += "[\(chatLocalizable("msg_unknown"))]"
      }
      getFunInputView()?.replyLabel.attributedText = NEEmotionTool.getAttWithStr(str: text,
                                                                                 font: .systemFont(ofSize: 13),
                                                                                 color: .ne_greyText)
      if menuView.textView.isFirstResponder {
        normalOffset = -10
        layoutInputView(offset: currentKeyboardHeight)
      } else {
        menuView.textView.becomeFirstResponder()
      }
    }
  }

  override open func didTapReadView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    if let msg = model?.message, msg.session?.sessionType == .team {
      let readVC = FunReadViewController(message: msg)
      navigationController?.pushViewController(readVC, animated: true)
    }
  }

  public func getMessageModel(model: MessageModel) {
    if model.type == .tip ||
      model.type == .notification ||
      model.type == .time {
      if let tipModel = model as? MessageTipsModel {
        tipModel.contentSize = String.getTextRectSize(tipModel.text ?? "",
                                                      font: .systemFont(ofSize: 14),
                                                      size: CGSize(width: chat_text_maxW, height: CGFloat.greatestFiniteMagnitude))
        tipModel.height = Float(max(tipModel.contentSize.height + chat_content_margin, 28))
      }
      return
    }

    let contentWidth = model.contentSize.width
    let contentHeight = model.contentSize.height
    if contentHeight < 42 {
      let subHeight = 42 - contentHeight
      model.contentSize = CGSize(width: contentWidth, height: 42)
      model.offset = CGFloat(subHeight)
    }

    if model.type == .reply {
      model.offset += 44 + chat_content_margin
    }

    if model.type == .rtcCallRecord {
      model.contentSize = CGSize(width: contentWidth, height: contentHeight - 2)
      model.offset = -2
    }
  }

  override open func addToAtUsers(addText: String, isReply: Bool = false, accid: String, _ isLongPress: Bool = false) {
    if let isRecordMode = getFunInputView()?.isRecordMode(), isRecordMode {
      getFunInputView()?.hideRecordMode()
    }
    getFunInputView()?.hideRecordMode()
    super.addToAtUsers(addText: addText, isReply: isReply, accid: accid, isLongPress)
  }
}
