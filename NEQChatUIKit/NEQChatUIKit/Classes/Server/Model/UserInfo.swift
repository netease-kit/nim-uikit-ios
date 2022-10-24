
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIMKit

@objcMembers
class UserInfo: NSObject {
  var nickName: String?
  var cornerType: CornerType = .none
  var color = UIColor.colorWithNumber(number: 0)
  var select = false
  var accid: String?
  var serverId: UInt64?
  var createTime: Double?

  var serverMember: ServerMemeber?

  var roleMember: RoleMember?

  override init() {}

  init(_ member: ServerMemeber) {
    serverMember = member
    if let n = member.nick, n.count > 0 {
      nickName = n
    } else {
      nickName = member.accid
    }
    accid = member.accid
    serverId = member.serverId
    createTime = member.createTime
    color = UIColor.colorWithString(string: accid)
  }

  init(_ member: RoleMember) {
    roleMember = member
    if let n = member.nick, n.count > 0 {
      nickName = n
    } else {
      nickName = member.accid
    }
    accid = member.accid
    serverId = member.serverId
    createTime = member.createTime
    color = UIColor.colorWithString(string: accid)
  }
}
