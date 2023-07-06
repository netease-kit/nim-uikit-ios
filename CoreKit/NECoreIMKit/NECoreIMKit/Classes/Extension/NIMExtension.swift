
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public extension NIMUser {
  func getShowName() -> String? {
    if let remark = alias, !remark.isEmpty {
      return remark
    }
    if let nickname = userInfo?.nickName, !nickname.isEmpty {
      return nickname
    }
    return userId
  }
}

public extension NIMTeam {
  func getShowName() -> String {
    if let name = teamName {
      return name
    }
    if let id = teamId {
      return "\(id)"
    }
    return ""
  }
}
