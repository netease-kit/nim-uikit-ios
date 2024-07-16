//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import UIKit

@objcMembers
open class NEFusionContactCellModel: NSObject {
  /// 用户信息
  public var user: NEUserWithFriend?
  /// cell 类型
  public var type = 0
  /// 是否选中
  public var selected = false
  /// 机器人数据
  public var aiUser: V2NIMAIUser?

  /// 获取accid
  public func getAccountId() -> String {
    if let aiAccountId = aiUser?.accountId {
      return aiAccountId
    } else if let uid = user?.user?.accountId {
      return uid
    }
    return ""
  }

  /// 获取显示名称
  public func getShowName() -> String {
    if let name = user?.showName() {
      if name.count > 0 {
        return name
      }
      return user?.user?.accountId ?? ""
    } else if let name = aiUser?.name {
      if name.count > 0 {
        return name
      }
      return aiUser?.accountId ?? ""
    }
    return ""
  }
}
