//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECoreIM2Kit
import NIMSDK
import UIKit

@objc
public protocol AIUserPinListener: NSObjectProtocol {
  /// 用户信息发生变化，通知外部重新检查unpin列表
  @objc optional func userInfoDidChange()
}

@objcMembers
open class NEAIUserPinManager: NSObject, NEContactListener, NEIMKitClientListener {
  let pinAIUserMutiDelegate = MultiDelegate<AIUserPinListener>(strongReferences: false)

  public static let shared = NEAIUserPinManager()

  let unpinAIUsersKey = "unpinAIUsers"

  /// 当前用户信息，用于存储取消Pin置顶数据
  public var currentUser: V2NIMUser?

  /// 通讯录 API 接口单例
  public var contactRepo = ContactRepo.shared

  /// 记录数字人
  public var aiUserRecordDic = [String: V2NIMUser]()

  override private init() {
    super.init()
    ContactRepo.shared.addContactListener(self)
    NEAIUserManager.shared.addAIUserChangeListener(listener: self)
    IMKitClient.instance.addLoginListener(self)
  }

  /// 添加监听
  /// - Parameter listener: 监听者
  open func addPinManagerListener(_ listener: AIUserPinListener) {
    pinAIUserMutiDelegate.addDelegate(listener)
  }

  /// 移除监听
  /// - Parameter listener: 监听者
  open func removePinManagerListener(_ listener: AIUserPinListener) {
    pinAIUserMutiDelegate.removeDelegate(listener)
  }

  /// 监听用户变更
  open func onUserProfileChanged(_ users: [V2NIMUser]) {
    for user in users {
      if user.accountId == IMKitClient.instance.account() {
        currentUser = user
        pinAIUserMutiDelegate |> { delegate in
          delegate.userInfoDidChange?()
        }
        break
      }
    }
  }

  /// 检查是否取消标记
  /// - Parameter accountId: 用户id
  /// - Returns: 是否取消标记，返回 false 非 pin 置顶
  open func checkoutUnPinAIUser(_ checkUser: V2NIMUser) -> Bool {
    guard let accountId = checkUser.accountId else {
      return false
    }

    if let serverExtension = checkUser.serverExtension, let jsonObject = NECommonUtil.getDictionaryFromJSONString(serverExtension) {
      if let pinDefault = jsonObject[aiUserPinKey] as? NSNumber {
        if pinDefault.boolValue == false {
          return false
        }
        if let user = currentUser, let serverExtension = user.serverExtension, let jsonObject = NECommonUtil.getDictionaryFromJSONString(serverExtension) {
          if let accountIds = jsonObject[unpinAIUsersKey] as? [String] {
            return !accountIds.contains(accountId)
          }
        }
        return true
      }
    }
    return false
  }

  /// 保存用户信息
  open func saveChangeUnpinInfo(_ serverExtension: String, _ completion: @escaping (NSError?) -> Void) {
    let updateParams = V2NIMUserUpdateParams()
    updateParams.serverExtension = serverExtension
    contactRepo.updateSelfUserProfile(updateParams) { error in
      completion(error)
    }
  }

  /// 取消数字人置顶
  /// - Parameter accountId: 用户id
  /// - Parameter completion: 回调
  open func unpinAIUser(_ accountId: String, _ completion: @escaping (NSError?, Bool) -> Void) {
    guard let user = currentUser else {
      completion(nil, false)
      return
    }

    guard let serverExtension = user.serverExtension, !serverExtension.isEmpty else {
      var accountIds = [String]()
      accountIds.append(accountId)
      saveChangeUnpinInfo(NECommonUtil.getJSONStringFromDictionary([unpinAIUsersKey: accountIds])) { error in
        completion(error, true)
      }

      return
    }

    if let jsonObject = NECommonUtil.getDictionaryFromJSONString(serverExtension) {
      if var accountIds = jsonObject[unpinAIUsersKey] as? [String] {
        if accountIds.contains(accountId) == false {
          accountIds.append(accountId)
          saveChangeUnpinInfo(NECommonUtil.getJSONStringFromDictionary([unpinAIUsersKey: accountIds])) { error in
            completion(error, true)
          }
        }
      }
    }
  }

  /// 修改数字人pin 置顶
  /// - Parameter accountId : 用户id
  /// - Parameter completion : 回调
  open func pinAIUser(_ accountId: String, _ completion: @escaping (NSError?, Bool) -> Void) {
    guard let user = currentUser else {
      completion(nil, false)
      return
    }

    guard let serverExtension = user.serverExtension else {
      NEALog.infoLog(className(), desc: #function + "pinAIUser error , serverExtension is empty")
      return
    }

    if let jsonObject = NECommonUtil.getDictionaryFromJSONString(serverExtension) {
      if var accountIds = jsonObject[unpinAIUsersKey] as? [String] {
        accountIds.removeAll { uid in
          accountId == uid
        }
        saveChangeUnpinInfo(NECommonUtil.getJSONStringFromDictionary([unpinAIUsersKey: accountIds])) { error in
          completion(error, true)
        }
      }
    }
  }

  /// 判断是否是可pin 到顶部的数字人
  /// - Parameter accountId: 用户id
  open func checkoutPinEnable(_ accountId: String) -> V2NIMUser? {
    if aiUserRecordDic.count == 0 {
      let users = NEAIUserManager.shared.getAllAIUsers()
      for aiUser in users {
        if let uid = aiUser.accountId {
          aiUserRecordDic[uid] = aiUser
        }
      }
    }
    if let findAIUser = aiUserRecordDic[accountId] {
      if let serverExtension = findAIUser.serverExtension, let jsonObject = NECommonUtil.getDictionaryFromJSONString(serverExtension) as? [String: Any] {
        if jsonObject[aiUserPinKey] != nil {
          return findAIUser
        }
      }
    }
    return nil
  }
}

// MARK: AI User Cache Delegate

extension NEAIUserPinManager: AIUserChangeListener {
  /// 数字人变更回调
  /// - Parameter aiUsers: 数字人列表
  open func onAIUserChanged(aiUsers: [V2NIMAIUser]) {
    aiUserRecordDic.removeAll()
    for aiUser in aiUsers {
      if let uid = aiUser.accountId {
        aiUserRecordDic[uid] = aiUser
      }
    }
  }
}

public extension NEAIUserPinManager {
  func onLoginStatus(_ status: V2NIMLoginStatus) {
    if status == .LOGIN_STATUS_LOGOUT {
      currentUser = nil
    } else if status == .LOGIN_STATUS_LOGINED {
      if let mine = NEFriendUserCache.shared.getFriendInfo(IMKitClient.instance.account()) {
        currentUser = mine.user
      } else {
        ContactRepo.shared.getUserWithFriend(accountIds: [IMKitClient.instance.account()]) { [weak self] users, error in
          if let first = users?.first {
            self?.currentUser = first.user
          }
        }
      }
    }
  }
}
