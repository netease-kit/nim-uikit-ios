// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

extension UIFont {
  func withTraits(_ traits: UIFontDescriptor.SymbolicTraits...) -> UIFont? {
    guard let descriptor = fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits)) else {
      return nil
    }
    return UIFont(descriptor: descriptor, size: 0)
  }

  func bold() -> UIFont? {
    withTraits(.traitBold)
  }

  func italic() -> UIFont? {
    withTraits(.traitItalic)
  }
}
