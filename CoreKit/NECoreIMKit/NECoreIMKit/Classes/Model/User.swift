
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objcMembers
public class User: NSObject {
  public var userId: String?
  public var alias: String?
  public var ext: String?
  public var serverExt: String?
  public var userInfo: UserInfo?

  public var imUser: NIMUser?
  override public init() {
    super.init()
  }

  public init(user: NIMUser?) {
    imUser = user
    userId = user?.userId
    alias = user?.alias
    ext = user?.ext
    serverExt = user?.serverExt
    userInfo = UserInfo(userInfo: user?.userInfo)
  }

  public init(userId: String, nickName: String, avatarUrl: String) {
    self.userId = userId
    let info = UserInfo(nickName: nickName, avatar: avatarUrl)
    userInfo = info
  }

  // (备注 >) 昵称 > accid
  public func showName(_ showAlias: Bool = true) -> String? {
    if showAlias, let remark = alias, !remark.isEmpty {
      return remark
    }
    if let nickname = userInfo?.nickName, !nickname.isEmpty {
      return nickname
    }
    return userId
  }

  public func shortName(showAlias: Bool = true, count: Int) -> String? {
    if let name = showName(showAlias) {
      return name
        .count > count ? String(name[name.index(name.endIndex, offsetBy: -count)...]) : name
    }
    return nil
  }
}
