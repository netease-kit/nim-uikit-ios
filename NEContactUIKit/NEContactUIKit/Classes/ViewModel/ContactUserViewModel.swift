// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEContactKit
import NECoreKit
import NECoreIMKit
import CoreMedia

@objcMembers
public class ContactUserViewModel: NSObject {
  let contactRepo = ContactRepo()
  private let className = "ContactUserViewModel"

  func addFriend(_ account: String, _ completion: @escaping (NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", account: " + account)
    let request = AddFriendRequest()
    request.account = account
    request.operationType = .addRequest
    contactRepo.addFriend(request: request, completion)
  }

  public func deleteFriend(account: String, _ completion: @escaping (NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", account: " + account)
    contactRepo.deleteFriend(account: account, completion)
  }

  public func isFriend(account: String) -> Bool {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", account: " + account)
    return contactRepo.isFriend(account: account)
  }

  public func isBlack(account: String) -> Bool {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", account: " + account)
    return contactRepo.isBlackList(account: account)
  }

  public func update(_ user: User, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", userId: " + (user.userId ?? "nil"))
    contactRepo.updateUser(user, completion)
  }

  public func getUserInfo(_ uid: String, _ completion: @escaping (Error?, User?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", uid: " + uid)
    contactRepo.getUserInfo(uid) { error, users in
      completion(error, users?.first)
    }
  }
}
