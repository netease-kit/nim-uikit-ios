// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class FunP2PChatViewController: FunChatViewController {
  public init(session: NIMSession, anchor: NIMMessage?) {
    super.init(session: session)
    viewmodel = ChatViewModel(session: session, anchor: anchor)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
  }

  override open func getSessionInfo(session: NIMSession) {
    var showName = session.sessionId
    ChatUserCache.getUserInfo(session.sessionId) { [weak self] user, error in
      if let name = user?.showName() {
        showName = name
      }

      self?.title = showName
      self?.titleContent = showName
      let text = chatLocalizable("fun_chat_input_placeholder")
      let attribute = NSMutableAttributedString(string: text)
      let style = NSMutableParagraphStyle()
      style.lineBreakMode = .byTruncatingTail
      style.alignment = .left
      attribute.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: NSMakeRange(0, text.utf16.count))
      attribute.addAttribute(.foregroundColor, value: UIColor.funChatInputViewPlaceholderTextColor, range: NSMakeRange(0, text.utf16.count))
      attribute.addAttribute(.paragraphStyle, value: style, range: NSMakeRange(0, text.utf16.count))
      self?.chatInputView.textView.attributedPlaceholder = attribute
      self?.chatInputView.textView.setNeedsLayout()
    }
  }

  /// 创建个人聊天页构造方法
  /// - Parameter sessionId: 会话id
  public init(sessionId: String) {
    let session = NIMSession(sessionId, type: .P2P)
    super.init(session: session)
  }

  /// 重写父类的构造方法
  /// - Parameter session: sessionId
  override public init(session: NIMSession) {
    super.init(session: session)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
