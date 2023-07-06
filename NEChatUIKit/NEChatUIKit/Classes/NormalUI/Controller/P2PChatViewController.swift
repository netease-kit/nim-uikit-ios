
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK

@objcMembers
open class P2PChatViewController: NormalChatViewController {
  public init(session: NIMSession, anchor: NIMMessage?) {
    super.init(session: session)
    viewmodel = ChatViewModel(session: session, anchor: anchor)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
  }

  override open func getSessionInfo(session: NIMSession) {
    let user = viewmodel.getUserInfo(userId: session.sessionId)
    let showName = user?.showName() ?? ""
    title = showName
    titleContent = showName
    let text = "\(chatLocalizable("send_to"))\(showName)"
    let attribute = NSMutableAttributedString(string: text)
    let style = NSMutableParagraphStyle()
    style.lineBreakMode = .byTruncatingTail
    style.alignment = .left
    attribute.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: NSMakeRange(0, text.utf16.count))
    attribute.addAttribute(.foregroundColor, value: UIColor.gray, range: NSMakeRange(0, text.utf16.count))
    attribute.addAttribute(.paragraphStyle, value: style, range: NSMakeRange(0, text.utf16.count))
    menuView.textView.attributedPlaceholder = attribute
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
