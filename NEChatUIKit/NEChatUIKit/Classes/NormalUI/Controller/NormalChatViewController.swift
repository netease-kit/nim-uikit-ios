//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK

@objcMembers
open class NormalChatViewController: ChatViewController {
  override public init(session: NIMSession) {
    super.init(session: session)
    customNavigationView.backgroundColor = .white
    navigationController?.navigationBar.backgroundColor = .white
    registerCellDic = [
      "\(MessageType.text.rawValue)": ChatMessageTextCell.self,
      "\(MessageType.rtcCallRecord.rawValue)": ChatMessageCallCell.self,
      "\(MessageType.audio.rawValue)": ChatMessageAudioCell.self,
      "\(MessageType.image.rawValue)": ChatMessageImageCell.self,
      "\(MessageType.revoke.rawValue)": ChatMessageRevokeCell.self,
      "\(MessageType.video.rawValue)": ChatMessageVideoCell.self,
      "\(MessageType.file.rawValue)": ChatMessageFileCell.self,
      "\(MessageType.reply.rawValue)": ChatMessageReplyCell.self,
      "\(MessageType.location.rawValue)": ChatMessageLocationCell.self,
      "\(MessageType.time.rawValue)": ChatMessageTipCell.self,
    ]
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
  }

  override open func getMenuView() -> NEBaseChatInputView {
    ChatInputView()
  }

  override open func getForwardAlertController() -> NEBaseForwardAlertViewController {
    ForwardAlertViewController()
  }

  override func getUserSelectVC() -> NEBaseSelectUserViewController {
    SelectUserViewController(sessionId: viewmodel.session.sessionId, showSelf: false)
  }

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
      let userSetting = UserSettingViewController()
      userSetting.userId = viewmodel.session.sessionId
      navigationController?.pushViewController(userSetting, animated: true)
    }
  }

  override open func didLongTouchMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    super.didLongTouchMessageView(cell, model)
    operationView?.layer.cornerRadius = 8
    operationView?.layer.borderColor = UIColor.ne_darkText.cgColor
    operationView?.layer.borderWidth = 0.2
  }

  override open func didTapReadView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
    if let msg = model?.message, msg.session?.sessionType == .team {
      let readVC = ReadViewController(message: msg)
      navigationController?.pushViewController(readVC, animated: true)
    }
  }

  public func getMessageModel(model: MessageModel) {
    if model.type == .reply {
      let normalMoreHeight = chat_reply_height + chat_content_margin
      model.contentSize = CGSize(
        width: model.contentSize.width,
        height: model.contentSize.height + normalMoreHeight
      )
      model.height += Float(normalMoreHeight)
    }
  }
}
