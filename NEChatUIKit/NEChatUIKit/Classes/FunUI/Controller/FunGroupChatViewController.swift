// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class FunGroupChatViewController: FunChatViewController, TeamChatViewModelDelegate {
  private var isLeaveTeamByOther = false // 是否被移出群聊
  private var isLeaveTeamBySelf = false // 是否多端登录另一端退出群聊
  private var isdismissTeam = false // 群聊是否已解散
  private var isdismissDiscuss = false // 讨论组是否已解散
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

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    onCurrentPage = true

    // 多端登录另一端解散、退出讨论组
    // 多端登录另一端退出群聊
    if isdismissDiscuss || isLeaveTeamBySelf {
      popGroupChatVC()
    }

    weak var weakSelf = self
    // 被移除群聊
    if isLeaveTeamByOther {
      showSingleAlert(message: chatLocalizable("team_has_been_quit")) {
        weakSelf?.navigationController?.popViewController(animated: true)
      }
    }

    // 解散群聊
    if isdismissTeam {
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
    NotificationCenter.default.addObserver(self, selector: #selector(popGroupChatVC), name: NENotificationName.popGroupChatVC, object: nil)
  }

  override open func getSessionInfo(session: NIMSession) {
    if let vm = viewmodel as? TeamChatViewModel {
      if let t = vm.getTeam(teamId: session.sessionId) {
        updateTeamInfo(team: t)
      }
    }
  }

  //    MARK: private method

  func popGroupChatVC() {
    var beforeChat: UIViewController?
    var loopCount = 0
    for vc in navigationController?.viewControllers ?? [] {
      if vc.isKind(of: ChatViewController.self) {
        if loopCount <= 1 {
          navigationController?.popToRootViewController(animated: true)
          return
        }
        navigationController?.popToViewController(beforeChat!, animated: true)
        return
      } else {
        beforeChat = vc
        loopCount += 1
      }
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
    if team.inAllMuteMode(), viewmodel.teamMember?.type != .manager, viewmodel.teamMember?.type != .owner {
      // 群禁言
      isMute = true
      chatInputView.textView.attributedPlaceholder = getPlaceHolder(text: chatLocalizable("team_mute"))
      chatInputView.textView.backgroundColor = .funChatInputViewBackgroundColorInMute
      layoutInputView(offset: 0)
      getFunInputView()?.hideRecordMode()
      chatInputView.isUserInteractionEnabled = false
      chatInputView.setMuteInputStyle()
      if chatInputView.chatInpuMode != .normal {
        chatInputView.titleField.text = nil
        didHideMultipleButtonClick()
      }
      if getFunInputView()?.replyLabel.text?.count ?? 0 > 0 {
        getFunInputView()?.hideReplyMode()
      }
    } else {
      // 解除群禁言
      isMute = false
      chatInputView.textView.attributedPlaceholder = getPlaceHolder(text: chatLocalizable("fun_chat_input_placeholder"))
      chatInputView.textView.backgroundColor = .white
      chatInputView.isUserInteractionEnabled = true
      chatInputView.setUnMuteInputStyle()
    }
  }

  override open func onRecvMessages(_ messages: [NIMMessage]) {
    super.onRecvMessages(messages)
    for message in messages {
      if let object = message.messageObject as? NIMNotificationObject,
         let content = object.content as? NIMTeamNotificationContent {
        if content.operationType == .leave,
           IMKitClient.instance.isMySelf(content.sourceID) {
          isLeaveTeamBySelf = true
          if onCurrentPage {
            popGroupChatVC()
          }
        } else if content.operationType == .kick,
                  let targetIDs = content.targetIDs,
                  targetIDs.contains(IMKitClient.instance.imAccid()) {
          // 被移出群聊
          isLeaveTeamByOther = true
          if onCurrentPage {
            showSingleAlert(message: chatLocalizable("team_has_been_quit")) { [weak self] in
              self?.navigationController?.popViewController(animated: true)
            }
          }
        } else if content.operationType == .dismiss {
          if isdismissDiscuss {
            return
          }

          // 解散群聊
          isdismissTeam = true
          if onCurrentPage {
            showSingleAlert(message: chatLocalizable("team_has_been_removed")) { [weak self] in
              self?.navigationController?.popViewController(animated: true)
            }
          }
        }
      }
    }
  }

  //    MARK: TeamChatViewModelDelegate

  open func onTeamRemoved(team: NIMTeam) {
    // 多端登录另一端解散、退出讨论组
    if team.isDisscuss() == true {
      isdismissDiscuss = true
      if onCurrentPage {
        popGroupChatVC()
      }
      return
    }
  }

  open func onTeamUpdate(team: NIMTeam) {
    if team.teamId != viewmodel.session.sessionId {
      return
    }
    updateTeamInfo(team: team)
  }

  open func onTeamMemberUpdate(team: NIMTeam) {
    didRefreshTable()
  }

  override public func onTeamMemberChange(team: NIMTeam) {
    if viewmodel.session.sessionId != team.teamId {
      return
    }
    (viewmodel as? TeamChatViewModel)?.getTeamMember()
    updateTeamInfo(team: team)
  }
}
