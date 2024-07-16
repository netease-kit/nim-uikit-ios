// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class NormalChatViewController: ChatViewController {
  override public init(conversationId: String) {
    super.init(conversationId: conversationId)
    cellRegisterDic = ChatMessageHelper.getChatCellRegisterDic(isFun: false)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.navigationBar.backgroundColor = .white
    navigationView.backgroundColor = .white

    topMessageView.topImageView.image = UIImage.ne_imageNamed(name: "top_message_image")
    topMessageView.layer.borderColor = UIColor(hexString: "#E8EAED").cgColor
    topMessageView.layer.borderWidth = 1
  }

  override open func getMenuView() -> NEBaseChatInputView {
    let chat = ChatInputView()
    chat.multipleLineDelegate = self
    return chat
  }

  /// 获取转发确认弹窗 - 协同版
  override open func getForwardAlertController() -> NEBaseForwardAlertViewController {
    ForwardAlertViewController()
  }

  /// 获取合并转发详情页视图控制器 - 协同版
  override open func getMultiForwardViewController(_ messageAttachmentUrl: String?,
                                                   _ messageAttachmentFilePath: String,
                                                   _ messageAttachmentMD5: String?) -> MultiForwardViewController {
    NormalMultiForwardViewController(messageAttachmentUrl, messageAttachmentFilePath, messageAttachmentMD5)
  }

  /// 获取@列表视图控制器 - 协同版
  override func getUserSelectVC(showTeamMembers: Bool) -> NEBaseSelectUserViewController {
    SelectUserViewController(conversationId: viewModel.conversationId, showSelf: false, showTeamMembers: showTeamMembers)
  }

  open func getMessageModel(model: MessageModel) {
    if model.type == .reply {
      let normalMoreHeight = chat_reply_height + chat_content_margin
      model.contentSize = CGSize(
        width: model.contentSize.width,
        height: model.contentSize.height + normalMoreHeight
      )
      model.height += normalMoreHeight
    }
  }

  @discardableResult
  override open func expandMoreAction() -> [NEMoreItemModel] {
    var items = super.expandMoreAction()

    items.removeAll { item in
      if item.type == .photo {
        return true
      }
      return false
    }

    chatInputView.chatAddMoreView.configData(data: items)
    return items
  }

  override open func expandButtonDidClick() {
    print("expandButtonDidClick ")
    super.expandButtonDidClick()
    chatInputView.changeToMultipleLineStyle()
    normalInputHeight = 296
    bottomViewTopAnchor?.constant = -normalInputHeight
    chatInputView.textView.resignFirstResponder()
    chatInputView.titleField.resignFirstResponder()
    checkAndRemoveReplyView()
  }

  override open func didHideMultipleButtonClick() {
    super.didHideMultipleButtonClick()

    if chatInputView.chatInpuMode == .normal {
      normalInputHeight = 100
    } else {
      normalInputHeight = 150
    }

    layoutInputViewWithAnimation(offset: 0)
    checkAndRestoreReplyView()
  }

  // 切换到多行消息模式隐藏回复
  func checkAndRemoveReplyView() {
    if chatInputView.chatInpuMode == .multipleReturn {
      if replyView.superview != nil {
        replyView.removeFromSuperview()
      }
    }
  }

  // 切换到单行输入框如果有回复显示回复视图
  func checkAndRestoreReplyView() {
    if viewModel.isReplying == true, replyView.superview == nil {
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
  }

  override open func titleTextDidClearEmpty() {
    if chatInputView.chatInpuMode == .multipleSend {
      chatInputView.chatInpuMode = .normal
      if chatInputView.chatInpuMode == .normal {
        normalInputHeight = 100
      } else {
        normalInputHeight = 150
      }
      chatInputView.restoreNormalInputStyle()
      layoutInputViewWithAnimation(offset: currentKeyboardHeight)
      chatInputView.textView.becomeFirstResponder()
    }
  }

  override open func keyBoardWillShow(_ notification: Notification) {
    let keyboardRect = (notification
      .userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
    currentKeyboardHeight = keyboardRect.height
    super.keyBoardWillShow(notification)
  }

  override open func keyBoardWillHide(_ notification: Notification) {
    currentKeyboardHeight = 0
    super.keyBoardWillHide(notification)
  }

  // 减小多行输入框高度，不收回键盘
  override open func didHideMultiple() {
    if chatInputView.chatInpuMode == .normal {
      normalInputHeight = 100
    } else {
      normalInputHeight = 150
    }
    bottomViewTopAnchor?.constant = -(normalInputHeight + currentKeyboardHeight)
  }

  override open func didSwitchLanguageClick(_ currentLanguage: String?) {
    let languageSelectController = SelectLanguageViewController()
    if let current = currentLanguage {
      languageSelectController.currentContent = current
    }
    showLanguageContentController(languageSelectController)
  }
}
