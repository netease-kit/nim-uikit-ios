
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objc
public enum Gender: Int {
  case unknown
  case male
  case female
}

@objcMembers
public class UserInfo: NSObject {
  public var nickName: String?
  public var avatarUrl: String?
  public var thumbAvatarUrl: String?
  public var sign: String?
  public var gender: Gender = .unknown
  public var email: String?
  public var birth: String?
  public var mobile: String?
  public var ext: String?

  init(userInfo: NIMUserInfo?) {
    nickName = userInfo?.nickName
    avatarUrl = userInfo?.avatarUrl
    thumbAvatarUrl = userInfo?.thumbAvatarUrl
    sign = userInfo?.sign
    switch userInfo?.gender {
    case .male:
      gender = .male
    case .female:
      gender = .female
    default:
      gender = .unknown
    }
    email = userInfo?.email
    birth = userInfo?.birth
    mobile = userInfo?.mobile
    ext = userInfo?.ext
  }

  public init(nickName: String?, avatar: String?) {
    self.nickName = nickName
    avatarUrl = avatar
  }

  func toImUserInfo() -> NIMUserInfo {
    let userInfo = NIMUserInfo()
    return userInfo
  }
}
