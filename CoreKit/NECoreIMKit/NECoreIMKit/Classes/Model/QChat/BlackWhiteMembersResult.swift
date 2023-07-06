
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public struct BlackWhiteMembersResult {
  public var memberArray = [ServerMemeber]()

  init(result: NIMQChatGetExistingChannelBlackWhiteMembersResult?) {
    if let members = result?.memberArray {
      for member in members {
        memberArray.append(ServerMemeber(member))
      }
    }
  }
}
