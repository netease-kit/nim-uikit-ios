
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK
import NECoreIMKit

@objcMembers
open class GroupChatViewController: ChatViewController, TeamChatViewModelDelegate {
  public init(session: NIMSession, anchor: NIMMessage?) {
//        self.viewmodel = ChatViewModel(session: session)
    super.init(session: session)
    viewmodel = TeamChatViewModel(session: session, anchor: anchor)
    viewmodel.delegate = self
  }

  /// 创建群的构造方法
  /// - Parameter sessionId: 会话id
  public init(sessionId: String) {
    let session = NIMSession(sessionId, type: .team)
    super.init(session: session)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
  }

  override open func getSessionInfo(session: NIMSession) {
    if let vm = viewmodel as? TeamChatViewModel {
      if let t = vm.getTeam(teamId: session.sessionId) {
        updateTeamInfo(team: t)
      }
    }
  }

//    MARK: private method

  private func updateTeamInfo(team: NIMTeam) {
    title = team.getShowName()
    if team.inAllMuteMode(), team.owner != NIMSDK.shared().loginManager.currentAccount() {
      menuView.textField.isEditable = false
      menuView.textField.placeholder = chatLocalizable("team_mute") as NSString?
      layoutInputView(offset: 0)
      menuView.stackView.isUserInteractionEnabled = false
    } else {
      menuView.textField.isEditable = true
      let text = "\(chatLocalizable("send_to"))\(team.getShowName())" as NSString?
//      let attribute = NSMutableAttributedString(string: text)
//      let style = NSMutableParagraphStyle()
//      style.lineBreakMode = .byTruncatingTail
//      style.alignment = .left
//      attribute.addAttribute(.paragraphStyle, value: style, range: NSMakeRange(0, text.count))
//      attribute.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: NSMakeRange(0, text.count))
//      attribute.addAttribute(.foregroundColor, value: UIColor.gray, range: NSMakeRange(0, text.count))
      menuView.textField.placeholder = text
      menuView.stackView.isUserInteractionEnabled = true
    }
  }

//    MARK: TeamChatViewModelDelegate

  public func onTeamRemoved(team: NIMTeam) {
    navigationController?.popViewController(animated: true)

    /* 后续优化逻辑，暂时不做修改
     if team.clientCustomInfo?.contains(discussTeamKey) == true {
       navigationController?.popViewController(animated: true)
       return
     }
     if team.teamId == viewmodel.session.sessionId {
       weak var weakSelf = self
       showSingleAlert(message: chatLocalizable("team_has_been_removed")) {
         weakSelf?.navigationController?.popViewController(animated: true)
       }
     } */
  }

  public func onTeamUpdate(team: NIMTeam) {
    if team.teamId != viewmodel.session.sessionId {
      return
    }
    updateTeamInfo(team: team)
  }
}
