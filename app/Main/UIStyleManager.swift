// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatUIKit

class NEStyleManager {
  static let instance = NEStyleManager()
  let userDefault = UserDefaults.standard
  open func isNormalStyle() -> Bool {
    return true
  }

  open func setNormalStyle() {
    userDefault.set(NSNumber(integerLiteral: 1), forKey: IMUIKit_Style_Key)
    userDefault.synchronize()
  }

}
