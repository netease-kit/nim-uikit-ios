
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public enum LoginAuthType: Int {
  case theDefault = 0
  case dynamicToken = 1
}

public typealias CallBack = (_ str: String) -> String

@objcMembers
public class QChatLoginParam: NSObject {
  public var account: String?
  public var token: String?
  public var authType: LoginAuthType?
  public var dynamicTokenHandler: CallBack?
  public var loginExt: String?

  public init(_ account: String, _ token: String) {
    self.account = account
    self.token = token
  }

  func toIMParam() -> NIMQChatLoginParam {
    let imParam = NIMQChatLoginParam()

    imParam.dynamicTokenHandler = { account -> String in
      guard let token = self.token else {
        return ""
      }
      return token
    }
    switch authType {
    case .dynamicToken:
      imParam.authType = .dynamicToken
    default:
      imParam.authType = .default
    }

//        imParam.loginExt = self.loginExt
    return imParam
  }
}
