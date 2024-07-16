// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECommonUIKit
import NECoreIM2Kit
import NIMSDK

protocol UserSettingViewModelDelegate: NSObjectProtocol {
  func didNeedRefreshUI()
  func didError(_ error: Error)
  func didShowErrorMsg(_ msg: String)
}

@objcMembers
open class UserSettingViewModel: NSObject, NEConversationListener, AIUserPinListener {
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
    conversationRepo.addConversationListener(self)
    if IMKitConfigCenter.shared.enableAIUser {
      NEAIUserPinManager.shared.addPinManagerListener(self)
    }
  }

  deinit {
    conversationRepo.removeConversationListener(self)
    if IMKitConfigCenter.shared.enableAIUser {
      NEAIUserPinManager.shared.removePinManagerListener(self)
    }
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
    contactRepo.getUserWithFriend(accountIds: [userId]) { [weak self] userfriends, error in
      self?.userInfo = userfriends?.first

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
//    mark.cornerType = .topLeft.union(.topRight)

    let remind = UserSettingCellModel()
    remind.cellName = chatLocalizable("message_remind")
    if let userId = userInfo?.user?.accountId {
      remind.switchOpen = settingRepo.getP2PMessageMuteMode(accountId: userId) == .NIM_P2P_MESSAGE_MUTE_MODE_OFF
    }

    weak var weakSelf = self
    remind.swichChange = { isOpen in
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        weakSelf?.delegate?.didShowErrorMsg(commonLocalizable("network_error"))
        remind.switchOpen = !isOpen
        weakSelf?.delegate?.didNeedRefreshUI()
        return
      }
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

    if let currentConversation = conversation {
      setTop.switchOpen = currentConversation.stickTop
    }

    setTop.swichChange = { isOpen in
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        weakSelf?.delegate?.didShowErrorMsg(commonLocalizable("network_error"))
        setTop.switchOpen = !isOpen
        weakSelf?.delegate?.didNeedRefreshUI()
        return
      }
      if let uid = weakSelf?.userInfo?.user?.accountId, let cid = V2NIMConversationIdUtil.p2pConversationId(uid) {
        if isOpen {
          weakSelf?.conversationRepo.setStickTop(cid, true) { error in
            print("add stick : ", error as Any)
            if let err = error {
              weakSelf?.delegate?.didNeedRefreshUI()
              weakSelf?.delegate?.didError(err)
            } else {
              setTop.switchOpen = false
            }
          }

        } else {
          weakSelf?.conversationRepo.setStickTop(cid, false) { error in
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
    if IMKitConfigCenter.shared.enablePinMessage {
      cellDatas.append(mark)
    }
    cellDatas.append(remind)
    cellDatas.append(setTop)

    if let user = userInfo?.user, let account = user.accountId, let serverExtensions = user.serverExtension, let jsonObject = NECommonUtil.getDictionaryFromJSONString(serverExtensions) {
      if jsonObject[aiUserPinKey] != nil {
        let changePin = UserSettingCellModel()
        changePin.cellName = chatLocalizable("ai_user_pin_top")
        if NEAIUserPinManager.shared.checkoutUnPinAIUser(user) == true {
          changePin.switchOpen = true
        } else {
          changePin.switchOpen = false
        }
        changePin.swichChange = { isOpen in
          if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
            weakSelf?.delegate?.didShowErrorMsg(commonLocalizable("network_error"))
            changePin.switchOpen = !isOpen
            weakSelf?.delegate?.didNeedRefreshUI()
            return
          }
          if isOpen {
            NEAIUserPinManager.shared.pinAIUser(account) { error, finish in
              NEALog.infoLog(ModuleName, desc: #function + " pinAIUser error: \(String(describing: error)), finish: \(finish)")
            }
          } else {
            NEAIUserPinManager.shared.unpinAIUser(account) { error, finish in
              NEALog.infoLog(ModuleName, desc: #function + " unpinAIUser error: \(String(describing: error)), finish: \(finish)")
            }
          }
        }
        cellDatas.append(changePin)
      }
    }

    setAudoType()
  }

  // 设置圆角
  open func setAudoType() {
    for model in cellDatas {
      if model == cellDatas.first {
        model.cornerType = .topLeft.union(.topRight)
        if model == cellDatas.last {
          model.cornerType = .topLeft.union(.topRight).union(.bottomLeft).union(.bottomRight)
        }
      } else if model == cellDatas.last {
        model.cornerType = .bottomLeft.union(.bottomRight)
      } else {
        model.cornerType = .none
      }
    }
  }

  open func setFunType() {
    for model in cellDatas {
      model.cornerType = .none
    }
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

  public func userInfoDidChange() {
    getSectionDatas()
    delegate?.didNeedRefreshUI()
  }
}
