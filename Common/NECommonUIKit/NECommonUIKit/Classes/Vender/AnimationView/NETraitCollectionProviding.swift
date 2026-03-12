// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#if !os(macOS)
  import UIKit

  /// The capability of providing a `UITraitCollection` instance.
  ///
  /// Typically conformed to by the `CallbackContext` of a `NECallbackContextEpoxyModeled`.
  protocol NETraitCollectionProviding {
    /// The `UITraitCollection` instance provided by this type.
    var traitCollection: UITraitCollection { get }
  }
#endif
