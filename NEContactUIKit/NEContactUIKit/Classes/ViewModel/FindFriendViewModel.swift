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

    // 优先去缓存中取
    if let userFriend = NEFriendUserCache.shared.getFriendInfo(text) {
      completion(userFriend, nil)
      return
    }

    // 缓存中没有则去远端查询
    contactRepo.getFriendInfo(text, completion)
  }
}
