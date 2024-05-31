// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit
import NECoreKit

@objcMembers
open class FindFriendViewModel: NSObject {
  let contactRepo = ContactRepo.shared
  private let className = "FindFriendViewModel"

  func searchFriend(_ text: String, _ completion: @escaping (NEUserWithFriend?, Error?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className, desc: #function + ", text: \(text.count)")

    contactRepo.getUserWithFriend(accountIds: [text]) { userFriends, error in
      completion(userFriends?.first, error)
    }
  }
}
