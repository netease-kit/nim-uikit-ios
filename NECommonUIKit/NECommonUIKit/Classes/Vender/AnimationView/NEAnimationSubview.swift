
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#if canImport(UIKit)
  import UIKit

  /// A view that can be added to a keypath of an AnimationView
  public final class NEAnimationSubview: UIView {
    var viewLayer: CALayer? {
      layer
    }
  }
#endif
