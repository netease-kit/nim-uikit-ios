// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit
import NIMSDK

protocol UserSettingViewModelDelegate: NSObjectProtocol {
  func didNeedRefreshUI()
  func didError(_ error: Error)
}

@objcMembers
open class UserSettingViewModel: NSObject, NEConversationListener {
  var chatRepo = ChatRepo.shared
  var contactRepo = ContactRepo.shared
  var conversationRepo = ConversationRepo.shared
  var settingRepo = SettingRepo.shared

  var userInfo: NEUserWithFriend?

  var cellDatas = [UserSettingCellModel]()

  var delegate: UserSettingViewModelDelegate?

  public var conversation: V2NIMConversation?

  override public init() {
    super.init()
    conversationRepo.addListener(self)
  }

  deinit {
    conversationRepo.removeListener(self)
  }

  private let className = "UserSettingViewModel"

  /// 回去单聊会话
  /// - Parameter userId: 用户id
  /// - Parameter completion: 完成回调
  func getConversation(_ userId: String, _ completion: @escaping (NSError?) -> Void) {
    if let cid = V2NIMConversationIdUtil.p2pConversationId(userId) {
      weak var weakSelf = self
      conversationRepo.getConversation(cid) { conversation, error in
        if conversation != nil {
          weakSelf?.conversation = conversation
        }
        completion(error)
      }
    }
  }

  /// 获取用户设置UI显示数据模型
  /// - Parameter userId: 用户id
  /// - Parameter completion: 完成回调
  func getUserSettingModel(_ userId: String, _ completion: @escaping () -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", userId: " + userId)
    contactRepo.getFriendInfo(userId) { [weak self] user, error in
      self?.userInfo = user

      self?.getSectionDatas()

      self?.delegate?.didNeedRefreshUI()

      completion()
    }
  }

  /// 拼装UI显示数据模型
  func getSectionDatas() {
    cellDatas.removeAll()

    let mark = UserSettingCellModel()
    mark.cellName = chatLocalizable("operation_pin")
    mark.type = UserSettingType.SelectType.rawValue
    mark.cornerType = .topLeft.union(.topRight)

    let remind = UserSettingCellModel()
    remind.cellName = chatLocalizable("message_remind")
    if let userId = userInfo?.user?.accountId {
      remind.switchOpen = settingRepo.getP2PMessageMuteMode(accountId: userId) == .NIM_P2P_MESSAGE_MUTE_MODE_OFF
    }

    weak var weakSelf = self
    remind.swichChange = { isOpen in
      if let uid = weakSelf?.userInfo?.user?.accountId {
        let muteMode: V2NIMP2PMessageMuteMode = isOpen ? .NIM_P2P_MESSAGE_MUTE_MODE_OFF : .NIM_P2P_MESSAGE_MUTE_MODE_ON
        weakSelf?.settingRepo.setP2PMessageMuteMode(accountId: uid, muteMode: muteMode) { error in
          if let err = error {
            weakSelf?.delegate?.didNeedRefreshUI()
            weakSelf?.delegate?.didError(err)
          } else {
            remind.switchOpen = isOpen
          }
        }
      }
    }

    let setTop = UserSettingCellModel()
    setTop.cellName = chatLocalizable("session_set_top")
    setTop.cornerType = .bottomRight.union(.bottomLeft)

    if let currentConversation = conversation {
      setTop.switchOpen = currentConversation.stickTop
    }

    setTop.swichChange = { isOpen in
      if let uid = weakSelf?.userInfo?.user?.accountId, let cid = V2NIMConversationIdUtil.p2pConversationId(uid) {
        if isOpen {
          weakSelf?.conversationRepo.addStickTop(cid) { error in
            print("add stick : ", error as Any)
            if let err = error {
              weakSelf?.delegate?.didNeedRefreshUI()
              weakSelf?.delegate?.didError(err)
            } else {
              setTop.switchOpen = false
            }
          }

        } else {
          weakSelf?.conversationRepo.removeStickTop(cid) { error in
            print("remote stick : ", error as Any)
            if let err = error {
              weakSelf?.delegate?.didNeedRefreshUI()
              weakSelf?.delegate?.didError(err)
            } else {
              setTop.switchOpen = true
            }
          }
        }
      }
    }
    cellDatas.append(contentsOf: [mark, remind, setTop])
  }

  /// 会话变更回调
  /// - Parameter conversations: 会话列表
  public func onConversationChanged(_ conversations: [V2NIMConversation]) {
    for changeConversation in conversations {
      if let currentConversation = conversation, currentConversation.conversationId == changeConversation.conversationId {
        conversation = changeConversation
        getSectionDatas()
        delegate?.didNeedRefreshUI()
        continue
      }
    }
  }
}
