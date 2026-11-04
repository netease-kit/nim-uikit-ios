// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatUIKit

/// 仓库只发布 NormalUI 一套皮肤，这里仅保留样式的持久化与历史缓存归一化。
class NEStyleManager {
  static let instance = NEStyleManager()
  let userDefault = UserDefaults.standard

  open func setNormalStyle() {
    userDefault.set(NSNumber(integerLiteral: 1), forKey: IMUIKit_Style_Key)
    userDefault.synchronize()
  }
}
