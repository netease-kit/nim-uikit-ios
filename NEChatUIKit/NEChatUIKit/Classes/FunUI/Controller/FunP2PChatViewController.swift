// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class FunP2PChatViewController: FunChatViewController {
  /// 重写父类的构造方法
  /// - Parameter conversationId: 会话id
  override public init(conversationId: String) {
    super.init(conversationId: conversationId)
    viewModel = P2PChatViewModel(conversationId: conversationId, anchor: nil)
  }

  /// 重写父类的构造方法
  /// - Parameter conversationId: 会话id
  /// - Parameter anchor: 锚点消息
  public init(conversationId: String, anchor: V2NIMMessage?) {
    super.init(conversationId: conversationId)
    viewModel = P2PChatViewModel(conversationId: conversationId, anchor: anchor)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  /// 添加子类监听
  override open func addListener() {
    super.addListener()
    ContactRepo.shared.addContactListener(self)
    NEP2PChatUserCache.shared.addListener(self)
  }

  /// 移除子类监听
  override open func removeListener() {
    super.removeListener()
    ContactRepo.shared.removeContactListener(self)
    NEP2PChatUserCache.shared.removeListener(self)
  }

  override public var titleContent: String {
    didSet {
      super.titleContent = titleContent
      let text = chatLocalizable("fun_chat_input_placeholder")
      let attribute = NSMutableAttributedString(string: text)
      let style = NSMutableParagraphStyle()
      style.lineBreakMode = .byTruncatingTail
      style.alignment = .left
      attribute.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: NSMakeRange(0, text.utf16.count))
      attribute.addAttribute(.foregroundColor, value: UIColor.funChatInputViewPlaceholderTextColor, range: NSMakeRange(0, text.utf16.count))
      attribute.addAttribute(.paragraphStyle, value: style, range: NSMakeRange(0, text.utf16.count))
      chatInputView.textView.attributedPlaceholder = attribute
      chatInputView.setUnMuteInputStyle()
      chatInputView.textView.setNeedsLayout()
    }
  }

  override open func getSessionInfo(sessionId: String, _ completion: @escaping () -> Void) {
    super.getSessionInfo(sessionId: sessionId) { [weak self] in
      self?.viewModel.loadShowName([sessionId]) {
        let name = self?.viewModel.getShowName(sessionId) ?? sessionId
        self?.titleContent = name
      }
      completion()
    }
  }

  override open func commonUI() {
    super.commonUI()
    if IMKitConfigCenter.shared.enableAIChatHelper {
      chatInputView.aiChatViewController.loadDataView.animation = .named("fun_ai_chat_loading", bundle: chatCoreLoader.bundle)
      chatInputView.aiChatViewController.titleIcon.image = UIImage.ne_imageNamed(name: "fun_ai_icon_highlight")
    }
  }

  /// 重写检查并发送正在输入状态
  /// - Parameter endEdit: 是否停止输入
  override open func checkAndSendTypingState(endEdit: Bool = false) {
    guard let viewModel = viewModel as? P2PChatViewModel else {
      return
    }

    if endEdit {
      viewModel.sendInputTypingEndState()
      return
    }

    if chatInputView.chatInpuMode == .normal {
      if let content = chatInputView.textView.text, content.count > 0 {
        viewModel.sendInputTypingState()
      } else {
        viewModel.sendInputTypingEndState()
      }
    } else {
      var title = ""
      var content = ""

      if let titleText = chatInputView.titleField.text {
        title = titleText
      }

      if let contentText = chatInputView.textView.text {
        content = contentText
      }
      if title.count <= 0, content.count <= 0 {
        viewModel.sendInputTypingEndState()
      } else {
        viewModel.sendInputTypingState()
      }
    }
  }
}

// MARK: - NEContactListener

extension FunP2PChatViewController: NEContactListener {
  /// 好友信息缓存更新（包含好友信息和用户信息）
  /// - Parameter changeType: 操作类型
  /// - Parameter contacts: 好友列表
  open func onContactChange(_ changeType: NEContactChangeType, _ contacts: [NEUserWithFriend]) {
    for contact in contacts {
      if let accid = contact.user?.accountId,
         accid == ChatRepo.sessionId {
        // 好友添加，则从 NEP2PChatUserCache 中移除信息缓存
        if changeType == .addFriend {
          NEP2PChatUserCache.shared.removeUserInfo(ChatRepo.sessionId)
        }

        // 好友被删除，则信息缓存移至 NEP2PChatUserCache
        if changeType == .deleteFriend {
          contact.friend = nil
          NEP2PChatUserCache.shared.updateUserInfo(contact)
        }
        onUserOrFriendInfoChanged(accid)
      }
    }
  }
}

// MARK: - NEP2PChatUserCacheListener

extension FunP2PChatViewController: NEP2PChatUserCacheListener {
  /// 非好友单聊信息缓存更新
  /// - Parameter accountId: 用户 id
  open func onUserInfoUpdate(_ accountId: String) {
    onUserOrFriendInfoChanged(accountId)
  }
}
