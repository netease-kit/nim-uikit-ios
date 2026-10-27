// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

// These values preserve the existing default UI appearance while keeping
// shared controllers independent from either skin directory.
public extension UIColor {
  static let neUIKitDefaultPrimaryColor = UIColor(hexString: "#337EFF")
  static let neUIKitDefaultPageBackgroundColor = UIColor(hexString: "#EDEDED")
  /// Shared separator/line color. Preserves the previous skin line color (#E5E5E5).
  static let neUIKitDefaultLineColor = UIColor(hexString: "#E5E5E5")
}
