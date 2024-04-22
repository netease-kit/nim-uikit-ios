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
    contactRepo.addFriend(accountId: account, completion)
  }

  open func deleteFriend(account: String, _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", account: " + account)
    contactRepo.deleteFriend(account: account, completion)
  }

  open func isFriend(account: String, _ completion: @escaping (Bool) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", account: " + account)
    contactRepo.isFriend(accountId: account, completion)
  }

  open func isBlack(account: String, _ completion: @escaping (Bool) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", account: " + account)
    contactRepo.isBlockList(accountId: account, completion)
  }

  open func removeBlackList(account: String, _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", account: " + account)
    contactRepo.removeBlockList(accountId: account, completion)
  }

  open func update(_ user: NEUserWithFriend, _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", userId: " + (user.user?.accountId ?? "nil"))
    contactRepo.updateUser(user, completion)
  }

  open func getUserInfo(_ uid: String, _ completion: @escaping (NEUserWithFriend?, Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", uid: " + uid)
    contactRepo.getFriendInfo(uid, completion)
  }
}
