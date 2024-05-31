// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreMedia
import Foundation
import NEChatKit
import NECoreIM2Kit
import NECoreKit

@objcMembers
open class ContactUserViewModel: NSObject {
  let contactRepo = ContactRepo.shared
  private let className = "ContactUserViewModel"

  func addFriend(_ account: String, _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", account: " + account)
    let params = V2NIMFriendAddParams()
    params.addMode = .FRIEND_MODE_TYPE_APPLAY
    contactRepo.addFriend(accountId: account, params: params, completion)
  }

  open func deleteFriend(account: String, _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", account: " + account)

    let params = V2NIMFriendDeleteParams()
    params.deleteAlias = true
    contactRepo.deleteFriend(account: account, params: params, completion)
  }

  open func removeBlackList(account: String, _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", account: " + account)
    contactRepo.removeBlockList(accountId: account, completion)
  }

  /// 更新好友备注
  /// - Parameters:
  ///   - accountId: 用户Id
  ///   - alias: 备注
  ///   - completion: 请求回调
  open func updateAlias(accountId: String,
                        alias: String,
                        _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", userId: \(accountId)")

    let params = V2NIMFriendSetParams()
    params.alias = alias

    contactRepo.setFriendInfo(accountId: accountId, params: params, completion)
  }

  open func getUserInfo(_ uid: String, _ completion: @escaping (NEUserWithFriend?, Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", uid: " + uid)
    contactRepo.getUserWithFriend(accountIds: [uid]) { userFriends, error in
      completion(userFriends?.first, error)
    }
  }
}
