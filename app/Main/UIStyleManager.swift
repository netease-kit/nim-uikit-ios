//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatUIKit

class NEStyleManager {
  static let instance = NEStyleManager()
  let userDefault = UserDefaults.standard
  public func isNormalStyle() -> Bool {
    if let style = userDefault.object(forKey: IMUIKit_Style_Key) as? NSNumber, style.intValue == 2 {
      return false
    }
    return true
  }

  public func setNormalStyle() {
    userDefault.set(NSNumber(integerLiteral: 1), forKey: IMUIKit_Style_Key)
    userDefault.synchronize()
  }

  public func setFunStyle() {
    userDefault.set(NSNumber(integerLiteral: 2), forKey: IMUIKit_Style_Key)
    userDefault.synchronize()
  }
}
