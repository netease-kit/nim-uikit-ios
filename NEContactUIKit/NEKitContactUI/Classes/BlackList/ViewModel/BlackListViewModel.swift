
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEKitContact
import NEKitCoreIM

public class BlackListViewModel: FriendProviderDelegate {
  var contactRepo = ContactRepo()
  init() {
    contactRepo.addContactDelegate(delegate: self)
  }

  func getBlackList() -> [User]? {
    contactRepo.getBlackList()
  }

  func removeFromBlackList(account: String, _ completion: @escaping (NSError?) -> Void) {
    contactRepo.removeBlackList(account: account, completion)
  }

  func addBlackList(account: String, _ completion: @escaping (NSError?) -> Void) {
    contactRepo.addBlackList(account: account, completion)
  }

  // MARK: callback

  public func onFriendChanged(user: User) {
    print(#file + #function)
  }

  public func onUserInfoChanged(user: User) {
    print(#file + #function)
  }

  public func onBlackListChanged() {
    print(#file + #function)
  }

  public func onRecieveNotification(notification: XNotification) {
    print(#file + #function)
  }

  public func onNotificationUnreadCountChanged(count: Int) {
    print(#file + #function)
  }
}
