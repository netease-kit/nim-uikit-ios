// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreMedia
import Foundation
import NEChatKit
import NECoreIMKit
import NECoreKit

@objcMembers
open class ContactUserViewModel: NSObject {
  let contactRepo = ContactRepo.shared
  private let className = "ContactUserViewModel"

  func addFriend(_ account: String, _ completion: @escaping (NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", account: " + account)
    let request = NEAddFriendRequest()
    request.account = account
    request.operationType = .addRequest
    contactRepo.addFriend(request: request, completion)
  }

  open func deleteFriend(account: String, _ completion: @escaping (NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", account: " + account)
    contactRepo.deleteFriend(account: account, completion)
  }

  open func isFriend(account: String) -> Bool {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", account: " + account)
    return contactRepo.isFriend(account: account)
  }

  open func isBlack(account: String) -> Bool {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", account: " + account)
    return contactRepo.isBlackList(account: account)
  }

  open func removeBlackList(account: String, _ completion: @escaping (NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", account: " + account)
    return contactRepo.removeBlackList(account: account, completion)
  }

  open func update(_ user: NEKitUser, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", userId: " + (user.userId ?? "nil"))
    contactRepo.updateUser(user, completion)
  }

  open func getUserInfo(_ uid: String, _ completion: @escaping (Error?, NEKitUser?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", uid: " + uid)
    contactRepo.getUserInfo(uid) { error, users in
      completion(error, users?.first)
    }
  }

  open func fetchUserInfo(accountList: [String],
                          _ completion: @escaping ([NEKitUser]?, NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", uid: \(accountList)")
    contactRepo.fetchUserInfo(accountList: accountList) { users, error in
      completion(users, error)
    }
  }
}
