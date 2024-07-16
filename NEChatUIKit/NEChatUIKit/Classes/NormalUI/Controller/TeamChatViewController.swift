
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import NIMSDK
import UIKit

@objcMembers
open class TeamChatViewController: NormalChatViewController, TeamChatViewModelDelegate {
  private var isLeaveTeamByOther = false // 是否被移出群聊
  private var isLeaveTeamBySelf = false // 是否多端登录另一端退出群聊
  private var isdismissTeam = false // 群聊是否已解散
  private var isdismissDiscuss = false // 讨论组是否已解散
  private var onCurrentPage = false // 是否位于聊天详情页

  public init(conversationId: String, anchor: V2NIMMessage?) {
    super.init(conversationId: conversationId)
    viewModel = TeamChatViewModel(conversationId: conversationId, anchor: anchor)
    viewModel.delegate = self
  }

  /// 创建群的构造方法
  /// - Parameter sessionId: 会话id
  public init(sessionId: String) {
    let conversationId = V2NIMConversationIdUtil.teamConversationId(sessionId) ?? ""
    super.init(conversationId: conversationId)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    NETeamUserManager.shared.removeAllTeamInfo()
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    onCurrentPage = true

    // 多端登录另一端解散、退出讨论组
    // 多端登录另一端退出群聊
    if isdismissDiscuss || isLeaveTeamBySelf {
      popGroupChatVC()
    }

    // 被移除群聊
    if isLeaveTeamByOther {
      showLeaveTeamAlert()
    }

    // 解散群聊
    if isdismissTeam {
      showDismissTeamAlert()
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

  override open func getSessionInfo(sessionId: String, _ completion: @escaping () -> Void) {
    chatInputView.textView.attributedPlaceholder = getPlaceHolder(text: chatLocalizable("send_to"))
    super.getSessionInfo(sessionId: sessionId) { [weak self] in

      if let vm = self?.viewModel as? TeamChatViewModel {
        vm.getTeamInfo(teamId: sessionId) { error, team in
          if let team = team {
            if IMKitConfigCenter.shared.enabledismissTeamDeleteConversation == true, team.isValidTeam == false {
              self?.showSingleAlert(message: coreLoader.localizable("team_not_exist")) {
                NotificationCenter.default.post(name: NENotificationName.deleteConversationNotificationName, object: V2NIMConversationIdUtil.teamConversationId(team.teamId))
                self?.popGroupChatVC()
              }
            }
            self?.updateTeamInfo(team: team)
          }
        }
      }
      completion()
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
    attribute.addAttribute(.foregroundColor, value: UIColor.gray, range: NSMakeRange(0, text.utf16.count))
    return attribute
  }

  open func updateTeamTitle(_ noti: Notification) {
    if let tid = noti.userInfo?["teamId"] as? String,
       tid == viewModel.sessionId,
       let team = NETeamUserManager.shared.getTeamInfo() {
      updateTeamInfo(team: team)
    }
  }

  /// 更新群聊信息（群聊名称、群禁言状态、缓存）
  /// - Parameter team: 群聊信息
  open func updateTeamInfo(team: V2NIMTeam) {
    title = team.name
    setMute(team: team)
  }

  /// 设置群禁言/取消群禁言状态
  /// - Parameter team: 群聊信息
  open func setMute(team: V2NIMTeam) {
    guard let viewModel = viewModel as? TeamChatViewModel else {
      return
    }

    if team.chatBannedMode == .TEAM_CHAT_BANNED_MODE_BANNED_ALL || (team.chatBannedMode == .TEAM_CHAT_BANNED_MODE_BANNED_NORMAL && viewModel.teamMember?.memberRole == .TEAM_MEMBER_ROLE_NORMAL) {
      // 群禁言
      isMute = true
      chatInputView.textView.isEditable = false
      chatInputView.textView.attributedPlaceholder = getPlaceHolder(text: chatLocalizable("team_mute"))
      chatInputView.textView.backgroundColor = UIColor(hexString: "#E3E4E4")
      layoutInputView(offset: 0)
      chatInputView.stackView.isUserInteractionEnabled = false
      chatInputView.setMuteInputStyle()
      if chatInputView.chatInpuMode != .normal {
        chatInputView.titleField.text = nil
        didHideMultipleButtonClick()
      }
      closeReply(button: nil)
    } else {
      // 解除群禁言
      isMute = false
      chatInputView.textView.isEditable = true
      chatInputView.textView.attributedPlaceholder = getPlaceHolder(text: "\(chatLocalizable("send_to"))\(title ?? team.name)")

      chatInputView.textView.backgroundColor = .white
      chatInputView.stackView.isUserInteractionEnabled = true
      chatInputView.setUnMuteInputStyle()
    }
  }

  override open func onRecvMessages(_ messages: [V2NIMMessage], _ index: [IndexPath]) {
    super.onRecvMessages(messages, index)
    for message in messages {
      if let content = message.attachment as? V2NIMMessageNotificationAttachment {
        if content.type == .MESSAGE_NOTIFICATION_TYPE_TEAM_UPDATE_TINFO,
           let updatedTeamInfo = content.updatedTeamInfo {
          if let name = updatedTeamInfo.name {
            title = name
            onTeamMemberUpdate([])
          }
        } else if content.type == .MESSAGE_NOTIFICATION_TYPE_TEAM_INVITE,
                  let targetIDs = content.targetIds,
                  targetIDs.contains(IMKitClient.instance.account()) {
          // 被重新拉进群聊
          isLeaveTeamByOther = false
          if onCurrentPage {
            dismissAlert()
          }
        } else if content.type == .MESSAGE_NOTIFICATION_TYPE_TEAM_LEAVE,
                  message.senderId == IMKitClient.instance.account() {
          isLeaveTeamBySelf = true
          if onCurrentPage {
            popGroupChatVC()
          }
        } else if content.type == .MESSAGE_NOTIFICATION_TYPE_TEAM_KICK,
                  let targetIDs = content.targetIds,
                  targetIDs.contains(IMKitClient.instance.account()) {
          // 被移出群聊
          isLeaveTeamByOther = true
          if onCurrentPage {
            showLeaveTeamAlert()
          }
        } else if content.type == .MESSAGE_NOTIFICATION_TYPE_TEAM_DISMISS {
          if isdismissDiscuss {
            return
          }

          // 解散群聊
          isdismissTeam = true
          if onCurrentPage {
            showDismissTeamAlert()
          }
        }
      }
    }
  }

  // MARK: - TeamChatViewModelDelegate

  /// 群聊更新回调
  /// - Parameter team: 群聊
  public func onTeamUpdate(team: V2NIMTeam) {
    updateTeamInfo(team: team)
  }

  /// 群成员更新回调
  /// - Parameter teamMembers: 群成员列表
  public func onTeamMemberUpdate(_ teamMembers: [V2NIMTeamMember]) {
    if let team = NETeamUserManager.shared.getTeamInfo() {
      setMute(team: team)
    }
  }
}
