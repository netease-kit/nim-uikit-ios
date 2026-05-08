//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class NEAIUserModel: NSObject {
  /// 机器人用户
  public var aiUser: V2NIMAIUser?
  /// UI 样式绑定 type
  public var customType = 0
}
