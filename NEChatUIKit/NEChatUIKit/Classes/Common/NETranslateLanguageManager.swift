//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class NETranslateLanguageManager: NSObject {
  public static var shared = NETranslateLanguageManager()

  override private init() {}

  public var languageDatas = ["英语", "日语", "韩语", "俄语", "法语", "德语"]

//  public var translateAIUserAccountId: String {
//    NEAIUserManager.shared.getAITranslateUser()?.accountId ?? ""
//  }

//  var translationAIUser: V2NIMAIUser?

//  public func getTranslationAIUser(_ completion: @escaping (V2NIMAIUser?) -> Void) {
//    if translateAIUserAccountId.count <= 0 {
//      completion(nil)
//    }
//    if translationAIUser == nil {
//      AIRepo.shared.getAIUserList { [weak self] users, error in
//        users?.forEach { aiUser in
//          if self?.translateAIUserAccountId == aiUser.accountId {
//            self?.translationAIUser = aiUser
//            completion(aiUser)
//          }
//        }
//      }
//    } else {
//      completion(translationAIUser)
//    }
//  }
}
