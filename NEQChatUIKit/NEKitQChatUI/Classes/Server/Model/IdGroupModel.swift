
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEKitCoreIM

class IdGroupModel {
  var idName: String?
  var subTitle: String?
//    {
//        didSet {
//            if let s = subTitle, s == "0人" {
//
//            }
//        }
//    }
  var uid: Int?
  var isSelect = false
  var cornerType: CornerType = .none
  var role: ServerRole?
  var hasPermission = false

  public init() {}

  public init(_ serverRole: ServerRole) {
    role = serverRole
    idName = serverRole.name
    if let type = serverRole.type, type == .everyone {
      subTitle = localizable("qchat_group_default_permission")
    } else if let type = serverRole.type, type == .custom {
      subTitle = "\(serverRole.memberCount ?? 0)人"
    }

//        if let s = subTitle, s == "0人" {
//
//        }
  }
}
