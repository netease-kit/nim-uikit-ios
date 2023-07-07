// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreKit
import NECoreIMKit

@objcMembers
public class BlackListViewModel: NSObject, FriendProviderDelegate {
  var contactRepo = ContactRepo()
  public weak var delegate: FriendProviderDelegate?
  private let className = "BlackListViewModel"

  override init() {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    super.init()
    contactRepo.addContactDelegate(delegate: self)
  }

  func getBlackList() -> [User]? {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    return contactRepo.getBlackList()
  }

  func removeFromBlackList(account: String, _ completion: @escaping (NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", account:\(account)")
    contactRepo.removeBlackList(account: account, completion)
  }

  func addBlackList(account: String, _ completion: @escaping (NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", account:\(account)")
    contactRepo.addBlackList(account: account, completion)
  }

  // MARK: callback

  public func onFriendChanged(user: User) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", userId:\(user.userId ?? "nil")")
    delegate?.onFriendChanged(user: user)
  }

  public func onUserInfoChanged(user: User) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", userId:\(user.userId ?? "nil")")
    delegate?.onUserInfoChanged(user: user)
  }

  public func onBlackListChanged() {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    delegate?.onBlackListChanged()
  }

  public func onRecieveNotification(notification: XNotification) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    print(#file + #function)
  }

  public func onNotificationUnreadCountChanged(count: Int) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", count:\(count)")
    print(#file + #function)
  }
}
