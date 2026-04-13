// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// Fun 风格扫一扫页面（本地会话模块）
open class FunLocalScanQRViewController: NEBaseLocalScanQRViewController {
  // Fun 皮肤扫描光束主色 #22D39B
  override open var scanBeamColor: UIColor {
    UIColor(red: 0.133, green: 0.827, blue: 0.608, alpha: 1.0)
  }

  // Fun 皮肤扫描光晕色 #5DE9A6
  override open var scanBeamGlowColor: UIColor {
    UIColor(red: 0.365, green: 0.914, blue: 0.651, alpha: 1.0)
  }
}
