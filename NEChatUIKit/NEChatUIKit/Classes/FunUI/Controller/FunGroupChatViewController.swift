// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class FunGroupChatViewController: FunChatViewController, TeamChatViewModelDelegate {
  private var isLeaveTeamBySelf = false // 是否是主动退出群聊
  private var isdismissTeam = false // 群聊是否已解散
  private var onCurrentPage = false // 是否位于聊天详情页

  public init(session: NIMSession, anchor: NIMMessage?) {
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

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    onCurrentPage = true
    // 被动解散群聊
    if isdismissTeam {
      weak var weakSelf = self
      showSingleAlert(message: chatLocalizable("team_has_been_removed")) {
        weakSelf?.navigationController?.popViewController(animated: true)
      }
    }
  }

  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    onCurrentPage = false
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    NotificationCenter.default.addObserver(self, selector: #selector(leaveTeamBySelf), name: NotificationName.leaveTeamBySelf, object: nil)
  }

  override open func getSessionInfo(session: NIMSession) {
    if let vm = viewmodel as? TeamChatViewModel {
      if let t = vm.getTeam(teamId: session.sessionId) {
        updateTeamInfo(team: t)
      }
    }
  }

  //    MARK: private method

  func leaveTeamBySelf(noti: Notification) {
    if let flag = noti.object as? Bool {
      isLeaveTeamBySelf = flag
    }
  }

  private func getPlaceHolder(text: String) -> NSMutableAttributedString {
    let attribute = NSMutableAttributedString(string: text)
    let style = NSMutableParagraphStyle()
    style.lineBreakMode = .byTruncatingTail
    style.alignment = .left
    attribute.addAttribute(.paragraphStyle, value: style, range: NSMakeRange(0, text.utf16.count))
    attribute.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: NSMakeRange(0, text.utf16.count))
    attribute.addAttribute(.foregroundColor, value: UIColor.funChatInputViewPlaceholderTextColor, range: NSMakeRange(0, text.utf16.count))
    return attribute
  }

  open func updateTeamInfo(team: NIMTeam) {
    title = team.getShowName()
    if team.inAllMuteMode(), team.owner != NIMSDK.shared().loginManager.currentAccount() {
      // 群禁言
      menuView.textView.attributedPlaceholder = getPlaceHolder(text: chatLocalizable("team_mute"))
      menuView.textView.backgroundColor = .funChatInputViewBackgroundColorInMute
      layoutInputView(offset: 0)
      getFunInputView()?.hideRecordMode()
      menuView.isUserInteractionEnabled = false
    } else {
      // 解除群禁言
      menuView.textView.attributedPlaceholder = getPlaceHolder(text: chatLocalizable("fun_chat_input_placeholder"))
      menuView.textView.backgroundColor = .white
      menuView.isUserInteractionEnabled = true
    }
  }

  //    MARK: TeamChatViewModelDelegate

  open func onTeamRemoved(team: NIMTeam) {
    // 退出讨论组
    if team.clientCustomInfo?.contains(discussTeamKey) == true {
      navigationController?.popViewController(animated: true)
      return
    }

    // 离开群聊
    if team.teamId == viewmodel.session.sessionId {
      if team.owner != NIMSDK.shared().loginManager.currentAccount() { // 退出群聊
        if isLeaveTeamBySelf {
          navigationController?.popViewController(animated: true)
        } else {
          isdismissTeam = true
          // 被动解散群聊
          if onCurrentPage {
            weak var weakSelf = self
            showSingleAlert(message: chatLocalizable("team_has_been_removed")) {
              weakSelf?.navigationController?.popViewController(animated: true)
            }
          }
        }
      } else { // 主动解散
        navigationController?.popViewController(animated: true)
      }
    }
  }

  open func onTeamUpdate(team: NIMTeam) {
    if team.teamId != viewmodel.session.sessionId {
      return
    }
    updateTeamInfo(team: team)
  }

  public func onTeamMemberUpdate(team: NIMTeam) {
    didRefreshTable()
  }
}
