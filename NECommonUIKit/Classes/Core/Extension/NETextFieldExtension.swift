//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public extension UITextField {
  func removeAllAutoLayout() {
    removeConstraints(constraints)
    for constraint in superview?.constraints ?? [] {
      if let firstItem = constraint.firstItem as? UIView, firstItem == self {
        superview?.removeConstraint(constraint)
      }
    }
  }
}
