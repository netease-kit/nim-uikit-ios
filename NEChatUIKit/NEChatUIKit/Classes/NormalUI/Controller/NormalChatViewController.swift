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

    if ChatUIConfig.shared.messageProperties.chatViewBackgroundSolid,
       let color = ChatUIConfig.shared.messageProperties.chatTableViewBackgroundColor {
      navigationController?.navigationBar.backgroundColor = color
      navigationView.setNavigationBackgroundColor(color)
      chatInputView.recordView.backgroundColor = color
      chatInputView.chatAddMoreView.backgroundColor = color
    } else {
      navigationController?.navigationBar.backgroundColor = .normalChatNavigationBg
      navigationView.backgroundColor = .normalChatNavigationBg
      navigationView.titleBarBottomLine.backgroundColor = .normalChatNavigationDivideBg
      bodyTopView.backgroundColor = .normalChatBodyTopViewBg
      brokenNetworkView.backgroundColor = .normalChatNetworkBrokenViewBg
      brokenNetworkView.contentLabel.textColor = .normalChatNetworkBrokenTitleColor
      bodyView.backgroundColor = .normalChatBodyViewBg
      tableView.backgroundColor = .normalChatTableViewBg
      bodyBottomView.backgroundColor = .normalChatBodyBottomViewBg
//      chatInputView.backgroundColor = ChatUIConfig.shared.messageProperties.chatViewBackgroundSolid ? ChatUIConfig.shared.messageProperties.chatTableViewBackgroundColor : .normalChatInputViewBg
    }

    topMessageView.topImageView.image = UIImage.ne_imageNamed(name: "top_message_image")
    topMessageView.layer.borderColor = UIColor(hexString: "#E8EAED").cgColor
    topMessageView.layer.borderWidth = 1
  }

  override open func getMenuView(_ conversationType: V2NIMConversationType) -> NEBaseChatInputView {
    let chat = ChatInputView(conversationType)
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
  override open func getUserSelectVC(showTeamMembers: Bool) -> NEBaseSelectUserViewController {
    SelectUserViewController(conversationId: ChatRepo.conversationId, showSelf: false, showTeamMembers: showTeamMembers)
  }

  open func getMessageModel(model: MessageModel) {
    if model.isReply {
      let normalMoreHeight = chat_reply_height + chat_content_margin
      model.contentSize = CGSize(
        width: model.contentSize.width,
        height: model.contentSize.height + normalMoreHeight
      )
      model.height += normalMoreHeight
    }

    // 历史消息加载时：如已有译文且可见，同时追加气泡高度和宽度（取原文/译文最大值）
    if let textModel = model as? MessageTextModel,
       let info = textModel.translationInfo,
       !info.translatedText.isEmpty,
       textModel.translationVisible,
       textModel.addedTranslationHeight == 0 {
      let bubbleH = textModel.estimateTranslationBubbleHeight()
      if bubbleH > 0 {
        // 宽度：原文宽度 vs 译文宽度，取最大，加左右 margin
        let translationW = textModel.estimateTranslationTextWidth() + chat_content_margin * 2
        let newWidth = max(textModel.contentSize.width, translationW)
        textModel.contentSize = CGSize(width: newWidth,
                                       height: textModel.contentSize.height + bubbleH)
        textModel.height += bubbleH
        textModel.addedTranslationHeight = bubbleH
      }
    }
  }

  @discardableResult
  override open func expandMoreAction() -> [NEMoreItemModel] {
    var items = super.expandMoreAction()

    items.removeAll { item in
      if item.type == .photo || item.type == .aiChat {
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

  // MARK: - Normal 皮肤译文高度处理

  /// Normal 皮肤：统一的翻译高度/宽度更新 + reload + 滚动（autoTranslationDidFinish / triggerAutoTranslateHistory 共用）
  override open func applyTranslationHeightAndReload(index: Int, textModel: MessageTextModel?, indexPath: IndexPath) {
    if let textModel = textModel {
      let bubbleH = textModel.estimateTranslationBubbleHeight()
      if bubbleH > 0, textModel.addedTranslationHeight == 0 {
        let translationW = textModel.estimateTranslationTextWidth() + chat_content_margin * 2
        let newWidth = max(textModel.contentSize.width, translationW)
        textModel.contentSize = CGSize(width: newWidth,
                                       height: textModel.contentSize.height + bubbleH)
        textModel.height += bubbleH
        textModel.addedTranslationHeight = bubbleH
      }
    }
    tableViewReloadIndexs([indexPath])
    scrollToShowTranslationIfNeeded(indexPath)
  }

  /// 翻译成功后同时更新 model.contentSize.height（气泡高度）和 model.height（行高）
  override open func translateMessage() {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }
    guard let textModel = viewModel.operationModel as? MessageTextModel else { return }
    viewModel.performTranslation(model: textModel) { [weak self] index, error in
      guard let self = self else { return }
      if error != nil {
        self.showToast(chatLocalizable("chat_translate_failed"))
        return
      }
      // 先还原旧译文占用的高度（语言切换后译文高度可能不同）
      if textModel.addedTranslationHeight > 0 {
        textModel.contentSize = CGSize(width: textModel.contentSize.width,
                                       height: textModel.contentSize.height - textModel.addedTranslationHeight)
        textModel.height -= textModel.addedTranslationHeight
        textModel.addedTranslationHeight = 0
      }
      let bubbleH = textModel.estimateTranslationBubbleHeight()
      if bubbleH > 0 {
        // 宽度取原文/译文最大值
        let translationW = textModel.estimateTranslationTextWidth() + chat_content_margin * 2
        let newWidth = max(textModel.contentSize.width, translationW)
        textModel.contentSize = CGSize(width: newWidth,
                                       height: textModel.contentSize.height + bubbleH)
        textModel.height += bubbleH
        textModel.addedTranslationHeight = bubbleH
      }
      if index >= 0 {
        self.tableViewReloadIndexs([IndexPath(row: index, section: 0)])
      }
    }
  }

  // Normal 皮肤复用基类 triggerAutoTranslateHistory（基类回调已调用 applyTranslationHeightAndReload，Normal override 了该方法处理宽度）

  /// 隐藏译文时还原气泡高度和行高（Normal 皮肤）
  override open func hideTranslationMessage() {
    guard let textModel = viewModel.operationModel as? MessageTextModel else { return }
    if textModel.addedTranslationHeight > 0 {
      textModel.contentSize = CGSize(width: textModel.contentSize.width,
                                     height: textModel.contentSize.height - textModel.addedTranslationHeight)
      textModel.height -= textModel.addedTranslationHeight
      textModel.addedTranslationHeight = 0
    }
    viewModel.hideTranslation(model: textModel) { [weak self] index in
      guard let self = self else { return }
      if index >= 0 {
        self.tableViewReloadIndexs([IndexPath(row: index, section: 0)])
      }
    }
  }
}
