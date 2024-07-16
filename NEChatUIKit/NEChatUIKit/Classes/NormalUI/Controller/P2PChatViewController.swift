
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class P2PChatViewController: NormalChatViewController {
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

  override open var title: String? {
    didSet {
      super.title = title
      let text = "\(chatLocalizable("send_to"))\(titleContent)"
      let attribute = getPlaceHolder(text: text)
      chatInputView.textView.attributedPlaceholder = attribute
      chatInputView.textView.setNeedsLayout()
    }
  }

  private func getPlaceHolder(text: String) -> NSMutableAttributedString {
    let attribute = NSMutableAttributedString(string: text)
    let style = NSMutableParagraphStyle()
    style.lineBreakMode = .byTruncatingTail
    style.alignment = .left
    attribute.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: NSMakeRange(0, text.utf16.count))
    attribute.addAttribute(.foregroundColor, value: UIColor.gray, range: NSMakeRange(0, text.utf16.count))
    attribute.addAttribute(.paragraphStyle, value: style, range: NSMakeRange(0, text.utf16.count))
    return attribute
  }

  override open func getSessionInfo(sessionId: String, _ completion: @escaping () -> Void) {
    chatInputView.textView.attributedPlaceholder = getPlaceHolder(text: chatLocalizable("send_to"))
    super.getSessionInfo(sessionId: sessionId) { [weak self] in
      self?.viewModel.loadShowName([sessionId]) {
        let name = self?.viewModel.getShowName(sessionId) ?? sessionId
        self?.titleContent = name
        self?.title = name
      }
      completion()
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

extension P2PChatViewController: NEContactListener {
  /// 好友信息缓存更新
  /// - Parameter accountId: 用户 id
  public func onContactChange(_ changeType: NEContactChangeType, _ contacts: [NEUserWithFriend]) {
    for contact in contacts {
      if let accid = contact.user?.accountId, contact.user?.accountId == viewModel.sessionId {
        // 好友添加，则从 NEP2PChatUserCache 中移除信息缓存
        if changeType == .addFriend {
          NEP2PChatUserCache.shared.removeUserInfo(viewModel.sessionId)
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

extension P2PChatViewController: NEP2PChatUserCacheListener {
  /// 非好友单聊信息缓存更新
  /// - Parameter accountId: 用户 id
  public func onUserInfoUpdate(_ accountId: String) {
    onUserOrFriendInfoChanged(accountId)
  }
}
